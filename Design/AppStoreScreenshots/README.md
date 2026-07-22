# Vorb Mac App Store screenshots

The `Final` folder contains eight upload-ready English (US) 2880 × 1800 RGB PNG files. Screens 1–3 use original AI-generated conceptual artwork to communicate speech-to-text, output, and cross-app use. Screens 4–8 use authentic window-only captures from the sandboxed macOS build.

The generated `Localized` folder contains complete eight-image sets for ten launch locales: English (US), German, French, Spanish (Spain), Portuguese (Brazil), Italian, Japanese, Korean, Simplified Chinese, and Russian. Each set combines reviewed localized marketing copy with native Vorb windows launched in the matching macOS language. The folder is ignored by Git because the 80 upload-ready images are reproducible release artifacts.

The `GeneratedReferences` folder contains the original conceptual image assets and prompt notes. The `Raw` folder contains the native captures; it intentionally excludes the desktop and unrelated apps. The earlier six-screen set is preserved in `PreviousFinal`.

Regenerate the composed images after updating a raw capture:

    python3 Scripts/create_app_store_screenshots.py

Capture the nine non-English native UI sets, then generate all 80 localized screenshots:

    ./Scripts/capture_localized_app_store_screenshots.sh
    python3 Scripts/create_app_store_screenshots.py --all-locales

Generate or review one locale in isolation:

    python3 Scripts/create_app_store_screenshots.py --locale ja

The composition uses SF Pro, original contextual artwork, native Vorb UI captures, and a deterministic background renderer. The conceptual images do not claim to be app controls, and every displayed Vorb control comes from a native capture.

Each output folder also contains a lossless `contact-sheet.png` for visual review. Window captures are masked to the native macOS corner radius, and their shadows are rendered on padded surfaces so no desktop-colored corners or clipped rectangular shadows appear in the final images.
