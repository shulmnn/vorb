# Vorb — App Store metadata (English, U.S.)

Submission copy for Vorb 1.0.0. Contact-name and phone fields must still be completed by the App Store account holder before submission.

## App record

| Field | Value |
| --- | --- |
| Platform | macOS |
| App name | Vorb |
| Primary language | English (U.S.) |
| Bundle ID | `com.amnios.vorb` |
| SKU | `VORB-MAC-001` |
| Version | `1.0.0` |
| Build | `1` |
| Copyright | 2026 Amnios Group |
| Primary category | Productivity |
| Secondary category | Utilities |
| Price | Free |
| In-App Purchases | None |
| License agreement | Apple Standard EULA |
| Minimum system | macOS 14.0 |
| Supported Macs | Apple silicon |

## English (U.S.) product page

### Name — 4/30 characters

```text
Vorb
```

### Subtitle — 25/30 characters

```text
Private Whisper Dictation
```

### Promotional text — 164/170 characters

```text
Press Option–Space, speak, and get clean text in your clipboard. Run Whisper locally with no key, or bring your own provider—without a Vorb account or subscription.
```

### Keywords — 95/100 bytes

```text
transcription,speech to text,voice,clipboard,productivity,offline,local,BYOK,audio,typing,notes
```

### Description

```text
Vorb turns your voice into text with a single shortcut.

Press Option–Space to start speaking and press it again to stop, or choose hold-to-speak and release the shortcut when you are done. You can record a different global shortcut at any time. Vorb transcribes your audio, copies the result to the clipboard, and gets out of your way.

RUN WHISPER ON YOUR MAC

Choose Local Whisper to transcribe entirely on your Mac—no API key required. Models download only when you click Download Model. If you already have a complete WhisperKit model, import its folder instead.

BRING YOUR OWN PROVIDER

Already have an API key? Connect Groq, OpenAI, Deepgram, Mistral, ElevenLabs, or another compatible service. Keys stay in macOS Keychain, and Vorb sends audio directly to the provider you select. There is no Vorb account, backend, analytics, advertising, or subscription.

MADE FOR FOCUSED WORK

• Configurable global shortcut
• Toggle-to-speak or hold-to-speak
• Minimal animated recording orb
• Clipboard delivery in the Mac App Store version
• Optional, locally stored transcript history
• Automatic language detection or a chosen language
• Tiny, Base, Small, and Large V3 local Whisper models
• Hosted, self-hosted, and custom OpenAI-compatible endpoints
• Menu bar icon you can hide
• Settings that save automatically

Vorb removes temporary recordings after each transcription attempt. When Local Whisper is selected, transcription stays on your Mac. When you choose an online provider, its terms and privacy policy apply.

Requires macOS 14 or later and a Mac with Apple silicon. A network connection is required to download a local model or use an online provider.
```

### URLs

These permanent HTTPS pages are live.

| Field | Value |
| --- | --- |
| Marketing URL (optional) | `https://vorb.shulmnn.com` |
| Support URL (required) | `https://vorb.shulmnn.com/support` — includes `support@amnios-group.com` |
| Privacy Policy URL (required) | `https://vorb.shulmnn.com/privacy` |
| User Privacy Choices URL (optional) | Leave blank; Vorb does not operate an account or backend, and local history can be deleted in the app |

## Screenshots

Use the eight 2880 × 1800 PNG files without transparency, in the order below. The first three use original conceptual artwork to explain the dictation workflow; the remaining five show the real App Store build. Use the English set for English (U.S.) and the matching fully localized set for German, French, Spanish (Spain), Portuguese (Brazil), Italian, Japanese, Korean, Simplified Chinese, and Russian.

| Order | Headline | Supporting line | Screen to capture |
| --- | --- | --- | --- |
| 1 | Your thoughts. Already typed. | Speak naturally. Vorb turns your voice into text before the idea disappears. | Relatable dictation-at-a-desk scene with a visible voice-to-document transformation |
| 2 | Say it. Paste it. | One shortcut turns your voice into text you can paste wherever you work. | Explicit waveform-to-text transformation |
| 3 | One voice. Every writing task. | Dictate notes, emails, messages, and prompts—then paste the result wherever you work. | Email, notes, and messages workflow |
| 4 | Whisper stays here. So do your words. | On-device speech-to-text. No API key. No audio upload. | Local Whisper selected in Settings with model management visible |
| 5 | Your keys. Zero lock-in. | Connect Groq, OpenAI, Deepgram, or any compatible speech-to-text endpoint. | Custom provider endpoint and model settings |
| 6 | Fast or accurate? You decide. | Pick the Whisper model and language that fit the moment. | Model and language settings |
| 7 | Never lose a good thought again. | Keep an optional local transcript history, ready to copy when you need it. | History window populated with realistic, non-sensitive sample transcripts |
| 8 | Tap once. Or hold and talk. | Choose any global shortcut and make voice typing feel automatic. | Configurable shortcut and recording behavior in Settings |

