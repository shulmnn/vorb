#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
output_dir="$repo_root/dist/app-store"
app_dir="$output_dir/Vorb.app"
pkg_path="$output_dir/Vorb.pkg"
icon_source="$repo_root/Design/OrbLibraryVariants/solving.png"
iconset_dir="$output_dir/Vorb.iconset"
app_identity="${APP_STORE_SIGNING_IDENTITY:--}"
installer_identity="${APP_STORE_INSTALLER_IDENTITY:-}"
provisioning_profile="${APP_STORE_PROVISIONING_PROFILE:-}"
marketing_version="${MARKETING_VERSION:-1.0.0}"
build_number="${BUILD_NUMBER:-1}"
production_entitlements="$repo_root/Packaging/AppStore.entitlements"
development_entitlements="$repo_root/Packaging/AppStoreDevelopment.entitlements"

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    swift_command=(env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift)
else
    swift_command=(swift)
fi

"${swift_command[@]}" build \
    --package-path "$repo_root" \
    -c release \
    --disable-index-store \
    --jobs 4 \
    -Xswiftc -DAPP_STORE

rm -rf "$app_dir" "$pkg_path"
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

plutil -replace CFBundleShortVersionString -string "$marketing_version" "$app_dir/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$build_number" "$app_dir/Contents/Info.plist"
if [[ -n "${APP_STORE_ID:-}" ]]; then
    plutil -replace VorbAppStoreID -string "$APP_STORE_ID" "$app_dir/Contents/Info.plist" 2>/dev/null \
        || plutil -insert VorbAppStoreID -string "$APP_STORE_ID" "$app_dir/Contents/Info.plist"
fi

if [[ -n "$provisioning_profile" ]]; then
    cp "$provisioning_profile" "$app_dir/Contents/embedded.provisionprofile"
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

plutil -lint \
    "$app_dir/Contents/Info.plist" \
    "$app_dir/Contents/Resources/PrivacyInfo.xcprivacy" \
    "$production_entitlements" \
    "$development_entitlements"

signing_entitlements="$production_entitlements"
if [[ "$app_identity" == "-" || "$app_identity" == "Apple Development:"* || "$app_identity" == "Mac Developer:"* ]]; then
    signing_entitlements="$development_entitlements"
fi

codesign_options=(
    --force
    --deep
    --options runtime
    --entitlements "$signing_entitlements"
    --sign "$app_identity"
)
if [[ "$app_identity" != "-" ]]; then
    codesign_options+=(--timestamp)
fi
codesign "${codesign_options[@]}" "$app_dir"
codesign --verify --deep --strict --verbose=2 "$app_dir"

if [[ -n "$installer_identity" ]]; then
    productbuild \
        --component "$app_dir" /Applications \
        --sign "$installer_identity" \
        "$pkg_path"
else
    productbuild --component "$app_dir" /Applications "$pkg_path"
fi

echo "$app_dir"
echo "$pkg_path"
