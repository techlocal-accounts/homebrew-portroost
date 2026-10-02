cask "portroost" do
  version "1.1.1"
  sha256 "102aaffb4a79d8d10f0e39cd508527be8a4042fcd9065928e5da4fbc8fc9c7ae"

  url "https://github.com/techlocal-accounts/homebrew-portroost/releases/download/v#{version}/PortRoost-#{version}-macOS.zip"
  name "PortRoost"
  desc "Monitor and control persistent local development servers"
  homepage "https://github.com/techlocal-accounts/homebrew-portroost"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "PortRoost.app"
  binary "#{appdir}/PortRoost.app/Contents/MacOS/Portroost",
         target: "portroost"
  binary "#{appdir}/PortRoost.app/Contents/MacOS/Portroost",
         target: "codex-server-monitor"

  caveats <<~EOS
    PortRoost expects the persistent-local-dev runner at:
      ~/.codex/skills/persistent-local-dev/scripts/persistent-dev.sh

    Releases are currently ad-hoc signed. After attempting the first launch,
    open System Settings > Privacy & Security and choose Open Anyway.
    This manual step will disappear after Developer ID signing and
    notarization are configured.
  EOS
end
