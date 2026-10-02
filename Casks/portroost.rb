cask "portroost" do
  version "1.1.0"
  sha256 "bd18bdfda6cea85a46522492a62b09562b3cfc90d8bae9dfc0a2e0615012c6bf"

  url "https://github.com/techlocal-accounts/homebrew-portroost/releases/download/v#{version}/Portroost-#{version}-macOS.zip"
  name "Portroost"
  desc "Monitor and control persistent local development servers"
  homepage "https://github.com/techlocal-accounts/homebrew-portroost"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "Portroost.app"
  binary "#{appdir}/Portroost.app/Contents/MacOS/Portroost",
         target: "portroost"
  binary "#{appdir}/Portroost.app/Contents/MacOS/Portroost",
         target: "codex-server-monitor"

  caveats <<~EOS
    Portroost expects the persistent-local-dev runner at:
      ~/.codex/skills/persistent-local-dev/scripts/persistent-dev.sh

    Releases are currently ad-hoc signed. After attempting the first launch,
    open System Settings > Privacy & Security and choose Open Anyway.
    This manual step will disappear after Developer ID signing and
    notarization are configured.
  EOS
end
