#!/usr/bin/env python3
"""Generate Vorb's 50 Apple localizations and matching App Store metadata."""

from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from urllib.error import URLError
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LOCALIZATIONS = ROOT / "Packaging" / "Localizations"
METADATA = ROOT / "AppStore" / "Metadata"
CACHE_PATH = ROOT / "AppStore" / "translation-cache.json"

# Apple's complete App Store localization set as of July 2026.
# Values are target codes understood by Google Translate's public web endpoint.
LOCALES = {
    "ar-SA": "ar",
    "bn": "bn",
    "ca": "ca",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
    "hr": "hr",
    "cs": "cs",
    "da": "da",
    "nl-NL": "nl",
    "en-AU": "en",
    "en-CA": "en",
    "en-GB": "en",
    "en-US": "en",
    "fi": "fi",
    "fr-FR": "fr",
    "fr-CA": "fr",
    "de-DE": "de",
    "el": "el",
    "gu": "gu",
    "he": "he",
    "hi": "hi",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "kn": "kn",
    "ko": "ko",
    "ms": "ms",
    "ml": "ml",
    "mr": "mr",
    "no": "no",
    "or": "or",
    "pl": "pl",
    "pt-BR": "pt",
    "pt-PT": "pt",
    "pa": "pa",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "sl": "sl",
    "es-MX": "es",
    "es-ES": "es",
    "sv": "sv",
    "ta": "ta",
    "te": "te",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "ur": "ur",
    "vi": "vi",
}

# Screenshot-facing release copy receives a human pass. These overrides also
# improve the corresponding in-app navigation and history UI.
MANUAL_OVERRIDES = {
    "de-DE": {
        "Vorb Settings": "Vorb-Einstellungen",
        "Vorb History": "Vorb-Verlauf",
        "Shortcut": "Kurzbefehl",
        "Behavior": "Verhalten",
        "About": "Info",
        "Private · no API key": "Privat · kein API-Schlüssel",
        "Transcription History": "Transkriptionsverlauf",
        "Stored locally on this Mac": "Lokal auf diesem Mac gespeichert",
        "Clear…": "Löschen…",
    },
    "fr-FR": {
        "Vorb Settings": "Réglages de Vorb",
        "Vorb History": "Historique de Vorb",
        "Shortcut": "Raccourci",
        "Behavior": "Comportement",
        "About": "À propos",
        "Private · no API key": "Privé · aucune clé API",
        "Transcription History": "Historique des transcriptions",
        "Stored locally on this Mac": "Stocké localement sur ce Mac",
        "Clear…": "Effacer…",
    },
    "es-ES": {
        "Vorb Settings": "Ajustes de Vorb",
        "Vorb History": "Historial de Vorb",
        "Shortcut": "Atajo",
        "Behavior": "General",
        "About": "Info",
        "Private · no API key": "Privado · sin clave API",
        "Transcription History": "Historial de transcripciones",
        "Stored locally on this Mac": "Guardado localmente en este Mac",
        "Clear…": "Borrar…",
    },
    "pt-BR": {
        "Vorb Settings": "Ajustes do Vorb",
        "Vorb History": "Histórico do Vorb",
        "Shortcut": "Atalho",
        "Behavior": "Geral",
        "About": "Sobre",
        "Private · no API key": "Privado · sem chave de API",
        "Transcription History": "Histórico de transcrições",
        "Stored locally on this Mac": "Armazenado localmente neste Mac",
        "Clear…": "Limpar…",
    },
    "it": {
        "Vorb Settings": "Impostazioni di Vorb",
        "Vorb History": "Cronologia di Vorb",
        "Shortcut": "Tasti",
        "Behavior": "Generale",
        "About": "Info",
        "Private · no API key": "Privato · nessuna chiave API",
        "Transcription History": "Cronologia trascrizioni",
        "Stored locally on this Mac": "Salvata localmente su questo Mac",
        "Clear…": "Cancella…",
    },
    "ja": {
        "Vorb Settings": "Vorb設定",
        "Vorb History": "Vorb履歴",
        "Transcription": "文字起こし",
        "Shortcut": "ショートカット",
        "Behavior": "動作",
        "About": "情報",
        "Private · no API key": "プライベート · APIキー不要",
        "Transcription History": "文字起こし履歴",
        "Stored locally on this Mac": "このMacにローカル保存",
        "Clear…": "消去…",
    },
    "ko": {
        "Vorb Settings": "Vorb 설정",
        "Vorb History": "Vorb 기록",
        "Transcription": "받아쓰기",
        "Shortcut": "단축키",
        "Behavior": "동작",
        "About": "정보",
        "Private · no API key": "비공개 · API 키 불필요",
        "Transcription History": "받아쓰기 기록",
        "Stored locally on this Mac": "이 Mac에 로컬로 저장됨",
        "Clear…": "지우기…",
    },
    "zh-Hans": {
        "Vorb Settings": "Vorb 设置",
        "Vorb History": "Vorb 历史记录",
        "Transcription": "转写",
        "Shortcut": "快捷键",
        "Behavior": "行为",
        "About": "关于",
        "Private · no API key": "私密 · 无需 API 密钥",
        "Transcription History": "转写历史",
        "Stored locally on this Mac": "本地存储在这台 Mac 上",
        "Clear…": "清除…",
    },
    "ru": {
        "Vorb Settings": "Настройки Vorb",
        "Vorb History": "История Vorb",
        "Transcription": "Речь",
        "Shortcut": "Клавиши",
        "Behavior": "Режим",
        "About": "Инфо",
        "Private · no API key": "Приватно · без API-ключа",
        "Transcription History": "История расшифровок",
        "Stored locally on this Mac": "Хранится локально на этом Mac",
        "Clear…": "Очистить…",
    },
}

