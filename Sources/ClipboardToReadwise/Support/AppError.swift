import Foundation

enum AppError: LocalizedError {
    case alreadySending
    case emptyClipboard
    case missingToken
    case invalidToken
    case rateLimited
    case offline
    case unexpectedStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .alreadySending:
            "Already sending your clipboard. Wait a moment."
        case .emptyClipboard:
            "Clipboard is empty. Copy some text first."
        case .missingToken:
            "No Readwise API token. Add your token in Settings."
        case .invalidToken:
            "Readwise rejected your API token. Check it in Settings."
        case .rateLimited:
            "Readwise rate limit reached. Try again in a moment."
        case .offline:
            "Couldn't reach Readwise. Check your internet connection."
        case let .unexpectedStatus(status, body):
            "Readwise returned \(status). \(body.prefix(200))".trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

enum ErrorPresenter {
    static func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}
