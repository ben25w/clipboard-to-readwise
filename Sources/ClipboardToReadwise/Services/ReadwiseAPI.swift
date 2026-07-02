import ClipboardToReadwiseCore
import Foundation

struct ReadwiseAPI {
    private let session: URLSession
    private let highlightsURL = URL(string: "https://readwise.io/api/v2/highlights/")!
    private let authURL = URL(string: "https://readwise.io/api/v2/auth/")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func sendHighlights(_ payload: ReadwiseHighlightsRequest, token: String) async throws {
        var request = URLRequest(url: highlightsURL)
        request.httpMethod = "POST"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        try await perform(request: request, acceptedStatuses: Set(200..<300))
    }

    func testConnection(token: String) async throws {
        var request = URLRequest(url: authURL)
        request.httpMethod = "GET"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        try await perform(request: request, acceptedStatuses: [204])
    }

    private func perform(request: URLRequest, acceptedStatuses: Set<Int>) async throws {
        let responseData: (Data, URLResponse)
        do {
            responseData = try await session.data(for: request)
        } catch {
            throw AppError.offline
        }

        guard let httpResponse = responseData.1 as? HTTPURLResponse else {
            throw AppError.offline
        }

        guard acceptedStatuses.contains(httpResponse.statusCode) else {
            let body = String(data: responseData.0, encoding: .utf8) ?? ""
            switch httpResponse.statusCode {
            case 401:
                throw AppError.invalidToken
            case 429:
                throw AppError.rateLimited
            default:
                throw AppError.unexpectedStatus(httpResponse.statusCode, body)
            }
        }
    }
}