MODEL_DETAIL_STRINGS = [
    "Smallest and fastest; best for quick English dictation",
    "Lightweight multilingual transcription",
    "Recommended balance of speed and accuracy",
    "Highest local accuracy; larger download and memory use",
    "Fastest Groq option",
    "Higher accuracy",
    "Open-source Whisper V2 via the API",
    "Fast GPT transcription",
    "Highest-quality OpenAI option",
    "Routed hosted Whisper",
    "Faster hosted Whisper",
    "OpenAI Whisper through OpenRouter",
    "Fast OpenAI transcription",
    "High-quality OpenAI transcription",
    "Very fast English transcription",
    "Multilingual Google STT",
    "Mistral’s current batch transcription model",
    "Multilingual Whisper",
    "Best DeepInfra accuracy",
    "Balanced",
    "Faster",
    "Smallest",
    "Multilingual speech recognition",
    "Serverless multilingual Whisper",
    "OVHcloud’s multilingual transcription model",
    "Deepgram’s current general model",
    "Previous-generation general model",
    "Deepgram-hosted Whisper",
    "Current multilingual model",
    "Previous Scribe model",
    "Fast multilingual Whisper",
    "High-accuracy multilingual Whisper",
    "Use the name configured in LocalAI",
    "Downloaded automatically by Speaches",
    "High-quality faster-whisper model",
    "Multilingual Whisper NIM",
    "NVIDIA multilingual ASR",
    "Use the model loaded by your server",
    "Common default model ID",
]

