import SwiftUI

struct SettingsView: View {
    private static let suiteName = "group.com.typlx.grammar-keyboard"

    @AppStorage("apiUrl", store: UserDefaults(suiteName: suiteName))
    private var apiUrl: String = ""

    @AppStorage("model", store: UserDefaults(suiteName: suiteName))
    private var model: String = ""

    @State private var token: String = ""
    @State private var showToken: Bool = false
    @State private var saveStatus: SaveStatus = .idle

    enum SaveStatus: Equatable {
        case idle
        case saved
        case error(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    headerView
                } header: {
                    Text("")
                }

                Section("API Configuration") {
                    TextField("API URL", text: $apiUrl)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Model", text: $model)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    HStack {
                        if showToken {
                            TextField("API Token", text: $token)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("API Token", text: $token)
                        }
                        Button {
                            showToken.toggle()
                        } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button("Save Token") {
                        saveToken()
                    }
                    .disabled(token.isEmpty)

                    switch saveStatus {
                    case .idle:
                        EmptyView()
                    case .saved:
                        Label("Token saved to Keychain", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .error(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                Section("Setup Instructions") {
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(number: 1, text: "Open Settings > General > Keyboard > Keyboards")
                        instructionRow(number: 2, text: "Tap \"Add New Keyboard...\"")
                        instructionRow(number: 3, text: "Select \"Typlx Grammar\"")
                        instructionRow(number: 4, text: "Tap the keyboard and enable \"Allow Full Access\"")
                        instructionRow(number: 5, text: "Configure your API URL, model, and token above")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Typlx")
        }
        .onAppear {
            loadToken()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "textformat.abc")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Typlx Grammar Keyboard")
                .font(.title2.bold())
            Text("Fix grammar and spelling with AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .fontWeight(.semibold)
                .frame(width: 20, alignment: .trailing)
            Text(text)
        }
    }

    // MARK: - Token Management

    private func loadToken() {
        if let stored = KeychainHelper.load(key: KeychainHelper.tokenKey) {
            token = stored
        }
    }

    private func saveToken() {
        let success = KeychainHelper.save(key: KeychainHelper.tokenKey, value: token)
        if success {
            saveStatus = .saved
        } else {
            saveStatus = .error("Failed to save token to Keychain")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if saveStatus == .saved {
                saveStatus = .idle
            }
        }
    }
}

#Preview {
    SettingsView()
}
