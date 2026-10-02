# Privacy

PortRoost is local-only and collects no data.

It does not include analytics, advertising, telemetry, crash reporting, accounts, or networking.
It reads only the local information needed to show and control persistent development servers:

- saved server metadata under `~/.codex/persistent-dev`;
- launchd state for those saved server labels;
- process identifiers and memory accounting available to the current macOS user; and
- environment/setup filenames in a server's working directory.

The app does not read environment-file contents. Nothing is transmitted to Tech Local, OpenAI, or
any other party.
