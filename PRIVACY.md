# Vorb Privacy Policy

Last updated: July 22, 2026

Vorb does not require an account and Amnios Group does not operate an application backend for it. Vorb does not include analytics, advertising, tracking, or telemetry.

## Audio and transcripts

When Local Whisper is selected, audio is transcribed on the Mac and is not sent to Amnios Group or a transcription provider. The optional model is downloaded from the WhisperKit model repository.

If the user chooses Import Existing, Vorb receives read-only access to the folder selected through the macOS file picker, validates the WhisperKit model, and copies it into Vorb’s Application Support directory. Vorb does not scan other files or folders.

When a hosted or self-hosted provider is selected, Vorb sends the recorded audio directly from the Mac to the endpoint chosen by the user. A self-hosted endpoint may be on the user’s local network. That provider processes the audio under its own terms and privacy policy. Amnios Group does not receive the audio or transcript.

Temporary audio files are deleted after each transcription attempt. Transcript history is optional and is stored locally. Users can delete individual transcripts or clear the complete history from the app.

## Credentials and clipboard

Provider API keys are stored in macOS Keychain. Vorb accesses the clipboard only when the user enables transcript copying or automatic paste. The direct-download build can temporarily preserve and restore clipboard contents while pasting.

## Your choices and deletion

Users can disable transcript history, delete individual transcripts, or clear all history from Vorb. Downloaded Local Whisper models can be removed individually or by clearing the model cache. Microphone permission can be revoked at any time in macOS System Settings. Choosing Local Whisper prevents recorded audio from being sent to a hosted transcription provider.

Vorb does not maintain an account or server-side profile, so Amnios Group has no account data to export or delete.

## Contact

For privacy questions or support, email [support@amnios-group.com](mailto:support@amnios-group.com).

Public policy URL: [https://vorb.shulmnn.com/privacy](https://vorb.shulmnn.com/privacy)
