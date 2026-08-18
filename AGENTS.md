# Repository guidelines

- Keep the app native and lightweight: AppKit and Foundation are preferred over third-party UI
  or runtime dependencies.
- Preserve the privacy boundary: never read or log environment-file contents. Showing filenames
  is acceptable.
- Lifecycle actions must continue to delegate to the `persistent-local-dev` runner rather than
  reimplementing its launchd behavior.
- Run `swift test`, `./Scripts/build-app.sh release`, and `./Scripts/verify-app.sh` before release.
- Release tags use semantic versions prefixed with `v`, for example `v1.0.0`.
- Do not commit `.build`, `dist`, archives, signing certificates, or notarization credentials.
