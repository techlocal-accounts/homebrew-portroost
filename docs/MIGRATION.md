# Migrating to Portroost

Codex Server Monitor is now **Portroost**, starting with version 1.1.0. Its native menu-bar
interface, privacy boundary, and persistent-local-dev lifecycle runner remain the same.

## Repository and links

The repository moved within the same owner from
`techlocal-accounts/homebrew-codex-server-monitor` to
[`techlocal-accounts/homebrew-portroost`](https://github.com/techlocal-accounts/homebrew-portroost).
It remains public and MIT licensed. GitHub redirects the old repository and release URLs.
The old repository name must remain unused for those redirects to keep working.

Update existing clones without moving or replacing your checkout:

```bash
git remote set-url origin https://github.com/techlocal-accounts/homebrew-portroost.git
```

Published v1.0.0 archives, asset names, and checksums remain unchanged. New releases use
`Portroost-VERSION-macOS.zip` containing `Portroost.app`.

## Homebrew

The canonical tap is now `techlocal-accounts/portroost`, and the Cask token is `portroost`:

```bash
brew tap techlocal-accounts/portroost
brew install --cask techlocal-accounts/portroost/portroost
```

For an existing Homebrew installation, quit the monitor, update the old tap, then upgrade.
The tap's `cask_renames.json` maps `codex-server-monitor` to `portroost`, so Homebrew migrates
its installation record and replaces the old app during the upgrade:

```bash
brew update
brew upgrade --cask techlocal-accounts/codex-server-monitor/portroost
```

The old tap can continue working through GitHub's redirect. Avoid installing a second copy
through the new tap while the old installation is still registered. You can also keep the old
tap's checkout and update its remote:

```bash
git -C "$(brew --repository techlocal-accounts/codex-server-monitor)" remote set-url origin \
  https://github.com/techlocal-accounts/homebrew-portroost.git
```

New installations should use the canonical tap. The old Cask token resolves through Homebrew's
rename mapping once the tap has updated. Both `portroost` and `codex-server-monitor` commands
invoke the same bundled executable. The bundle retains the `CodexServerMonitor`
executable name as a symlink for existing scripts. Swift source users should replace
`swift run CodexServerMonitor` with `swift run Portroost`; the `ServerMonitorCore` library name
is unchanged.

## Manual installations

Quit the monitor and replace its app bundle with `Portroost.app` from the new release, in the
same Applications folder. If a login item refers to the old app's filesystem path, update it to
`Portroost.app`. Relaunch the monitor when ready. Ad-hoc signing and the existing Gatekeeper
first-launch instructions still apply.

The macOS bundle identifier intentionally remains `co.za.techlocal.codex-server-monitor` to
preserve application identity. No permissions, credentials, signing identity, launchd service
labels, persistent-server registry paths, or server commands change. No server needs to stop,
restart, or migrate for this rename.
