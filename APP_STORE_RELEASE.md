# Mac App Store release checklist

Vorb uses the bundle identifier `vorb.shulmnn.com`, version `1.0`, build `2`, and the Productivity category.

Use [APP_STORE_METADATA_EN.md](APP_STORE_METADATA_EN.md) for the complete English (U.S.) product-page copy, App Review notes, privacy and age-rating answers, screenshot copy, compliance fields, and TestFlight metadata.

## Before packaging

- Reserve the Vorb name and create the matching macOS App ID in App Store Connect.
- Create Mac App Distribution and Mac Installer Distribution certificates and a provisioning profile for `vorb.shulmnn.com`.
- Verify the live [privacy policy](https://vorb.shulmnn.com/privacy) and [support page](https://vorb.shulmnn.com/support). App Store Connect requires both URLs.
- Review the generated metadata in `AppStore/Metadata`. All 50 App Store localizations are present; machine-generated translations should receive native-speaker review before submission.
- Keep the published App Privacy disclosure aligned with the final binary: optional hosted transcription collects Audio Data for App Functionality, links it to the user through their provider account, and does not use it for tracking. Local Whisper remains on-device.
- Test microphone and local-network permissions, Local Whisper model download, global Option–Space, clipboard copy, history, menu-bar hiding, and relaunch on a clean macOS account.

## Build the upload package

```sh
APP_STORE_SIGNING_IDENTITY="Apple Distribution: COMPANY (TEAMID)" \
APP_STORE_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: COMPANY (TEAMID)" \
APP_STORE_PROVISIONING_PROFILE="/absolute/path/to/profile.provisionprofile" \
MARKETING_VERSION="1.0" \
BUILD_NUMBER="2" \
./Scripts/package_app_store.sh
```

The script creates `dist/app-store/Vorb.app` and `dist/app-store/Vorb.pkg`. Without distribution signing variables it creates a sandboxed local-validation build with `get-task-allow` and an unsigned installer package; those artifacts cannot be uploaded. Apple Distribution builds use the production entitlement set and never include `get-task-allow`.

Upload the signed package with Transporter or App Store Connect tooling. Increment `BUILD_NUMBER` for every submitted macOS build.

## Review notes

- Vorb has no login. Reviewers can choose Local Whisper and use the app without an API key.
- Reviewers explicitly download the selected local model from Settings before dictating; audio then remains on-device.
- The default Option–Space shortcut starts and stops recording; reviewers can also configure a different shortcut or choose hold-to-speak.
- The recording orb disappears immediately when recording stops.
- The App Store build copies the transcript to the clipboard. Automatic cross-app paste exists only in the separately distributed, non-sandboxed build because App Sandbox prohibits controlling another app.