Do not show automatic cross-app paste in App Store screenshots. The sandboxed Store build copies the transcript to the clipboard.

### Optional App Preview

Skip an App Preview for 1.0 unless a polished native-resolution recording is available. If one is produced, use this 20-second sequence:

```text
0–3 s    Press Option–Space from any app.
3–8 s    Speak while the minimal orb responds.
8–12 s   Stop; the orb disappears immediately.
12–16 s  Paste the copied transcript.
16–20 s  Show “Local Whisper or your own provider” and the Vorb icon.
```

## Version information

### What’s New

App Store Connect does not show What’s New for the first version. Keep this copy for the first update:

```text
Vorb is now available for macOS.

• Dictate from anywhere with Option–Space
• Run Whisper locally with no API key
• Connect hosted, self-hosted, and custom transcription providers
• Copy transcripts to the clipboard and keep an optional local history
• Use a minimal animated orb that disappears as soon as recording stops
```

### Release method

Select **Manually release this version** for 1.0. This allows the website, support page, repository, and launch post to go live before the App Store product page becomes public.

### Phased release

Not applicable to the initial release. For later updates, use a seven-day phased release only when the update changes transcription, storage, or provider behavior substantially.

## App Review information

| Field | Value |
| --- | --- |
| Sign-in required | No |
| Demo account | Not applicable |
| Contact first name | **CONFIRM BEFORE SUBMISSION** |
| Contact last name | **CONFIRM BEFORE SUBMISSION** |
| Contact email | `support@amnios-group.com` |
| Contact phone | **CONFIRM BEFORE SUBMISSION** |

### Review notes

```text
Vorb is a native macOS push-to-talk transcription utility. It has no account, subscription, advertising, analytics, or in-app purchases. No API key is required for review.

Recommended review path:
1. Launch Vorb and open Settings.
2. Under Transcription, choose Local Whisper.
3. Choose the Tiny model and click “Download Model.” An internet connection is required only for that explicit download.
4. Press Option–Space, grant microphone access when macOS asks, and speak a short sentence.
5. Press Option–Space again. The recording orb disappears immediately while transcription continues.
6. When transcription completes, the result is copied to the clipboard. It also appears in History if “Preserve transcript history” is enabled.

The App Store build intentionally does not control another app or synthesize a paste command. App Sandbox permits clipboard copy but not the cross-app Accessibility automation used by the separately distributed direct build. The Store build therefore presents clipboard delivery as its supported result.

Hosted transcription is optional. If a reviewer chooses one, the reviewer must supply that provider’s own API key. Keys are stored in macOS Keychain, and audio is sent directly from the Mac to the selected endpoint. Amnios Group does not operate a Vorb backend.

The local-network permission is used only when the user explicitly configures a self-hosted transcription endpoint on the local network. User-selected read-only file access is used only when the user clicks Import Existing and chooses a WhisperKit model folder; Vorb validates and copies that model into its own container. Temporary audio files are deleted after every transcription attempt. Transcript history is optional, local, and user-deletable.

If the menu bar icon is hidden, Option–Space continues to work. Reopening Vorb from Finder or Spotlight restores access to Settings.

Support: support@amnios-group.com
```

### Attachments for review

No attachment is required. If the model host cannot be reached from App Review’s network, attach a short screen recording of the exact local test path above and provide the model-download host in the Resolution Center response.

## App Privacy

### Recommended App Store Connect answers

| Question | Answer |
| --- | --- |
| Does this app collect data? | No |
| Tracking | No |
| Uses data for third-party advertising | No |
| Uses data for developer advertising or marketing | No |

Rationale: Vorb has no Amnios Group backend, analytics, advertising SDK, telemetry, or developer account system. Local Whisper stays on-device. In hosted mode, the user deliberately sends audio directly to a provider they selected and separately authorized; Vorb includes no provider SDK, and Amnios Group cannot access the audio, transcript, key, or provider account. Apple defines collection as off-device data retained beyond real-time servicing by the developer or a third-party partner, and defines third-party partners around external code included in the app. The public privacy policy must still explain hosted-provider processing clearly.

