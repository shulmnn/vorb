# Vorb Mac App Store screenshots

The `Final` folder contains eight upload-ready 2880 × 1800 RGB PNG files. Screens 1–3 use original AI-generated conceptual artwork to communicate speech-to-text, output, and cross-app use. Screens 4–8 use authentic window-only captures from the sandboxed macOS build.

The `GeneratedReferences` folder contains the original conceptual image assets and prompt notes. The `Raw` folder contains the native captures; it intentionally excludes the desktop and unrelated apps. The earlier six-screen set is preserved in `PreviousFinal`.

Regenerate the composed images after updating a raw capture:

    python3 Scripts/create_app_store_screenshots.py

The composition uses SF Pro, original contextual artwork, native Vorb UI captures, and a deterministic background renderer. The conceptual images do not claim to be app controls, and every displayed Vorb control comes from a native capture.
