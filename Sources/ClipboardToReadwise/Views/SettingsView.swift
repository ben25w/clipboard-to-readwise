import ClipboardToReadwiseCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
    let readwiseAPI: ReadwiseAPI

    @State private var tokenDraft = ""
    @State private var testState: TestConnectionState = .idle

    var body: some View {
        Form {
            Section("Readwise") {
                SecureField(tokenPlaceholder, text: $tokenDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveToken)

                HStack {
                    Button("Save Token", action: saveToken)
                        .disabled(tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Test Connection", action: testConnection)
                        .disabled(testState == .testing || (!preferences.hasToken && tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))

                    Button("Clear Token", role: .destructive, action: clearToken)
                        .disabled(!preferences.hasToken)
                }

                Text(testState.message)
                    .foregroundStyle(testState.color)
                    .font(.caption)
            }

            Section("Document Defaults") {
                TextField("Author", text: $preferences.author)
                    .textFieldStyle(.roundedBorder)

                Picker("Category", selection: $preferences.category) {
                    ForEach(ReadwiseCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Privacy") {
                Text("The API token is stored in Keychain. Clipboard text is only read when you choose Send Clipboard to Readwise.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(minWidth: 480, minHeight: 320)
    }

    private var tokenPlaceholder: String {
        preferences.hasToken ? "Token saved. Paste a new token to replace it." : "Paste your Readwise API token"
    }

    private func saveToken() {
        do {
            try preferences.saveToken(tokenDraft)
            tokenDraft = ""
            testState = .success("Token saved.")
        } catch {
            testState = .failure(ErrorPresenter.message(for: error))
        }
    }

    private func clearToken() {
        do {
            try preferences.clearToken()
            tokenDraft = ""
            testState = .success("Token cleared.")
        } catch {
            testState = .failure(ErrorPresenter.message(for: error))
        }
    }

    private func testConnection() {
        testState = .testing
        let tokenOverride = tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let token = tokenOverride.isEmpty ? preferences.tokenForRequest() : tokenOverride
                guard let token, !token.isEmpty else {
                    throw AppError.missingToken
                }

                try await readwiseAPI.testConnection(token: token)
                testState = .success("Readwise accepted the token.")
            } catch {
                testState = .failure(ErrorPresenter.message(for: error))
            }
        }
    }
}

private enum TestConnectionState: Equatable {
    case idle
    case testing
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .idle:
            "Use Test Connection to verify a saved token or the token currently typed above."
        case .testing:
            "Testing Readwise connection..."
        case let .success(message):
            message
        case let .failure(message):
            message
        }
    }

    var color: Color {
        switch self {
        case .success:
            .green
        case .failure:
            .red
        case .idle, .testing:
            .secondary
        }
    }
}
