import Foundation

public enum ReadwisePayloadBuilder {
    public static let sourceType = "clipboard_to_readwise"

    public static func build(
        parsed: ParsedClipboard,
        configuration: ReadwiseConfiguration
    ) -> ReadwiseHighlightsRequest {
        let trimmedAuthor = configuration.author.trimmingCharacters(in: .whitespacesAndNewlines)
        let author = trimmedAuthor.isEmpty ? nil : trimmedAuthor

        let highlights = parsed.highlights.enumerated().map { index, text in
            ReadwiseHighlightPayload(
                text: text,
                title: parsed.title,
                author: author,
                sourceType: sourceType,
                category: configuration.category,
                location: index + 1,
                locationType: "order"
            )
        }

        return ReadwiseHighlightsRequest(highlights: highlights)
    }
}

public struct ReadwiseHighlightsRequest: Codable, Equatable, Sendable {
    public let highlights: [ReadwiseHighlightPayload]

    public init(highlights: [ReadwiseHighlightPayload]) {
        self.highlights = highlights
    }
}

public struct ReadwiseHighlightPayload: Codable, Equatable, Sendable {
    public let text: String
    public let title: String
    public let author: String?
    public let sourceType: String
    public let category: ReadwiseCategory
    public let location: Int
    public let locationType: String

    public init(
        text: String,
        title: String,
        author: String?,
        sourceType: String,
        category: ReadwiseCategory,
        location: Int,
        locationType: String
    ) {
        self.text = text
        self.title = title
        self.author = author
        self.sourceType = sourceType
        self.category = category
        self.location = location
        self.locationType = locationType
    }

    private enum CodingKeys: String, CodingKey {
        case text
        case title
        case author
        case sourceType = "source_type"
        case category
        case location
        case locationType = "location_type"
    }
}
