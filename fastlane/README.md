fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac validate_package

```sh
[bundle exec] fastlane mac validate_package
```

Validate the signed Vorb package without uploading it

### mac upload_build

```sh
[bundle exec] fastlane mac upload_build
```

Upload the signed Vorb package without submitting it for review

### mac upload_metadata

```sh
[bundle exec] fastlane mac upload_metadata
```

Upload all localized metadata and the ten localized screenshot sets

### mac upload_screenshots

```sh
[bundle exec] fastlane mac upload_screenshots
```

Upload the ten localized Mac screenshot sets without changing metadata

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
