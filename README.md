# Portroost

A deliberately small native macOS menu-bar app for the long-lived local servers started by
Codex's `persistent-local-dev` runner.

It is open source under the MIT license and contains no analytics, accounts, networking, or
third-party dependencies.

## Install

The public release channel is Homebrew:

```bash
brew install --cask \
  techlocal-accounts/portroost/portroost
```

Releases are currently ad-hoc signed, so macOS will block the first launch. After trying to open
the app once, go to **System Settings → Privacy & Security** and choose **Open Anyway**.
[Apple recommends](https://support.apple.com/en-ie/guide/mac-help/-mh40616/mac) overriding
Gatekeeper only for software you trust; this manual step will disappear once Developer ID signing
and notarization are configured. Versioned archives and checksums are also available from
[GitHub Releases](https://github.com/techlocal-accounts/homebrew-portroost/releases).

Requires macOS 14 or newer and Codex's `persistent-local-dev` runner.

## What it shows

- Every currently running persistent server, with its total process-tree memory footprint.
- All remembered stopped servers, ready to start again.
- The saved launch command, project folder, URL, log, PID, and detected environment/setup files.
- Total server footprint and the monitor's own footprint, with resident memory as context.

## Controls

- Open a running server in the browser.
- Stop or restart one server.
- Stop all running servers after confirmation.
- Start a remembered server without asking Codex to reconstruct its command.
- Copy the saved command, reveal the project, or open its log.

The app delegates lifecycle work to:

`~/.codex/skills/persistent-local-dev/scripts/persistent-dev.sh`

It never reads environment-file contents. It only lists relevant filenames so you can see where a
project gets its setup from. The server itself still starts in its saved project folder through a
login shell, exactly as it does when Codex starts it.

Memory uses macOS's per-process physical footprint, the closest match to Activity Monitor's main
memory figure. Resident memory (RSS) remains visible as a secondary diagnostic. Footprint includes
memory charged to a process even when macOS has compressed it, so it is the more useful measure of
how much pressure a server puts on the Mac.

## Build

```bash
swift test
./Scripts/generate-icons.swift
./Scripts/build-app.sh
./Scripts/verify-app.sh
```

The built app is written to `dist/Portroost.app`.

For diagnostics or scripting, the bundled executable also supports:

```bash
portroost --snapshot
portroost --stop <server-id>
portroost --restart <server-id>
```

## Design

This is AppKit, not Electron, a WebView, or a local web server. It has no third-party dependencies,
opens no listening port, and refreshes its process snapshot every ten seconds.

Upgrading from Codex Server Monitor? See the [migration guide](docs/MIGRATION.md).

See [distribution](docs/DISTRIBUTION.md), [privacy](docs/PRIVACY.md), and
[contributing](CONTRIBUTING.md) for project details.

Codex is a trademark of OpenAI. This independent utility is not affiliated with or endorsed by
OpenAI.
