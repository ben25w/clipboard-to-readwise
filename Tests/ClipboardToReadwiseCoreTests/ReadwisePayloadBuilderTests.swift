import XCTest
@testable import ClipboardToReadwiseCore

final class ReadwisePayloadBuilderTests: XCTestCase {
    func testCategoryAuthorAndSequentialLocationsAreIncluded() throws {
        let parsed = ParsedClipboard(title: "Document", highlights: ["One", "Two"])
        let config = ReadwiseConfiguration(author: "Ben", category: .articles)

        let request = ReadwisePayloadBuilder.build(parsed: parsed, configuration: config)

        XCTAssertEqual(request.highlights.map(\.location), [1, 2])
        XCTAssertEqual(request.highlights.map(\.locationType), ["order", "order"])
        XCTAssertEqual(request.highlights.map(\.sourceType), ["clipboard_to_readwise", "clipboard_to_readwise"])
        XCTAssertEqual(request.highlights.map(\.category), [.articles, .articles])
        XCTAssertEqual(request.highlights.map(\.author), ["Ben", "Ben"])
    }

    func testBlankAuthorIsOmittedFromJSON() throws {
        let parsed = ParsedClipboard(title: "Document", highlights: ["One"])
        let config = ReadwiseConfiguration(author: "  ", category: .books)

        let request = ReadwisePayloadBuilder.build(parsed: parsed, configuration: config)
        let json = try encodedJSONString(request)

        XCTAssertFalse(json.contains("\"author\""))
        XCTAssertTrue(json.contains("\"category\":\"books\""))
    }

    func testTokenIsNotPartOfPayload() throws {
        let parsed = ParsedClipboard(title: "Document", highlights: ["One"])
        let config = ReadwiseConfiguration(author: "Ben", category: .tweets)
        let token = "secret-token-that-must-not-be-encoded"

        let request = ReadwisePayloadBuilder.build(parsed: parsed, configuration: config)
        let json = try encodedJSONString(request)

        XCTAssertFalse(json.contains(token))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("token"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("authorization"))
    }

    private func encodedJSONString(_ request: ReadwiseHighlightsRequest) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(request)
        return String(decoding: data, as: UTF8.self)
    }
}
