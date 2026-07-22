# Contributing to Vorb

Thanks for helping make native Mac dictation better.

## Before you start

- Search existing [issues](https://github.com/shulmnn/vorb/issues) before opening a new one.
- Use an issue for a bug report or feature proposal before investing in a large change.
- Keep Vorb native, focused, and free of analytics, accounts, subscriptions, and provider SDKs.
- Never commit API keys, provider credentials, signing certificates, provisioning profiles, or private recordings.

## Development

Vorb requires macOS 14 or newer, Xcode 16 or newer, and Swift 6.

```sh
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
./Scripts/package_app.sh
```

Changes should include focused tests where practical. Confirm that temporary audio is deleted on success and failure, keys stay in Keychain, model downloads remain explicit, and the recording orb disappears immediately when recording stops.

## Pull requests

Keep pull requests small enough to review. Explain the user-visible result, note privacy or sandbox implications, and include before/after screenshots for interface changes. By contributing, you agree that your contribution is distributed under the repository license.

## License

Vorb uses the PolyForm Noncommercial License 1.0.0. Noncommercial forks and contributions are welcome. Commercial use requires separate written permission from Amnios Group; contact [support@amnios-group.com](mailto:support@amnios-group.com).
