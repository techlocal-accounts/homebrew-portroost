#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "${0}")/.." && pwd)"
build_configuration="${1:-release}"
bundle_root="${project_root}/dist/Portroost.app"
contents_root="${bundle_root}/Contents"
macos_root="${contents_root}/MacOS"
resources_root="${contents_root}/Resources"
build_universal="${BUILD_UNIVERSAL:-1}"
signing_identity="${CODE_SIGN_IDENTITY:--}"

build_arguments=(
  --package-path "${project_root}"
  --configuration "${build_configuration}"
)
if [[ "${build_universal}" == "1" ]]
then
  build_arguments+=(--arch arm64 --arch x86_64)
fi

swift build "${build_arguments[@]}"
binary_root="$(swift build "${build_arguments[@]}" --show-bin-path)"

rm -rf "${bundle_root}"
mkdir -p "${macos_root}" "${resources_root}"
cp "${project_root}/Resources/Info.plist" "${contents_root}/Info.plist"
cp "${project_root}/Resources/AppIcon.icns" "${resources_root}/AppIcon.icns"
cp \
  "${project_root}/Resources/PrivacyInfo.xcprivacy" \
  "${resources_root}/PrivacyInfo.xcprivacy"
cp \
  "${binary_root}/Portroost" \
  "${macos_root}/Portroost"
chmod 755 "${macos_root}/Portroost"
ln -s Portroost "${macos_root}/CodexServerMonitor"

signing_arguments=(--force --sign "${signing_identity}")
if [[ "${signing_identity}" != "-" ]]
then
  signing_arguments+=(--options runtime --timestamp)
fi
codesign "${signing_arguments[@]}" "${bundle_root}"

echo "${bundle_root}"
