import Foundation

enum OverlayStyle: String, CaseIterable, Identifiable, Codable {
    case orbOnly
    case detailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orbOnly: localized("Orb only")
        case .detailed: localized("Detailed")
        }
    }

    var detail: String {
        switch self {
        case .orbOnly:
            localized("A compact floating orb with no status text.")
        case .detailed:
            localized("The larger pill with status and shortcut guidance.")
        }
    }
}