Revisit this answer before every release. If Amnios Group adds analytics, a backend, crash reporting that transmits data, a provider SDK, or a commercial provider relationship that gives Amnios Group access to requests, disclose every affected data type. If App Review determines the built-in direct API integrations are third-party partners, use the conservative fallback below.

### Conservative fallback if App Review requests provider disclosure

Declare these data types only for optional hosted transcription:

| Data type | Purpose | Linked to identity | Tracking |
| --- | --- | --- | --- |
| Audio Data | App Functionality | Yes, because a provider API key may associate a request with the user’s provider account | No |
| Other User Content (transcript) | App Functionality | Yes, because the selected provider may associate the result with the user’s provider account | No |
| User ID | App Functionality | Yes; the provider credential identifies the provider account | No |

Do not use the fallback merely to describe Local Whisper; local transcription is not collected.

## Age rating questionnaire

Select **No** for capability and in-app-control questions and **None** for every content-frequency question:

| Section | Item | Answer |
| --- | --- | --- |
| In-App Controls | Parental Controls | No |
| In-App Controls | Age Assurance | No |
| Capabilities | Unrestricted Web Access | No |
| Capabilities | User-Generated Content | No |
| Capabilities | Social Media | No |
| Capabilities | Social Media Disabled for Users Under 13 | No |
| Capabilities | Messaging and Chat | No |
| Capabilities | Advertising | No |
| Mature Themes | Profanity or Crude Humor | None |
| Mature Themes | Horror/Fear Themes | None |
| Mature Themes | Alcohol, Tobacco, or Drug Use or References | None |
| Medical or Wellness | Medical or Treatment Information | None |
| Medical or Wellness | Health or Wellness Topics | None |
| Sexuality or Nudity | Mature or Suggestive Themes | None |
| Sexuality or Nudity | Sexual Content or Nudity | None |
| Sexuality or Nudity | Graphic Sexual Content and Nudity | None |
| Violence | Cartoon or Fantasy Violence | None |
| Violence | Realistic Violence | None |
| Violence | Prolonged Graphic or Sadistic Realistic Violence | None |
| Violence | Guns or Other Weapons | None |
| Chance-Based Activities | Gambling | None |
| Chance-Based Activities | Simulated Gambling | None |
| Chance-Based Activities | Contests | None |
| Chance-Based Activities | Loot Boxes | No / None, matching the control shown |

Additional answers:

| Field | Answer |
| --- | --- |
| Made for Kids | No |
| Age-rating override | None |
| Expected global rating | 4+ |

Private dictation is not User-Generated Content for this questionnaire because Vorb does not broadly distribute it. It also does not provide communication between users.

## Content rights, encryption, and compliance

| Field | Recommended answer |
| --- | --- |
| Content Rights | No, the app does not contain, show, or access third-party media content. Its third-party software dependencies and visual inspiration are used under their licenses and documented in `THIRD_PARTY_NOTICES.md`. |
| Export compliance | The app uses only exempt encryption provided by Apple’s operating system for HTTPS/TLS and Keychain. It contains no proprietary or non-exempt cryptography. `ITSAppUsesNonExemptEncryption` is `false`. |
| Advertising identifier / IDFA | Not used |
| ATT prompt | Not applicable |
| Regulated Medical Device | Not applicable; the app is neither Health & Fitness nor Medical and provides no medical functionality |
| App Store Server Notifications | Leave blank; no In-App Purchases or subscriptions |
| Routing App Coverage File | Not applicable |
| Game Center | Not used |
| Sign in with Apple | Not applicable; Vorb has no account system |
| Digital Services Act trader status | **ACCOUNT HOLDER MUST CONFIRM.** If Amnios Group distributes the app as part of its business, select Trader and complete Apple’s verified address, phone, and email requirements. |
| Labels and Markings URL | Leave blank unless required by the confirmed DSA/legal status |
| Availability in China mainland | No special license is expected for this productivity utility, but the account holder must confirm availability and local compliance. |
| Availability in Republic of Korea | No GRAC classification expected because Vorb is not a game. Complete organization contact fields if App Store Connect requires them. |
| Availability in Vietnam | No game license expected because Vorb is not a game. |

