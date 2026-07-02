import ClipboardToReadwiseCore
import Combine
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published private(set) var hasToken: Bool
    @Published var author: String {
        didSet {
            defaults.set(author, forKey: Keys.author)
        }
    }
    @Published var category: ReadwiseCategory {
        didSet {
            defaults.set(category.rawValue, forKey: Keys.category)
        }
    }

    private let defaults: UserDefaults
    private let tokenStore: KeychainTokenStore

    init(defaults: UserDefaults = .standard, tokenStore: KeychainTokenStore) {
        self.defaults = defaults
        self.tokenStore = tokenStore
        self.hasToken = tokenStore.hasToken()
        self.author = defaults.string(forKey: Keys.author) ?? ""
        self.category = ReadwiseCategory(rawValue: defaults.string(forKey: Keys.category) ?? "") ?? .articles
    }

    func saveToken(_ token: String) throws {
        try tokenStore.saveToken(token)
        hasToken = tokenStore.hasToken()
    }

    func clearToken() throws {
        try tokenStore.clearToken()
        hasToken = false
    }

    func tokenForRequest() -> String? {
        tokenStore.readToken()
    }
}

private enum Keys {
    static let author = "readwise.author"
    static let category = "readwise.category"
}
