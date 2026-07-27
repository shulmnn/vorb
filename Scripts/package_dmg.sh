#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
app_path="${VORB_APP_PATH:-$repo_root/dist/Vorb.app}"
version="${VORB_VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")}"
output_path="${VORB_DMG_PATH:-$repo_root/dist/Vorb-$version.dmg}"
volume_name="${VORB_VOLUME_NAME:-Vorb}"
dmg_identity="${DIRECT_SIGNING_IDENTITY:-}"

if [[ ! -d "$app_path" ]]; then
    echo "Vorb app was not found at $app_path" >&2
    echo "Run Scripts/package_app.sh first." >&2
    exit 1
fi

staging_dir="$(mktemp -d /tmp/vorb-dmg.XXXXXX)"
cleanup() {
    if [[ "$staging_dir" == /tmp/vorb-dmg.* && -d "$staging_dir" ]]; then
        rm -rf -- "$staging_dir"
    else
        echo "Refusing to remove unexpected staging path: $staging_dir" >&2
    fi
}
trap cleanup EXIT

ditto "$app_path" "$staging_dir/Vorb.app"
ln -s /Applications "$staging_dir/Applications"
touch "$staging_dir/.metadata_never_index"

hdiutil create \
    -volname "$volume_name" \
    -srcfolder "$staging_dir" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$output_path"

if [[ -n "$dmg_identity" ]]; then
    codesign --force --timestamp --sign "$dmg_identity" "$output_path"
    codesign --verify --verbose=2 "$output_path"
fi

echo "Packaged: $output_path"
