cask "codex-server-monitor" do
  version "1.0.0"
  sha256 "b8bd5270296d030e199c097967716b885c9a2b3eced747d29e671978650154c9"

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

    Releases are currently ad-hoc signed. After attempting the first launch,
    open System Settings > Privacy & Security and choose Open Anyway.
    This manual step will disappear after Developer ID signing and
    notarization are configured.
  EOS
end