UI_STRINGS = [
    "Vorb",
    "Vorb Settings",
    "Vorb History",
    "Transcription",
    "Shortcut",
    "Behavior",
    "About",
    "Provider",
    "Service",
    "Private · no API key",
    "Private on-device transcription with no API key",
    "Local Whisper",
    "Other OpenAI-compatible",
    "Fast hosted Whisper inference",
    "Whisper and GPT transcription models",
    "Routes OpenAI, Google, Groq, Mistral, NVIDIA, Qwen, and Microsoft STT",
    "Hosted Voxtral transcription",
    "Hosted Whisper and NVIDIA Parakeet",
    "Hosted open-source Whisper models",
    "Hosted multilingual SenseVoice transcription",
    "European-hosted Whisper transcription",
    "Whisper on OVHcloud AI Endpoints",
    "Nova and Whisper speech recognition",
    "Scribe multilingual speech recognition",
    "Whisper through Hugging Face Inference Providers",
    "Whisper on Cloudflare Workers AI",
    "Your Azure-hosted Whisper deployment",
    "Self-hosted Whisper, Moonshine, or faster-whisper",
    "Self-hosted faster-whisper server",
    "Self-hosted Whisper, Parakeet, Canary, or Nemotron ASR",
    "Self-hosted Whisper-compatible transcription",
    "Any server implementing OpenAI’s transcription endpoint",
    "Model & language",
    "Model",
    "Language",
    "Auto-detect",
    "Download Model",
    "Downloading…",
    "Downloading %@",
    "Reveal in Finder",
    "Remove…",
    "Remove Model",
    "Model page",
    "Import Existing…",
    "Clear Cache…",
    "Clear Model Cache",
    "Not downloaded",
    "Downloaded · %@",
    "The deployment or model is selected by the endpoint URL.",
    "Leave blank to auto-detect, or enter an ISO-639-1 code such as en, de, fr, or ru.",
    "Stored in Keychain. Audio goes directly to the selected provider.",
    "API documentation",
    "API key",
    "API key (optional)",
    "Endpoint",
    "Recommended models",
    "Global shortcut",
    "Start or stop dictation",
    "Toggle",
    "Hold",
    "Press once to start and again to stop.",
    "Hold the shortcut while speaking and release it to stop.",
    "How to change it",
    "Click the shortcut field, then press a key with Command, Option, or Control.",
    "Press Escape to cancel. The shortcut keeps working when the menu bar icon is hidden.",
    "Recording indicator",
    "Style",
    "Orb only",
    "Detailed",
    "A compact floating orb with no status text.",
    "The larger pill with status and shortcut guidance.",
    "Text delivery",
    "Paste into the previously active app",
    "Copy transcript to the clipboard",
    "The Mac App Store build copies text to the clipboard so you can paste it normally.",
    "Accessibility access is required for automatic paste",
    "Request Access",
    "Open Settings",
    "History & menu bar",
    "Save transcription history on this Mac",
    "1 saved transcript",
    "%lld saved transcripts",
    "Open History…",
    "Show Vorb in the menu bar",
    "Community",
    "View source and star Vorb on GitHub",
    "Report issues, request features, or fork Vorb for noncommercial use.",
    "Rate Vorb on the Mac App Store",
    "Help & privacy",
    "Privacy Policy",
    "Support",
    "Email Support",
    "No Vorb account, analytics, advertising, or application backend.",
    "Source available under the PolyForm Noncommercial License 1.0.0.",
    "Private Whisper dictation for macOS",
    "Version %@ (%@)",
    "Changes save automatically",
    "Start Dictation",
    "Stop Recording",
    "Transcribing…",
    "Copy Last Transcript",
    "History…",
    "Settings…",
    "Help & Community",
    "Star on GitHub",
    "Hide Menu Bar Icon",
    "Quit Vorb",
    "No Transcriptions Yet",
    "New transcripts appear here when history is enabled.",
    "Clear all transcription history?",
    "Clear History",
    "This removes the locally stored transcript text from this Mac.",
    "Transcription History",
    "Stored locally on this Mac",
    "Clear…",
    "Copy",
    "Delete",
    "Copy transcript",
    "Delete transcript",
    "Ready",
    "Listening…",
    "Done",
    "Couldn’t transcribe",
    "Press %@ to dictate",
    "Release %@ to finish",
    "Press %@ again to finish",
    "Click to stop recording",
    "Transcription complete",
    "Transcribing privately on this Mac",
    "Sending audio securely to %@",
    "Copied to the clipboard",
    "Saved to history",
    "Pasted and copied",
    "Pasted · clipboard preserved",
    "Remove the selected Whisper model?",
    "Vorb will require another download before this model can be used again.",
    "Clear all Local Whisper models?",
    "This removes every downloaded model and partial model download from Vorb.",
    "Import WhisperKit Model",
    "Import Model",
    "Choose the %@ model folder or a WhisperKit model repository containing it.",
    "Download the selected Whisper model before dictating",
    "No recording was available",
    "Enter a model name",
    "Enter a valid HTTP or HTTPS transcription endpoint",
    "Saved",
    "Saved · API key is in Keychain",
    "Custom model ID",
    "The deployment is selected by the endpoint URL",
    "Downloading",
    "Optional API key",
    "Hide API key",
    "Show API key",
    "Paste the full Workers AI model URL containing your Cloudflare account ID.",
    "Paste the full deployment transcription URL, including api-version.",
    "The local default can be replaced with any reachable server URL.",
    "The endpoint must accept OpenAI-style multipart file uploads.",
    "The saved shortcut could not be registered",
    "That shortcut is already in use",
    "Shortcut changed to %@",
    *MODEL_DETAIL_STRINGS,
]

MICROPHONE_DESCRIPTION = (
    "Vorb records audio only while you dictate. It transcribes on this Mac or "
    "sends the recording to the provider you selected."
)
LOCAL_NETWORK_DESCRIPTION = (
    "Vorb connects to transcription servers on your local network only when "
    "you choose a self-hosted provider."
)