Legal and export answers are product facts, not legal advice; the App Store account holder remains responsible for the declarations.

## Availability and distribution

| Field | Recommended setting |
| --- | --- |
| Distribution method | Public — App Store |
| Territories | All territories available to the account, subject to the account holder’s compliance review |
| Mac availability | macOS only; Apple silicon; macOS 14 or later |
| Pre-order | No |
| Educational volume purchase | Available at the standard free price |
| Business volume purchase | Available at the standard free price |

## App Accessibility

Accessibility Nutrition Labels are optional and can only be published for a device after a live version exists. Do not claim labels for 1.0 without testing every common task against Apple’s criteria.

Recommended initial state: leave all Mac labels unpublished. After hands-on testing, consider publishing only verified support for:

- Dark Interface
- Sufficient Contrast
- Differentiate Without Color Alone
- VoiceOver

Do not claim Voice Control until a user can start and stop Vorb’s custom recorder using only voice. Do not claim Reduced Motion until the animated orb responds to the system setting, and do not claim Larger Text until common tasks remain usable at Apple’s required enlargement. These behaviors are not established by the current implementation.

Captions and Audio Descriptions are not applicable because Vorb has no video content. A SwiftUI implementation alone is not enough evidence to publish an accessibility claim.

## App Tags

Apple generates U.S. tags from the English metadata and allows deselection rather than free-form entry. Keep relevant generated tags such as **Dictation**, **Transcription**, **Productivity**, **Speech to Text**, **Voice Input**, or **Writing Tools**. Deselect any generated tag that suggests recording storage, social audio, meetings, translation, or AI chat.

## TestFlight metadata (English, U.S.)

### Beta app description

```text
Vorb is a native macOS push-to-talk dictation app. Press Option–Space, speak, and press it again to turn your voice into text. Run Whisper locally with no API key, or connect a hosted, self-hosted, or custom transcription provider using your own credentials. Vorb can copy results to the clipboard and preserve an optional local transcript history.
```

### Feedback email

```text
support@amnios-group.com
```

### What to test

```text
Please focus on the complete dictation flow:

• Select Local Whisper, download a model, and transcribe several short and long recordings.
• Import a complete existing WhisperKit model folder and confirm it remains available after relaunch.
• Start and stop recording with Option–Space while different apps are active, then test a custom shortcut.
• Test both toggle-to-speak and hold-to-speak behavior.
• Confirm the compact orb keeps its black circular background without any square panel backing or outer border, and disappears immediately after recording stops.
• Verify that completed text is copied to the clipboard.
• Enable and disable local transcript history, then copy and delete individual entries and clear the history.
• Hide the menu bar icon, confirm the global shortcut still works, and reopen Vorb from Finder or Spotlight.
• If you already use a supported transcription provider, test it with your own key and report the provider, model, language, macOS version, and Mac model with any issue.

Please do not include API keys, private recordings, or sensitive transcript text in feedback. Send reports to support@amnios-group.com.
```

### TestFlight review contact

Use the same first name, last name, email, and phone number as the App Review contact. No login information is required.

## Final account-owner checklist

Before copying this metadata into App Store Connect:

- Publish and manually verify the support, privacy, and marketing URLs.
- Supply a real App Review contact name and phone number.
- Confirm the DSA trader declaration and territory availability.
- Confirm the App Privacy answer against the final binary and every bundled third-party component.
- Reserve the name “Vorb” in App Store Connect and verify that the subtitle’s use of “Whisper” does not conflict with any current trademark or metadata review requirement.
- A public U.S. App Store search on July 22, 2026 returned no exact “Vorb” listing, but only App Store Connect can confirm name availability.
- Upload at least one 16:10 Mac screenshot; five polished screenshots are recommended.
- Select the signed, sandboxed App Store build—not the direct-distribution build.

## Apple field limits used

- App name: 30 characters
- Subtitle: 30 characters
- Promotional text: 170 characters
- Description: 4,000 characters
- Keywords: 100 bytes
- What’s New: 4,000 characters
- App Review notes: 4,000 bytes
- Mac screenshots: 1–10; 16:10 sizes including 2880 × 1800

These limits and questionnaire recommendations were checked against Apple’s App Store Connect documentation on July 22, 2026.

## Apple references

- [App information fields](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Platform version fields and limits](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Mac screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [App Privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Age-rating values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
- [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
- [App Tags](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-tags/)
- [TestFlight test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)
