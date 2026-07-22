# App Store localization files

`Metadata` contains one folder for every localization App Store Connect supports. Each folder includes the localized name, subtitle, promotional text, description, keywords, release notes, and the permanent marketing, support, and privacy URLs.

The matching in-app `.strings` bundles live in `Packaging/Localizations` and are embedded by both packaging scripts. Regenerate both sets with:

```sh
python3 Scripts/generate_localizations.py
```

Translations are machine-generated release drafts with protected product, provider, platform, and protocol names. Character and UTF-8 byte limits are validated by the release checks. A native speaker should review each customer-facing localization in App Store Connect before publication.

Do not place credentials, signing material, reviewer contact details, or private App Store Connect values in these folders.
