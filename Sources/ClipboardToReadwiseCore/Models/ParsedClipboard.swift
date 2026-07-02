import Foundation

public struct ParsedClipboard: Equatable, Sendable {
    public let title: String
    public let highlights: [String]

    public init(title: String, highlights: [String]) {
        self.title = title
        self.highlights = highlights
    }
}
