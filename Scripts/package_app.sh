#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
app_dir="$repo_root/dist/Vorb.app"
icon_source="$repo_root/Design/OrbLibraryVariants/solving.png"
iconset_dir="$repo_root/dist/Vorb.iconset"
app_identity="${DIRECT_SIGNING_IDENTITY:--}"
development_entitlements="$repo_root/Packaging/LocalDevelopment.entitlements"

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    swift_command=(env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift)
else
    swift_command=(swift)
fi

"${swift_command[@]}" build --package-path "$repo_root" -c release --disable-index-store --jobs 4

rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$repo_root/.build/release/LocalGroq" "$app_dir/Contents/MacOS/Vorb"
cp "$repo_root/Packaging/Info.plist" "$app_dir/Contents/Info.plist"
cp "$repo_root/Packaging/PrivacyInfo.xcprivacy" "$app_dir/Contents/Resources/PrivacyInfo.xcprivacy"
cp "$repo_root/PRIVACY.md" "$app_dir/Contents/Resources/PRIVACY.md"
cp "$repo_root/THIRD_PARTY_NOTICES.md" "$app_dir/Contents/Resources/THIRD_PARTY_NOTICES.md"
for localization in "$repo_root"/Packaging/Localizations/*.lproj; do
    [[ -d "$localization" ]] && cp -R "$localization" "$app_dir/Contents/Resources/"
done
if [[ -f "$repo_root/.build/checkouts/argmax-oss-swift/NOTICES" ]]; then
    cp "$repo_root/.build/checkouts/argmax-oss-swift/NOTICES" \
        "$app_dir/Contents/Resources/ARGMAX_OSS_NOTICES.txt"
fi

if [[ -f "$icon_source" ]]; then
    rm -rf "$iconset_dir"
    mkdir -p "$iconset_dir"
    sips -s format png -z 16 16 "$icon_source" --out "$iconset_dir/icon_16x16.png" >/dev/null
    sips -s format png -z 32 32 "$icon_source" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
    sips -s format png -z 32 32 "$icon_source" --out "$iconset_dir/icon_32x32.png" >/dev/null
    sips -s format png -z 64 64 "$icon_source" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
    sips -s format png -z 128 128 "$icon_source" --out "$iconset_dir/icon_128x128.png" >/dev/null
    sips -s format png -z 256 256 "$icon_source" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
    sips -s format png -z 256 256 "$icon_source" --out "$iconset_dir/icon_256x256.png" >/dev/null
    sips -s format png -z 512 512 "$icon_source" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
    sips -s format png -z 512 512 "$icon_source" --out "$iconset_dir/icon_512x512.png" >/dev/null
    sips -s format png "$icon_source" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null
    iconutil -c icns "$iconset_dir" -o "$app_dir/Contents/Resources/Vorb.icns"
    rm -rf "$iconset_dir"
fi

plutil -lint "$app_dir/Contents/Info.plist"

codesign_options=(--force --deep --sign "$app_identity")
if [[ "$app_identity" == "-" || "$app_identity" == "Apple Development:"* || "$app_identity" == "Mac Developer:"* ]]; then
    codesign_options+=(--entitlements "$development_entitlements")
else
    codesign_options+=(--options runtime --timestamp)
fi
codesign "${codesign_options[@]}" "$app_dir"
codesign --verify --deep --strict --verbose=2 "$app_dir"
echo "$app_dir"
