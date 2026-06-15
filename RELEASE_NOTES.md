# Release Notes

## v1.0.0 (Build 1) — 2026-06-15

Initial App Store release.

### Features

- **AI grammar correction keyboard** — tap "Fix Grammar" in the keyboard toolbar to correct the current sentence using your chosen AI provider
- **OpenAI support** — GPT-4o mini (default), configurable to any OpenAI-compatible model and endpoint
- **Anthropic support** — Claude Haiku (default), configurable to any Anthropic model and endpoint
- **Local / self-hosted provider** — stub in place; full on-device support coming in v1.1
- **Context-aware prompts** — five writing contexts (General, Email, Chat, Essay, Code Comment) that adjust the AI's correction style
- **Two-tap workflow** — first tap fetches and previews the corrected text; second tap applies it, so you always stay in control
- **Secure key storage** — API keys stored in the iOS Keychain shared between the container app and keyboard extension; never written to UserDefaults or logs
- **Onboarding flow** — step-by-step instructions for enabling the keyboard and Full Access shown on first launch
- **Full Access gate** — keyboard displays a friendly message if Full Access is not enabled, rather than silently failing

### Technical

- iOS 15+ deployment target (iPhone and iPad)
- Swift 5, UIKit, no third-party dependencies
- App Group (`group.com.typist.keyboard`) for shared settings between container app and keyboard extension
- 15-second request timeout on all provider calls
- Graceful error messages for: no network, invalid API key, rate limit, server error, and empty text
