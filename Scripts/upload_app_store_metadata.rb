#!/usr/bin/env ruby

require "pathname"
require "spaceship"

APP_ID = ENV.fetch("ASC_APP_ID", "6793676551")
APP_VERSION = ENV.fetch("ASC_APP_VERSION", "1.0")
PLATFORM = Spaceship::ConnectAPI::Platform::MAC_OS
VERIFY_ONLY = ENV["ASC_VERIFY_ONLY"] == "1"
METADATA_PATH = Pathname.new(
  ENV.fetch(
    "ASC_METADATA_PATH",
    File.expand_path("../dist/app-store/upload-metadata-1-0", __dir__)
  )
)

VERSION_FIELDS = {
  "description.txt" => :description,
  "keywords.txt" => :keywords,
  "marketing_url.txt" => :marketing_url,
  "promotional_text.txt" => :promotional_text,
  "support_url.txt" => :support_url
}.freeze

APP_INFO_FIELDS = {
  "name.txt" => :name,
  "subtitle.txt" => :subtitle,
  "privacy_url.txt" => :privacy_policy_url
}.freeze

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

def attributes_from(directory, mapping)
  mapping.each_with_object({}) do |(filename, attribute), attributes|
    path = directory.join(filename)
    next unless path.file?

    value = path.read(encoding: "UTF-8").strip
    attributes[attribute] = value unless value.empty?
  end
end

unless METADATA_PATH.directory?
  abort "Metadata directory not found: #{METADATA_PATH}"
end

token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("ASC_KEY_ID"),
  issuer_id: ENV.fetch("ASC_ISSUER_ID"),
  filepath: ENV.fetch("ASC_KEY_PATH")
)
Spaceship::ConnectAPI.token = token

app = with_retry("Fetch app") do
  Spaceship::ConnectAPI::App.get(app_id: APP_ID)
end
abort "App #{APP_ID} was not found" unless app

version = with_retry("Fetch editable macOS version") do
  app.get_edit_app_store_version(platform: PLATFORM)
end
abort "Editable macOS version #{APP_VERSION} was not found" unless version&.version_string == APP_VERSION

app_info = with_retry("Fetch editable app info") do
  app.fetch_edit_app_info
end
abort "Editable app info was not found" unless app_info

unless VERIFY_ONLY
  with_retry("Update version release settings") do
    version.update(
      attributes: {
        copyright: "2026 Amnios Group",
        release_type: Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::MANUAL
      }
    )
  end
end

version_localizations = with_retry("Fetch version localizations") do
  version.get_app_store_version_localizations
end.to_h { |localization| [localization.locale, localization] }

info_localizations = with_retry("Fetch app info localizations") do
  app_info.get_app_info_localizations
end.to_h { |localization| [localization.locale, localization] }

locale_directories = METADATA_PATH.children.select(&:directory?).sort_by { |path| path.basename.to_s }

unless VERIFY_ONLY
  locale_directories.each_with_index do |directory, index|
    locale = directory.basename.to_s

    version_localization = version_localizations[locale] || with_retry("Create version localization #{locale}") do
      version.create_app_store_version_localization(attributes: { locale: locale })
    end

    info_localization = info_localizations[locale] || with_retry("Create app info localization #{locale}") do
      app_info.create_app_info_localization(attributes: { locale: locale })
    end

    with_retry("Update version localization #{locale}") do
      version_localization.update(attributes: attributes_from(directory, VERSION_FIELDS))
    end

    with_retry("Update app info localization #{locale}") do
      info_localization.update(attributes: attributes_from(directory, APP_INFO_FIELDS))
    end

    puts "[#{index + 1}/#{locale_directories.length}] Uploaded #{locale}"
    sleep(0.25)
  end

  puts "Uploaded #{locale_directories.length} App Store localizations for Vorb #{APP_VERSION}."
end

fresh_version = with_retry("Refresh editable macOS version") do
  app.get_edit_app_store_version(platform: PLATFORM)
end
fresh_info = with_retry("Refresh editable app info") do
  app.fetch_edit_app_info
end

fresh_version_localizations = with_retry("Refresh version localizations") do
  fresh_version.get_app_store_version_localizations
end.to_h { |localization| [localization.locale, localization] }
fresh_info_localizations = with_retry("Refresh app info localizations") do
  fresh_info.get_app_info_localizations
end.to_h { |localization| [localization.locale, localization] }

errors = []
locale_directories.each do |directory|
  locale = directory.basename.to_s
  version_localization = fresh_version_localizations[locale]
  info_localization = fresh_info_localizations[locale]

  if version_localization.nil?
    errors << "#{locale}: missing version localization"
  else
    attributes_from(directory, VERSION_FIELDS).each do |attribute, expected|
      actual = version_localization.public_send(attribute).to_s.strip
      errors << "#{locale}: #{attribute} differs" unless actual == expected
    end
  end

  if info_localization.nil?
    errors << "#{locale}: missing app info localization"
  else
    attributes_from(directory, APP_INFO_FIELDS).each do |attribute, expected|
      actual = info_localization.public_send(attribute).to_s.strip
      errors << "#{locale}: #{attribute} differs" unless actual == expected
    end
  end
end

errors << "copyright differs" unless fresh_version.copyright == "2026 Amnios Group"
errors << "release type is not manual" unless fresh_version.release_type == Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::MANUAL

unless errors.empty?
  warn errors.join("\n")
  abort "App Store metadata verification failed with #{errors.length} difference(s)."
end

puts "Verified #{locale_directories.length} version localizations, #{locale_directories.length} app info localizations, copyright, and manual release."
