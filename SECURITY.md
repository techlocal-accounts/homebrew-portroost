# Security policy

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do not open a public issue
for a suspected vulnerability or include local commands, paths, logs, or environment details in a
public report.

## Security model

Codex Server Monitor is a local-only utility. It opens no listening port and sends no telemetry.
It reads the persistent server registry, launchd state, and process memory data available to the
current macOS user. Lifecycle actions are delegated to the existing `persistent-local-dev` runner.

The app deliberately detects environment filenames but never reads their contents.
