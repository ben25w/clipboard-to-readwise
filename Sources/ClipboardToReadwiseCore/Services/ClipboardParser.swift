import Foundation

public enum ClipboardParser {
    public static let maxTitleLength = 511
    public static let maxHighlightLength = 8191

    public static func parse(_ raw: String) -> ParsedClipboard {
        let normalized = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let separated = paragraphBoundary.stringByReplacingMatches(
            in: normalized,
            range: NSRange(normalized.startIndex..., in: normalized),
            withTemplate: delimiter
        )

        let paragraphs = separated
            .components(separatedBy: delimiter)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = paragraphs.first else {
            return ParsedClipboard(title: "", highlights: [])
        }

        let title = String(first.prefix(maxTitleLength))
        let highlightSource = paragraphs.count > 1 ? Array(paragraphs.dropFirst()) : [first]
        let highlights = highlightSource.map { String($0.prefix(maxHighlightLength)) }

        return ParsedClipboard(title: title, highlights: highlights)
    }

    private static let delimiter = "\u{001E}"
    private static let paragraphBoundary = try! NSRegularExpression(pattern: "\u{000C}|\n[ \t]*\n+")
}