SUBTITLE = "Private Whisper Dictation"
PROMOTIONAL_TEXT = (
    "Press Option–Space, speak, and copy the transcript. Run Whisper locally "
    "with no key, or bring your own provider—free, private, and subscription-free."
)
DESCRIPTION = """Vorb turns your voice into text with one keyboard shortcut.

Press Option–Space to start and stop, or choose hold-to-speak. Vorb transcribes your recording and copies the result to the clipboard.

PRIVATE · LOCAL WHISPER
Transcribe your voice into text entirely on your Mac with no API key. Models download only when you click Download Model. You can also import an existing WhisperKit model.

BRING YOUR OWN PROVIDER
Connect Groq, OpenAI, Deepgram, Mistral, ElevenLabs, a self-hosted server, or another compatible endpoint. Keys stay in macOS Keychain, and audio goes directly to the provider you select.

BUILT FOR FOCUSED WORK
• Configurable global shortcut
• Toggle-to-speak or hold-to-speak
• Minimal recording orb
• Clipboard delivery
• Optional local transcript history
• Automatic language detection
• No Vorb account, analytics, advertising, or subscription

Local Whisper requires Apple silicon. Online providers and model downloads require a network connection."""
KEYWORDS = "dictation,speech,text,voice,whisper,offline,clipboard,notes,typing,audio"
WHATS_NEW = (
    "Vorb is now available for macOS with local Whisper, bring-your-own-provider "
    "transcription, configurable shortcuts, clipboard delivery, and optional history."
)

METADATA_STRINGS = [
    SUBTITLE,
    PROMOTIONAL_TEXT,
    DESCRIPTION,
    KEYWORDS,
    WHATS_NEW,
    MICROPHONE_DESCRIPTION,
    LOCAL_NETWORK_DESCRIPTION,
]

CACHE_VERSION = 3

# Product, platform, protocol, and provider names must never be translated as
# ordinary words (for example, Whisper must not become “chuchotement”).
PROTECTED_TERMS = sorted(
    {
        "PolyForm Noncommercial License 1.0.0",
        "Cloudflare Workers AI",
        "OVHcloud AI Endpoints",
        "Mac App Store",
        "Hugging Face",
        "Local Whisper",
        "WhisperKit",
        "WhisperLiveKit",
        "Option–Space",
        "ISO-639-1",
        "Nemotron ASR",
        "faster-whisper",
        "SenseVoice",
        "Whisper",
        "OpenAI",
        "OpenRouter",
        "Deepgram",
        "DeepInfra",
        "ElevenLabs",
        "Cloudflare",
        "OVHcloud",
        "Microsoft",
        "NVIDIA",
        "Mistral",
        "Together AI",
        "Voxtral",
        "Parakeet",
        "Moonshine",
        "Keychain",
        "LocalAI",
        "Speaches",
        "GitHub",
        "Finder",
        "Command",
        "Option",
        "Control",
        "Escape",
        "macOS",
        "Vorb",
        "Groq",
        "Google",
        "Qwen",
        "Azure",
        "Nova",
        "Scribe",
        "API",
        "GPT",
        "STT",
        "ASR",
        "NIM",
        "Mac",
    },
    key=len,
    reverse=True,
)

PLACEHOLDERS = {
    # Bracketed numeric tokens survive Google Translate across every launch
    # language, including Arabic and CJK. Word-like placeholder names were
    # themselves translated in some locales and could not be restored.
    "%lld": "⟦900⟧",
    "%@": "⟦901⟧",
    **{
        term: f"⟦{index:03d}⟧"
        for index, term in enumerate(PROTECTED_TERMS)
    },
}


def load_cache() -> dict[str, dict[str, str]]:
    if not CACHE_PATH.exists():
        return {}
    payload = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    if payload.get("version") != CACHE_VERSION:
        return {}
    return payload.get("locales", {})


