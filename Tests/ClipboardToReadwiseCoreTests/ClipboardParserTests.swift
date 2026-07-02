import XCTest
@testable import ClipboardToReadwiseCore

final class ClipboardParserTests: XCTestCase {
    func testWhitespaceClipboardProducesEmptyResult() {
        let parsed = ClipboardParser.parse("  \n\t\n ")

        XCTAssertEqual(parsed.title, "")
        XCTAssertEqual(parsed.highlights, [])
    }

    func testSingleParagraphBecomesTitleAndHighlight() {
        let parsed = ClipboardParser.parse("A single copied paragraph.")

        XCTAssertEqual(parsed.title, "A single copied paragraph.")
        XCTAssertEqual(parsed.highlights, ["A single copied paragraph."])
    }

    func testBlankLinesSplitParagraphs() {
        let parsed = ClipboardParser.parse("Title\n\nFirst highlight\n\n\nSecond highlight")

        XCTAssertEqual(parsed.title, "Title")
        XCTAssertEqual(parsed.highlights, ["First highlight", "Second highlight"])
    }

    func testFormFeedSplitsParagraphs() {
        let parsed = ClipboardParser.parse("Title\u{000C}First highlight\u{000C}Second highlight")

        XCTAssertEqual(parsed.title, "Title")
        XCTAssertEqual(parsed.highlights, ["First highlight", "Second highlight"])
    }

    func testCRLFAndCRNormalizeToLF() {
        let parsed = ClipboardParser.parse("Title\r\n\r\nFirst\r\rSecond")

        XCTAssertEqual(parsed.title, "Title")
        XCTAssertEqual(parsed.highlights, ["First", "Second"])
    }

    func testTitleAndHighlightLimits() {
        let title = String(repeating: "T", count: ClipboardParser.maxTitleLength + 20)
        let highlight = String(repeating: "H", count: ClipboardParser.maxHighlightLength + 20)

        let parsed = ClipboardParser.parse("\(title)\n\n\(highlight)")

        XCTAssertEqual(parsed.title.count, ClipboardParser.maxTitleLength)
        XCTAssertEqual(parsed.highlights.first?.count, ClipboardParser.maxHighlightLength)
    }
}
