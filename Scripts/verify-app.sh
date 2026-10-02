#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "${0}")/.." && pwd)"
bundle_root="${1:-}"
if [[ -z "${bundle_root}" ]]
then
  bundle_root="${project_root}/dist/Portroost.app"
fi
executable="${bundle_root}/Contents/MacOS/Portroost"

if [[ ! -d "${bundle_root}" ]]
then
  echo "Missing app bundle: ${bundle_root}" >&2
  exit 1
fi
if [[ ! -x "${executable}" ]]
then
  echo "Missing executable: ${executable}" >&2
  exit 1
fi

legacy_target="$(readlink "${bundle_root}/Contents/MacOS/CodexServerMonitor")"
if [[ "${legacy_target}" != "Portroost" ]]
then
  echo "Missing legacy executable alias" >&2
  exit 1
fi

plutil -lint "${bundle_root}/Contents/Info.plist"
plutil -lint "${bundle_root}/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --verify --deep --strict "${bundle_root}"

architectures="$(lipo -archs "${executable}")"
for required_architecture in arm64 x86_64
do
  if [[ " ${architectures} " != *" ${required_architecture} "* ]]
  then
    echo "Missing architecture ${required_architecture} (found: ${architectures})" >&2
    exit 1
  fi
done

echo "Verified ${bundle_root} (${architectures})"