def save_cache(cache: dict[str, dict[str, str]]) -> None:
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(
        json.dumps(
            {"version": CACHE_VERSION, "locales": cache},
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def protect(value: str) -> str:
    for original, token in PLACEHOLDERS.items():
        value = value.replace(original, token)
    return value


def restore(value: str) -> str:
    for original, token in PLACEHOLDERS.items():
        value = value.replace(token, original)
    return value


def translate_text(value: str, target: str) -> str:
    if target == "en":
        return value
    query = urllib.parse.urlencode(
        {
            "client": "gtx",
            "sl": "en",
            "tl": target,
            "dt": "t",
            "q": protect(value),
        }
    )
    request = urllib.request.Request(
        f"https://translate.googleapis.com/translate_a/single?{query}",
        headers={"User-Agent": "Vorb-Localization-Builder/1.0"},
    )
    payload = fetch_translation(request)
    translated = "".join(segment[0] for segment in payload[0] if segment[0])
    return restore(translated)


def translate_batch(values: list[str], target: str) -> list[str]:
    if target == "en":
        return values
    separator = "\n---987654321---\n"
    joined = separator.join(protect(value) for value in values)
    query = urllib.parse.urlencode(
        {
            "client": "gtx",
            "sl": "en",
            "tl": target,
            "dt": "t",
            "q": joined,
        }
    )
    request = urllib.request.Request(
        f"https://translate.googleapis.com/translate_a/single?{query}",
        headers={"User-Agent": "Vorb-Localization-Builder/1.0"},
    )
    payload = fetch_translation(request)
    translated = "".join(segment[0] for segment in payload[0] if segment[0])
    parts = translated.split(separator)
    if len(parts) != len(values):
        return [translate_text(value, target) for value in values]
    return [restore(part) for part in parts]


def fetch_translation(request: urllib.request.Request) -> list:
    last_error: Exception | None = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.loads(response.read().decode("utf-8"))
        except (URLError, TimeoutError) as error:
            last_error = error
            time.sleep(0.4 * (attempt + 1))
    assert last_error is not None
    raise last_error


def translate_all(
    values: list[str],
    target: str,
    locale_cache: dict[str, str],
) -> dict[str, str]:
    missing = [value for value in values if value not in locale_cache]
    batch_size = 30
    for offset in range(0, len(missing), batch_size):
        batch = missing[offset : offset + batch_size]
        translated = translate_batch(batch, target)
        locale_cache.update(zip(batch, translated, strict=True))
        time.sleep(0.05)
    return locale_cache


def escape_strings(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def write_strings(path: Path, translations: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = ["/* Generated by Scripts/generate_localizations.py. */", ""]
    for key in UI_STRINGS:
        lines.append(f'"{escape_strings(key)}" = "{escape_strings(translations[key])}";')
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_info_plist_strings(path: Path, translations: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = (
        "/* Generated by Scripts/generate_localizations.py. */\n"
        '"CFBundleDisplayName" = "Vorb";\n'
        f'"NSMicrophoneUsageDescription" = "{escape_strings(translations[MICROPHONE_DESCRIPTION])}";\n'
        f'"NSLocalNetworkUsageDescription" = "{escape_strings(translations[LOCAL_NETWORK_DESCRIPTION])}";\n'
    )
    path.write_text(content, encoding="utf-8")


def trim_utf8_keywords(value: str, limit: int = 100) -> str:
    terms = [term.strip() for term in value.split(",") if term.strip()]
    chosen: list[str] = []
    for term in terms:
        candidate = ",".join([*chosen, term])
        if len(candidate.encode("utf-8")) <= limit:
            chosen.append(term)
    return ",".join(chosen)


def compact(value: str, limit: int) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    if len(value) <= limit:
        return value
    shortened = value[: limit - 1].rsplit(" ", 1)[0].rstrip(" ,.;:—-")
    return shortened + "…"


def write_metadata(locale: str, translations: dict[str, str]) -> None:
    folder = METADATA / locale
    folder.mkdir(parents=True, exist_ok=True)
    fields = {
        "name.txt": "Vorb",
        "subtitle.txt": compact(translations[SUBTITLE], 30),
        "promotional_text.txt": compact(translations[PROMOTIONAL_TEXT], 170),
        "description.txt": translations[DESCRIPTION].strip(),
        "keywords.txt": trim_utf8_keywords(translations[KEYWORDS]),
        "release_notes.txt": compact(translations[WHATS_NEW], 4000),
        "marketing_url.txt": "https://vorb.shulmnn.com",
        "support_url.txt": "https://vorb.shulmnn.com/support",
        "privacy_url.txt": "https://vorb.shulmnn.com/privacy",
    }
    for filename, value in fields.items():
        (folder / filename).write_text(value + "\n", encoding="utf-8")


def main() -> None:
    cache = load_cache()
    values = list(dict.fromkeys([*UI_STRINGS, *METADATA_STRINGS]))

    def build(item: tuple[str, str]) -> tuple[str, dict[str, str]]:
        locale, target = item
        print(f"Localizing {locale} ({target})", flush=True)
        translations = translate_all(values, target, dict(cache.get(locale, {})))
        translations.update(MANUAL_OVERRIDES.get(locale, {}))
        return locale, translations

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(build, item) for item in LOCALES.items()]
        for future in as_completed(futures):
            locale, translations = future.result()
            cache[locale] = translations
            save_cache(cache)
            lproj = LOCALIZATIONS / f"{locale}.lproj"
            write_strings(lproj / "Localizable.strings", translations)
            write_info_plist_strings(lproj / "InfoPlist.strings", translations)
            write_metadata(locale, translations)
            print(f"Finished {locale}", flush=True)

    print(f"Generated {len(LOCALES)} app and metadata localizations.")


if __name__ == "__main__":
    main()
