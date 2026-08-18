#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
bundle_root="${1:-$project_root/dist/Codex Server Monitor.app}"
executable="$bundle_root/Contents/MacOS/CodexServerMonitor"

[[ -d "$bundle_root" ]] || { echo "Missing app bundle: $bundle_root" >&2; exit 1; }
[[ -x "$executable" ]] || { echo "Missing executable: $executable" >&2; exit 1; }

plutil -lint "$bundle_root/Contents/Info.plist"
plutil -lint "$bundle_root/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --verify --deep --strict "$bundle_root"

architectures="$(lipo -archs "$executable")"
for required_architecture in arm64 x86_64; do
  if [[ " $architectures " != *" $required_architecture "* ]]; then
    echo "Missing architecture $required_architecture (found: $architectures)" >&2
    exit 1
  fi
done

echo "Verified $bundle_root ($architectures)"
