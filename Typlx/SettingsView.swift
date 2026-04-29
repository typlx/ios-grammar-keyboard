import SwiftUI

struct SettingsView: View {
    @State private var apiURL: String = ""
    @State private var model: String = ""
    @State private var apiToken: String = ""
    @State private var showSavedAlert = false

    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                TextField("API URL (e.g. https://api.openai.com/v1)", text: $apiURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                TextField("Model (e.g. gpt-4o)", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("API Token", text: $apiToken)
            }

            Section {
                Button("Save Settings") {
                    saveSettings()
                }
            }

            Section(header: Text("Setup Instructions")) {
                Label("Enter your OpenAI-compatible API URL", systemImage: "1.circle")
                Label("Enter the model name", systemImage: "2.circle")
                Label("Enter your API token", systemImage: "3.circle")
                Label("Go to Settings → General → Keyboard → Keyboards → Add New Keyboard → Typlx", systemImage: "4.circle")
                Label("Enable Full Access for grammar fixing", systemImage: "5.circle")
            }
            .foregroundColor(.secondary)
        }
        .navigationTitle("Typlx")
        .onAppear(perform: loadSettings)
        .alert("Settings Saved", isPresented: $showSavedAlert) {
            Button("OK") {}
        }
    }

    private func loadSettings() {
        apiURL = SharedSettings.shared.apiURL
        model = SharedSettings.shared.model
        apiToken = SharedSettings.shared.apiToken
    }

    private func saveSettings() {
        SharedSettings.shared.apiURL = apiURL
        SharedSettings.shared.model = model
        SharedSettings.shared.apiToken = apiToken
        showSavedAlert = true
    }
}
