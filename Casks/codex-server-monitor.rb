cask "codex-server-monitor" do
  version "1.0.0"
  sha256 "05ba588bb9f2dcb4e8bb4b889fcdfb0767465c812a2a579eafba6ebda0e087c5"

  url "https://github.com/techlocal-accounts/homebrew-codex-server-monitor/releases/download/v#{version}/Codex-Server-Monitor-#{version}-macOS.zip"
  name "Codex Server Monitor"
  desc "Monitor and control persistent local development servers"
  homepage "https://github.com/techlocal-accounts/homebrew-codex-server-monitor"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "Codex Server Monitor.app"
  binary "#{appdir}/Codex Server Monitor.app/Contents/MacOS/CodexServerMonitor",
         target: "codex-server-monitor"

  caveats <<~EOS
    Codex Server Monitor expects the persistent-local-dev runner at:
      ~/.codex/skills/persistent-local-dev/scripts/persistent-dev.sh

    Releases are currently ad-hoc signed. Until Developer ID signing and
    notarization are configured, install with Homebrew's --no-quarantine flag.
  EOS
end
