import Foundation

public struct ReadwiseConfiguration: Equatable, Sendable {
    public let author: String
    public let category: ReadwiseCategory

    public init(author: String, category: ReadwiseCategory) {
        self.author = author
        self.category = category
    }
}
