import AppKit
import Darwin
import ServerMonitorCore

@main
struct PortroostApplication {
  @MainActor
  static func main() {
    if runCommandLineModeIfRequested() {
      return
    }

    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.setActivationPolicy(.accessory)
    application.delegate = delegate
    application.run()
    _ = delegate
  }

  private static func runCommandLineModeIfRequested() -> Bool {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard let option = arguments.first else {
      return false
    }

    let registry = PersistentServerRegistry()
    if option == "--snapshot" {
      let snapshot = registry.scan()
      print(
        "\(snapshot.runningServers.count) running · "
          + "\(snapshot.servers.count) remembered · "
          + "\(ByteCount.format(snapshot.runningFootprintBytes)) footprint · "
          + "\(ByteCount.format(snapshot.runningResidentMemoryBytes)) resident"
      )
      for server in snapshot.servers {
        let pid = server.pid.map { " · pid \($0)" } ?? ""
        let memory = server.state == .running
          ? " · \(ByteCount.format(server.footprintBytes)) footprint"
            + " · \(ByteCount.format(server.residentMemoryBytes)) resident"
          : ""
        print("\(server.id)\t\(server.state.rawValue)\(pid)\(memory)\t\(server.name)")
      }
      return true
    }

    let action: ServerAction?
    switch option {
    case "--stop": action = .stop
    case "--restart": action = .restart
    default: action = nil
    }

    guard let action else {
      return false
    }
    guard arguments.count == 2 else {
      print("Usage: portroost \(option) <server-id>")
      exit(2)
    }

    let snapshot = registry.scan()
    guard let server = snapshot.servers.first(where: { $0.id == arguments[1] }) else {
      print("Unknown server: \(arguments[1])")
      exit(2)
    }

    let result = registry.perform(action, on: server)
    print(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
    if result.exitCode != 0 {
      exit(result.exitCode)
    }
    return true
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private let registry = PersistentServerRegistry()
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let menu = NSMenu()
  private var refreshTimer: Timer?
  private var snapshot = RegistrySnapshot(
    servers: [],
    monitorFootprintBytes: 0,
    monitorResidentMemoryBytes: 0
  )
  private var isRefreshing = false
  private var busyServerIDs = Set<String>()

  func applicationDidFinishLaunching(_ notification: Notification) {
    configureStatusItem()
    menu.delegate = self
    statusItem.menu = menu
    rebuildMenu()
    refresh()

    refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) {
      [weak self] _ in
      Task { @MainActor in
        self?.refresh()
      }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    refreshTimer?.invalidate()
  }

  func menuWillOpen(_ menu: NSMenu) {
    refresh()
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else {
      return
    }
    let image = NSImage(
      systemSymbolName: "server.rack",
      accessibilityDescription: "Local servers"
    )
    image?.isTemplate = true
    button.image = image
    button.imagePosition = .imageLeading
    button.title = " 0 MB"
    button.toolTip = "PortRoost · local servers"
  }

  private func refresh() {
    guard !isRefreshing else {
      return
    }
    isRefreshing = true

    DispatchQueue.global(qos: .utility).async { [registry] in
      let nextSnapshot = registry.scan()
      DispatchQueue.main.async { [weak self] in
        guard let self else {
          return
        }
        self.snapshot = nextSnapshot
        self.isRefreshing = false
        self.updateStatusItem()
        self.rebuildMenu()
      }
    }
  }

  private func updateStatusItem() {
    let running = snapshot.runningServers
    let memory = ByteCount.format(snapshot.runningFootprintBytes)
    statusItem.button?.title = " \(memory)"
    statusItem.button?.toolTip = running.isEmpty
      ? "No Codex local servers running"
      : "\(running.count) Codex local server\(running.count == 1 ? "" : "s")"
        + " · \(memory) footprint"
  }

  private func rebuildMenu() {
    menu.removeAllItems()

    let heading = NSMenuItem(title: "PortRoost", action: nil, keyEquivalent: "")
    heading.isEnabled = false
    menu.addItem(heading)

    let summary = NSMenuItem(title: summaryTitle, action: nil, keyEquivalent: "")
    summary.isEnabled = false
    menu.addItem(summary)
    menu.addItem(.separator())

    let running = snapshot.runningServers
    if running.isEmpty {
      let empty = NSMenuItem(title: "No servers running", action: nil, keyEquivalent: "")
      empty.isEnabled = false
      menu.addItem(empty)
    } else {
      for server in running {
        menu.addItem(makeServerMenuItem(server, among: snapshot.servers))
      }
      menu.addItem(.separator())

      let stopAll = NSMenuItem(
        title: "Stop All Running Servers…",
        action: #selector(confirmStopAll),
        keyEquivalent: ""
      )
      stopAll.target = self
      stopAll.isEnabled = busyServerIDs.isEmpty
      menu.addItem(stopAll)
    }

    let stopped = snapshot.servers.filter { $0.state != .running }
    if !stopped.isEmpty {
      menu.addItem(.separator())
      let knownItem = NSMenuItem(
        title: "Stopped Servers (\(stopped.count))",
        action: nil,
        keyEquivalent: ""
      )
      let knownMenu = NSMenu()
      for server in stopped {
        knownMenu.addItem(makeServerMenuItem(server, among: snapshot.servers))
      }
      knownItem.submenu = knownMenu
      menu.addItem(knownItem)
    }

    menu.addItem(.separator())
    let monitorMemory = NSMenuItem(
      title: "Monitor: \(ByteCount.format(snapshot.monitorFootprintBytes)) footprint"
        + " · \(ByteCount.format(snapshot.monitorResidentMemoryBytes)) resident",
      action: nil,
      keyEquivalent: ""
    )
    monitorMemory.isEnabled = false
    menu.addItem(monitorMemory)

    let refresh = NSMenuItem(
      title: isRefreshing ? "Refreshing…" : "Refresh Now",
      action: #selector(refreshNow),
      keyEquivalent: "r"
    )
    refresh.target = self
    refresh.isEnabled = !isRefreshing
    menu.addItem(refresh)

    let quit = NSMenuItem(
      title: "Quit PortRoost",
      action: #selector(quitApplication),
      keyEquivalent: "q"
    )
    quit.target = self
    menu.addItem(quit)
  }

  private var summaryTitle: String {
    let count = snapshot.runningServers.count
    let total = snapshot.servers.count
    let runningWord = count == 1 ? "server" : "servers"
    return "\(count) \(runningWord) running · \(total) remembered · "
      + "\(ByteCount.format(snapshot.runningFootprintBytes)) footprint"
  }

  private func makeServerMenuItem(
    _ server: PersistentServer,
    among allServers: [PersistentServer]
  ) -> NSMenuItem {
    let displayName = displayName(for: server, among: allServers)
    let title: String
    switch server.state {
    case .running:
      title = "● \(displayName) — \(ByteCount.format(server.footprintBytes))"
    case .loaded:
      title = "◌ \(displayName) — loaded"
    case .stopped:
      title = "○ \(displayName)"
    }

    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    item.submenu = makeServerSubmenu(server)
    return item
  }

  private func makeServerSubmenu(_ server: PersistentServer) -> NSMenu {
    let submenu = NSMenu()
    let isBusy = busyServerIDs.contains(server.id)

    let stateTitle: String
    switch server.state {
    case .running:
      let pid = server.pid.map(String.init) ?? "unknown"
      stateTitle = "Running · PID \(pid)"
    case .loaded:
      stateTitle = "Loaded but not running"
    case .stopped:
      stateTitle = "Stopped"
    }
    let state = NSMenuItem(
      title: isBusy ? "Working…" : stateTitle,
      action: nil,
      keyEquivalent: ""
    )
    state.isEnabled = false
    submenu.addItem(state)

    if server.state == .running {
      let memory = NSMenuItem(
        title: "Memory: \(ByteCount.format(server.footprintBytes)) footprint"
          + " · \(ByteCount.format(server.residentMemoryBytes)) resident",
        action: nil,
        keyEquivalent: ""
      )
      memory.isEnabled = false
      submenu.addItem(memory)
    }
    submenu.addItem(.separator())

    if let url = server.url, let destination = URL(string: url) {
      let open = NSMenuItem(
        title: "Open in Browser",
        action: #selector(openURL(_:)),
        keyEquivalent: ""
      )
      open.target = self
      open.representedObject = destination
      open.isEnabled = server.state == .running
      submenu.addItem(open)
    }

    let restartTitle = server.state == .running ? "Restart" : "Start"
    let restart = NSMenuItem(
      title: restartTitle,
      action: #selector(restartServer(_:)),
      keyEquivalent: ""
    )
    restart.target = self
    restart.representedObject = server.id
    restart.isEnabled = !isBusy && server.isRunnable
    submenu.addItem(restart)

    let stop = NSMenuItem(
      title: "Stop",
      action: #selector(stopServer(_:)),
      keyEquivalent: ""
    )
    stop.target = self
    stop.representedObject = server.id
    stop.isEnabled = !isBusy && server.state == .running
    submenu.addItem(stop)
    submenu.addItem(.separator())

    addDetails(for: server, to: submenu)
    return submenu
  }

  private func addDetails(for server: PersistentServer, to submenu: NSMenu) {
    let command = NSMenuItem(
      title: "Command: \(truncate(server.command, limit: 72))",
      action: #selector(copyCommand(_:)),
      keyEquivalent: ""
    )
    command.target = self
    command.representedObject = server.command
    command.toolTip = "Click to copy: \(server.command)"
    submenu.addItem(command)

    let directory = NSMenuItem(
      title: "Folder: \(truncate(server.workingDirectory, limit: 72))",
      action: #selector(revealProject(_:)),
      keyEquivalent: ""
    )
    directory.target = self
    directory.representedObject = server.workingDirectory
    directory.toolTip = server.workingDirectory
    submenu.addItem(directory)

    let environmentTitle = server.setupFiles.isEmpty
      ? "Environment: login shell; no env files detected"
      : "Environment: login shell + \(server.setupFiles.joined(separator: ", "))"
    let environment = NSMenuItem(title: environmentTitle, action: nil, keyEquivalent: "")
    environment.isEnabled = false
    submenu.addItem(environment)

    if FileManager.default.fileExists(atPath: server.logPath) {
      let logs = NSMenuItem(
        title: "Open Log",
        action: #selector(openLog(_:)),
        keyEquivalent: ""
      )
      logs.target = self
      logs.representedObject = server.logPath
      submenu.addItem(logs)
    }
  }

  private func displayName(
    for server: PersistentServer,
    among allServers: [PersistentServer]
  ) -> String {
    let duplicates = allServers.filter { $0.name == server.name }
    guard duplicates.count > 1 else {
      return server.name
    }
    let parent = URL(fileURLWithPath: server.workingDirectory)
      .deletingLastPathComponent()
      .lastPathComponent
    return "\(parent)/\(server.name)"
  }

  private func truncate(_ value: String, limit: Int) -> String {
    guard value.count > limit else {
      return value
    }
    return "…" + value.suffix(limit - 1)
  }

  private func perform(_ action: ServerAction, serverID: String) {
    guard let server = snapshot.servers.first(where: { $0.id == serverID }) else {
      return
    }
    busyServerIDs.insert(server.id)
    rebuildMenu()

    DispatchQueue.global(qos: .userInitiated).async { [registry] in
      let result = registry.perform(action, on: server)
      DispatchQueue.main.async { [weak self] in
        guard let self else {
          return
        }
        self.busyServerIDs.remove(server.id)
        if result.exitCode != 0 {
          self.showError(
            title: "Couldn’t \(action.rawValue) \(server.name)",
            message: result.output
          )
        }
        self.refresh()
      }
    }
  }

  @objc private func refreshNow() {
    refresh()
  }

  @objc private func restartServer(_ sender: NSMenuItem) {
    guard let serverID = sender.representedObject as? String else {
      return
    }
    perform(.restart, serverID: serverID)
  }

  @objc private func stopServer(_ sender: NSMenuItem) {
    guard let serverID = sender.representedObject as? String else {
      return
    }
    perform(.stop, serverID: serverID)
  }

  @objc private func confirmStopAll() {
    let running = snapshot.runningServers
    guard !running.isEmpty else {
      return
    }

    let alert = NSAlert()
    alert.messageText = "Stop all \(running.count) running servers?"
    alert.informativeText = "They stay remembered and can be started again from this menu."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Stop All")
    alert.addButton(withTitle: "Cancel")

    guard alert.runModal() == .alertFirstButtonReturn else {
      return
    }

    busyServerIDs.formUnion(running.map(\.id))
    rebuildMenu()
    DispatchQueue.global(qos: .userInitiated).async { [registry] in
      let failures = running.compactMap { server -> String? in
        let result = registry.perform(.stop, on: server)
        return result.exitCode == 0 ? nil : "\(server.name): \(result.output)"
      }
      DispatchQueue.main.async { [weak self] in
        guard let self else {
          return
        }
        self.busyServerIDs.subtract(running.map(\.id))
        if !failures.isEmpty {
          self.showError(
            title: "Some servers could not be stopped",
            message: failures.joined(separator: "\n")
          )
        }
        self.refresh()
      }
    }
  }

  @objc private func openURL(_ sender: NSMenuItem) {
    guard let url = sender.representedObject as? URL else {
      return
    }
    NSWorkspace.shared.open(url)
  }

  @objc private func revealProject(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else {
      return
    }
    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
  }

  @objc private func openLog(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else {
      return
    }
    NSWorkspace.shared.open(URL(fileURLWithPath: path))
  }

  @objc private func copyCommand(_ sender: NSMenuItem) {
    guard let command = sender.representedObject as? String else {
      return
    }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(command, forType: .string)
  }

  @objc private func quitApplication() {
    NSApplication.shared.terminate(nil)
  }

  private func showError(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message.trimmingCharacters(in: .whitespacesAndNewlines)
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
}
