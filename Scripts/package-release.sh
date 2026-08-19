#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "${0}")/.." && pwd)"
tag="${1:-}"

if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "Usage: ${0} vMAJOR.MINOR.PATCH" >&2
  exit 2
fi

version="${tag#v}"
plist_version="$(/usr/libexec/PlistBuddy \
  -c 'Print :CFBundleShortVersionString' \
  "${project_root}/Resources/Info.plist")"

if [[ "${version}" != "${plist_version}" ]]
then
  echo "Tag ${tag} does not match Info.plist version ${plist_version}" >&2
  exit 1
fi

BUILD_UNIVERSAL=1 "${project_root}/Scripts/build-app.sh" release
"${project_root}/Scripts/verify-app.sh"

archive="${project_root}/dist/Codex-Server-Monitor-${version}-macOS.zip"
checksum="${archive}.sha256"
rm -f "${archive}" "${checksum}"
ditto -c -k --sequesterRsrc --keepParent \
  "${project_root}/dist/Codex Server Monitor.app" \
  "${archive}"

shasum -a 256 "${archive}" >"${checksum}"
echo "${archive}"
echo "${checksum}"
