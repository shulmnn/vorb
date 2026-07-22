import Foundation

func localized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
    String(
        format: localized(key),
        locale: Locale.current,
        arguments: arguments
    )
}
