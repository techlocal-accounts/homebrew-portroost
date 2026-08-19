cask "codex-server-monitor" do
  version "1.0.0"
  sha256 "fe849dcbf6350f8c2ce4889aec0f35117046539e452032c67b95ec7d0e415b11"

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
