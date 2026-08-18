# Contributing

Contributions are welcome. Please open an issue before making a large behavioral change so the
scope can be agreed first.

## Development

Requirements:

- macOS 14 or newer
- Xcode 16 or newer with the Swift toolchain

Run the checks locally:

```bash
swift test
./Scripts/build-app.sh release
./Scripts/verify-app.sh
```

Keep pull requests focused, add tests for core parsing or lifecycle behavior, and use conventional
commit prefixes such as `feat:`, `fix:`, `docs:`, or `chore:`.

Do not include process output, project paths, environment contents, signing identities, or other
machine-specific information in issues or test fixtures.
