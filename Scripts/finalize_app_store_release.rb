#!/usr/bin/env ruby

require "pathname"
require "spaceship"

APP_ID = ENV.fetch("ASC_APP_ID", "6793676551")
APP_VERSION = ENV.fetch("ASC_APP_VERSION", "1.0")
BUILD_NUMBER = ENV.fetch("ASC_BUILD_NUMBER", "2")
PLATFORM = Spaceship::ConnectAPI::Platform::MAC_OS
SCREENSHOTS_PATH = Pathname.new(
  ENV.fetch(
    "ASC_SCREENSHOTS_PATH",
    File.expand_path("../dist/app-store/upload-screenshots-1-0", __dir__)
  )
)

def with_retry(label, attempts: 6)
  attempt = 0
  begin
    attempt += 1
    yield
  rescue StandardError => error
    raise if attempt >= attempts

    wait = [attempt * 3, 15].min
    warn "#{label} failed (attempt #{attempt}/#{attempts}); retrying in #{wait}s: #{error.class}"
    sleep(wait)
    retry
  end
end

def selected_build(version)
  version.get_build
rescue RuntimeError => error
  return nil if error.message == "No data"

  raise
end

token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("ASC_KEY_ID"),
  issuer_id: ENV.fetch("ASC_ISSUER_ID"),
  filepath: ENV.fetch("ASC_KEY_PATH")
)
Spaceship::ConnectAPI.token = token

app = with_retry("Fetch app") { Spaceship::ConnectAPI::App.get(app_id: APP_ID) }
abort "App #{APP_ID} was not found" unless app

version = with_retry("Fetch editable macOS version") do
  app.get_edit_app_store_version(platform: PLATFORM)
end
abort "Editable macOS version #{APP_VERSION} was not found" unless version&.version_string == APP_VERSION

app_info = with_retry("Fetch editable app info") { app.fetch_edit_app_info }
abort "Editable app info was not found" unless app_info

with_retry("Set App Store categories") do
  app_info.update_categories(
    category_id_map: {
      primary_category_id: "PRODUCTIVITY",
      secondary_category_id: "UTILITIES"
    }
  )
end

deadline = Time.now + 20 * 60
target_build = nil
loop do
  target_build = with_retry("Fetch build #{BUILD_NUMBER}") do
    Spaceship::ConnectAPI::Build.all(
      app_id: APP_ID,
      version: APP_VERSION,
      build_number: BUILD_NUMBER,
      platform: PLATFORM
    ).first
  end

  abort "Build #{BUILD_NUMBER} was not found" unless target_build
  break unless target_build.processing_state == Spaceship::ConnectAPI::Build::ProcessingState::PROCESSING
  abort "Build #{BUILD_NUMBER} did not finish processing within 20 minutes" if Time.now >= deadline

  puts "Build #{BUILD_NUMBER} is still processing; checking again in 20s."
  sleep(20)
end

unless target_build.processing_state == Spaceship::ConnectAPI::Build::ProcessingState::VALID
  abort "Build #{BUILD_NUMBER} is #{target_build.processing_state}, not VALID"
end

selected_build = with_retry("Fetch selected build") { selected_build(version) }
if selected_build&.id != target_build.id
  with_retry("Select build #{BUILD_NUMBER}") do
    version.select_build(build_id: target_build.id)
  end
  selected_build = with_retry("Verify selected build") { selected_build(version) }
end
abort "Build #{BUILD_NUMBER} was not selected" unless selected_build&.id == target_build.id

fresh_info = with_retry("Refresh app info") { app.fetch_edit_app_info }
unless fresh_info.primary_category&.id == "PRODUCTIVITY" && fresh_info.secondary_category&.id == "UTILITIES"
  abort "App Store categories do not match Productivity and Utilities"
end

expected_locales = SCREENSHOTS_PATH.children.select(&:directory?).map { |path| path.basename.to_s }.sort
version_localizations = with_retry("Fetch version localizations") do
  version.get_app_store_version_localizations
end.to_h { |localization| [localization.locale, localization] }

errors = []
verified_screenshot_count = 0
expected_locales.each do |locale|
  localization = version_localizations[locale]
  if localization.nil?
    errors << "#{locale}: missing version localization"
    next
  end

  sets = with_retry("Fetch screenshots for #{locale}") do
    localization.get_app_screenshot_sets(includes: "appScreenshots")
  end
  desktop_set = sets.find do |set|
    set.screenshot_display_type == Spaceship::ConnectAPI::AppScreenshotSet::DisplayType::APP_DESKTOP
  end
  screenshots = desktop_set&.app_screenshots || []
  verified_screenshot_count += screenshots.length
  errors << "#{locale}: expected 8 desktop screenshots, found #{screenshots.length}" unless screenshots.length == 8
  incomplete = screenshots.reject(&:complete?)
  errors << "#{locale}: #{incomplete.length} screenshot(s) are not fully processed" unless incomplete.empty?
end

unless errors.empty?
  warn errors.join("\n")
  abort "App Store release verification failed with #{errors.length} difference(s)."
end

puts "Build #{BUILD_NUMBER} is VALID and selected for Vorb #{APP_VERSION}."
puts "Verified Productivity / Utilities categories."
puts "Verified #{verified_screenshot_count} processed Mac screenshots across #{expected_locales.length} locales."
puts "The version remains #{version.app_version_state}; it was not submitted for review."
