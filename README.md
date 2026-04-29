# Typlx Grammar Keyboard (iOS)

iOS custom keyboard extension with a grammar-fix button. Uses any OpenAI-compatible chat completions API to fix grammar and spelling in-place. Part of the [Typlx](https://typlx.com) open-source grammar-checking suite.

## Features

- Custom keyboard extension with a "Fix Grammar" button
- Sends selected text to a configurable LLM API for grammar and spelling correction
- Host app with settings screen to configure API URL, model, and token
- API token stored securely in the iOS Keychain
- Settings shared between the host app and keyboard extension via App Groups
- No external dependencies — pure URLSession networking

## Architecture

```
ios-grammar-keyboard/
├── Package.swift                         # Swift Package Manager manifest
├── GrammarKeyboard/
│   ├── Info.plist                         # Host app Info.plist
│   └── Sources/
│       ├── GrammarKeyboardApp.swift       # SwiftUI App entry point
│       ├── SettingsView.swift             # API configuration UI
│       ├── KeychainHelper.swift           # Keychain wrapper (shared via App Group)
│       └── GrammarService.swift           # LLM API client
└── KeyboardExtension/
    ├── Info.plist                         # Extension Info.plist (NSExtension config)
    └── KeyboardViewController.swift      # Custom keyboard UI + logic
```

### Components

| Component | Description |
|---|---|
| **GrammarKeyboardApp** | Host app entry point. Opens the settings screen. |
| **SettingsView** | SwiftUI form for API URL, model name, and API token. Stores URL/model in `@AppStorage` (App Group UserDefaults) and token in Keychain. |
| **KeychainHelper** | Thin wrapper around Security framework. Uses `kSecAttrAccessGroup` so the extension can read the token. |
| **GrammarService** | Stateless API client. Builds a chat completions request, sends it with a 30-second timeout, and parses `choices[0].message.content`. |
| **KeyboardViewController** | UIInputViewController subclass. Reads text from the document proxy, calls GrammarService, and replaces the text with the corrected version. |

## Setup

### Prerequisites

- Xcode 15+ (Swift 5.9+)
- iOS 16+ deployment target
- An Apple Developer account (required for keyboard extensions)

### Xcode Project Setup

Since this repo contains Swift source files but not a full `.xcodeproj`, you need to create the Xcode project:

1. Open Xcode and create a new iOS App project
   - Product Name: **GrammarKeyboard**
   - Bundle Identifier: `com.typlx.grammar-keyboard`
   - Interface: **SwiftUI**

2. Add a **Custom Keyboard Extension** target
   - Product Name: **KeyboardExtension**
   - Bundle Identifier: `com.typlx.grammar-keyboard.keyboard`

3. Configure App Groups
   - Select the **GrammarKeyboard** target > Signing & Capabilities > + App Groups
   - Add: `group.com.typlx.grammar-keyboard`
   - Do the same for the **KeyboardExtension** target

4. Copy the source files from this repo into the project:
   - `GrammarKeyboard/Sources/*` into the host app target
   - `KeyboardExtension/*` into the keyboard extension target
   - Replace the auto-generated `Info.plist` files with the ones from this repo

5. Ensure `GrammarService.swift` and `KeychainHelper.swift` are included in **both** targets (host app and keyboard extension)

### Device Setup

1. Build and run the app on your device
2. Go to **Settings > General > Keyboard > Keyboards > Add New Keyboard**
3. Select **Typlx Grammar**
4. Tap the keyboard entry and enable **Allow Full Access** (required for network access)
5. Open the Typlx app and configure your API URL, model, and token

## API Contract

The keyboard uses the OpenAI-compatible chat completions endpoint:

```
POST {apiUrl}/chat/completions
Authorization: Bearer {token}
Content-Type: application/json

{
  "model": "{model}",
  "messages": [
    {
      "role": "system",
      "content": "Fix grammar and spelling in the following text. Return only the corrected text, nothing else. Preserve the original language, tone, and formatting."
    },
    {
      "role": "user",
      "content": "{text to fix}"
    }
  ],
  "temperature": 0.3
}
```

Compatible with OpenAI, Anthropic (via proxy), Ollama, and any other provider that implements the chat completions API.

## License

See [LICENSE](LICENSE) for details.
