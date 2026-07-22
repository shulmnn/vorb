#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
app_path="$repo_root/dist/app-store/Vorb.app"
raw_root="$repo_root/Design/AppStoreScreenshots/Raw"
fixture_root="$repo_root/Design/AppStoreScreenshots/Fixtures/history"
bundle_id="com.amnios.vorb"
capture_dir="$(mktemp -d /tmp/vorb-localized-captures.XXXXXX)"
container_root="$HOME/Library/Containers/$bundle_id/Data/Library"
container_prefs="$container_root/Preferences/$bundle_id.plist"
history_path="$container_root/Application Support/Vorb/transcription-history.json"

locales=(de-DE fr-FR es-ES pt-BR it ja ko zh-Hans ru)

if [[ ! -x "$app_path/Contents/MacOS/Vorb" ]]; then
    echo "Build the App Store app first: ./Scripts/package_app_store.sh" >&2
    exit 1
fi

defaults export "$bundle_id" "$capture_dir/defaults.plist" >/dev/null 2>&1 || true
if [[ -f "$container_prefs" ]]; then
    cp "$container_prefs" "$capture_dir/container-preferences.plist"
fi
if [[ -f "$history_path" ]]; then
    cp "$history_path" "$capture_dir/transcription-history.json"
    touch "$capture_dir/history-existed"
fi

quit_vorb() {
    osascript -e 'tell application "Vorb" to quit' >/dev/null 2>&1 || true
    for _ in {1..30}; do
        pgrep -x Vorb >/dev/null 2>&1 || return 0
        sleep 0.1
    done
    pkill -TERM -x Vorb >/dev/null 2>&1 || true
    sleep 0.3
}

restore_user_state() {
    quit_vorb
    if [[ -f "$capture_dir/defaults.plist" ]]; then
        defaults import "$bundle_id" "$capture_dir/defaults.plist" >/dev/null 2>&1 || true
    fi
    if [[ -f "$capture_dir/container-preferences.plist" ]]; then
        mkdir -p "${container_prefs:h}"
        cp "$capture_dir/container-preferences.plist" "$container_prefs"
    fi
    if [[ -f "$capture_dir/history-existed" ]]; then
        mkdir -p "${history_path:h}"
        cp "$capture_dir/transcription-history.json" "$history_path"
    else
        rm -f "$history_path"
    fi
    killall cfprefsd >/dev/null 2>&1 || true
}
trap restore_user_state EXIT INT TERM

wait_for_settings() {
    for _ in {1..60}; do
        if osascript -e 'tell application "System Events" to tell process "Vorb" to return (count of windows) > 0' 2>/dev/null | grep -q true; then
            return 0
        fi
        sleep 0.2
    done
    echo "Timed out waiting for the Vorb settings window" >&2
    return 1
}

ensure_settings() {
    if ! osascript -e 'tell application "System Events" to tell process "Vorb" to return (count of windows) > 0' 2>/dev/null | grep -q true; then
        osascript -e 'tell application "Vorb" to reopen' >/dev/null
        osascript -e 'tell application "Vorb" to activate' >/dev/null
        wait_for_settings
        sleep 0.5
    fi
}

settings_rect() {
    osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Vorb"
        set targetWindow to first window
        set windowPosition to position of targetWindow
        set windowSize to size of targetWindow
        return (item 1 of windowPosition as text) & "," & (item 2 of windowPosition as text) & "," & (item 1 of windowSize as text) & "," & (item 2 of windowSize as text)
    end tell
end tell
APPLESCRIPT
}

select_custom_provider() {
    osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Vorb"
        set servicePicker to pop up button 1 of scroll area 1 of group 1 of first window
        click servicePicker
        delay 0.4
        click last menu item of menu 1 of servicePicker
    end tell
end tell
APPLESCRIPT
}

select_tab() {
    local index="$1"
    osascript - "$index" <<'APPLESCRIPT'
on run arguments
    set tabIndex to item 1 of arguments as integer
    tell application "System Events"
        tell process "Vorb"
            try
                click radio button tabIndex of radio group 1 of group 1 of toolbar 1 of first window
            on error
                -- macOS collapses long localized tab names into a toolbar
                -- overflow menu. The menu preserves the original tab order.
                set overflowPicker to pop up button 1 of toolbar 1 of first window
                click overflowPicker
                delay 0.3
                click menu item tabIndex of menu 1 of overflowPicker
            end try
        end tell
    end tell
end run
APPLESCRIPT
}

open_history() {
    osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Vorb"
        click button 1 of scroll area 1 of group 1 of first window
    end tell
end tell
APPLESCRIPT
}

history_rect() {
    osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Vorb"
        repeat with targetWindow in windows
            set windowSize to size of targetWindow
            if item 1 of windowSize > 620 then
                set windowPosition to position of targetWindow
                return (item 1 of windowPosition as text) & "," & (item 2 of windowPosition as text) & "," & (item 1 of windowSize as text) & "," & (item 2 of windowSize as text)
            end if
        end repeat
        error "History window not found"
    end tell
end tell
APPLESCRIPT
}

for locale in $locales; do
    echo "Capturing $locale"
    quit_vorb
    mkdir -p "${history_path:h}" "$raw_root/$locale"
    cp "$fixture_root/$locale.json" "$history_path"

    defaults write "$bundle_id" transcriptionProvider -string localWhisper
    defaults write "$bundle_id" 'providerModel.localWhisper' -string openai_whisper-base
    defaults write "$bundle_id" transcriptionLanguage -string ''
    defaults write "$bundle_id" preserveHistory -bool true
    defaults write "$bundle_id" showMenuBarIcon -bool true
    killall cfprefsd >/dev/null 2>&1 || true

    open -n "$app_path" --args -AppleLanguages "($locale)"
    sleep 1
    osascript -e 'tell application "Vorb" to reopen' >/dev/null
    osascript -e 'tell application "Vorb" to activate' >/dev/null
    wait_for_settings
    sleep 0.8

    ensure_settings
    rect="$(settings_rect)"
    screencapture -x -R"$rect" "$raw_root/$locale/settings-local.png"

    ensure_settings
    select_custom_provider >/dev/null
    sleep 1.2
    rect="$(settings_rect)"
    screencapture -x -R"$rect" "$raw_root/$locale/settings-provider.png"

    ensure_settings
    select_tab 2 >/dev/null
    sleep 0.8
    rect="$(settings_rect)"
    screencapture -x -R"$rect" "$raw_root/$locale/settings-shortcut.png"

    ensure_settings
    select_tab 3 >/dev/null
    sleep 0.8
    open_history >/dev/null
    sleep 0.8
    rect="$(history_rect)"
    screencapture -x -R"$rect" "$raw_root/$locale/history.png"
done

restore_user_state
trap - EXIT INT TERM
echo "Captured ${#locales} localized native UI sets."
