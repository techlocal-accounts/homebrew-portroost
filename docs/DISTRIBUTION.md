# Distribution

## Supported channel

The supported public distribution path is a versioned GitHub Release installed through the
`techlocal-accounts/homebrew-tap` Homebrew Cask.

Homebrew recommends a Cask for native macOS applications and supports Casks in third-party taps.
The release archive is immutable and pinned by SHA-256 in the tap.

## Prepare a release

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. Run the local checks:

   ```bash
   swift test
   ./Scripts/package-release.sh v1.2.3
   ```

3. Commit and push the version change.
4. Tag the exact release commit and push the tag:

   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

5. The release workflow publishes the ZIP and checksum to GitHub Releases.
6. Replace `__VERSION__` and `__SHA256__` in
   `Distribution/Homebrew/codex-server-monitor.rb.template`, then commit the rendered Cask to
   `Casks/codex-server-monitor.rb` in `techlocal-accounts/homebrew-tap`.
7. Verify the published Cask:

   ```bash
   brew audit --new --cask techlocal-accounts/tap/codex-server-monitor
   brew install --cask --no-quarantine techlocal-accounts/tap/codex-server-monitor
   brew uninstall --cask techlocal-accounts/tap/codex-server-monitor
   ```

## Signing and notarization

The repository does not contain signing material. With no `CODE_SIGN_IDENTITY`, the build script
uses an ad-hoc signature so local and CI builds remain reproducible.

For normal Gatekeeper behavior, sign releases with a Developer ID Application certificate and
submit the archive through Apple's notary service before publishing it. Once every release is
signed and notarized, remove the `--no-quarantine` instruction from the README and Cask caveat.

## Why not the Mac App Store?

The Mac App Store requires App Sandbox. Apple explicitly lists terminating other running apps as
functionality that is incompatible with App Sandbox. This utility also reads a registry in
`~/.codex`, queries launchd, enumerates process trees, and invokes an external lifecycle runner.

Submitting the current feature set as a sandboxed build would therefore be misleading and would
not work correctly. A future App Store edition would need a different architecture in which it
launches and owns only its own managed server processes inside its container. Direct Developer ID
distribution and Homebrew preserve the utility's intended system-management behavior.

References:

- [Homebrew: Adding Software](https://docs.brew.sh/Adding-Software-to-Homebrew)
- [Homebrew: Creating a tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Apple: Protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox)
- [Apple: App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
