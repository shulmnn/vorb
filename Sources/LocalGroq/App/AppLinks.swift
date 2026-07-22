import Foundation

enum AppLinks {
    static let website = URL(string: "https://vorb.shulmnn.com")!
    static let privacy = URL(string: "https://vorb.shulmnn.com/privacy")!
    static let support = URL(string: "https://vorb.shulmnn.com/support")!
    static let github = URL(string: "https://github.com/shulmnn/vorb")!
    static let supportEmail = "support@amnios-group.com"
    static let supportEmailURL = URL(string: "mailto:\(supportEmail)")!

    static var appStoreReview: URL? {
        guard let identifier = Bundle.main.object(
            forInfoDictionaryKey: "VorbAppStoreID"
        ) as? String,
        !identifier.isEmpty else {
            return nil
        }
        return URL(
            string: "https://apps.apple.com/app/id\(identifier)?action=write-review"
        )
    }
}
