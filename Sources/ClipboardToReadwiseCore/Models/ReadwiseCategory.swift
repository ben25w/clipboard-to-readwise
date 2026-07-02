import Foundation

public enum ReadwiseCategory: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case articles
    case books
    case tweets
    case podcasts

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .articles:
            "Articles"
        case .books:
            "Books"
        case .tweets:
            "Tweets"
        case .podcasts:
            "Podcasts"
        }
    }
}
