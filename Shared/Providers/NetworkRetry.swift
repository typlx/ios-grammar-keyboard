import Foundation

typealias HTTPSleeper = (TimeInterval) async throws -> Void

func defaultHTTPSleeper(_ seconds: TimeInterval) async throws {
    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
}

/// Executes a URLSession data task with automatic retry for transient HTTP errors.
///
/// Retry policy:
///   - 429 (rate limit): up to `maxRateLimitRetries` retries using Retry-After header or 1s/2s/4s backoff
///   - 408 (request timeout): exactly one retry after 1s
///   - URLErrors: mapped to GrammarProviderError immediately, no retry
func performHTTPWithRetry(
    maxRateLimitRetries: Int = 2,
    sleeper: HTTPSleeper,
    request: () async throws -> (Data, URLResponse)
) async throws -> (Data, HTTPURLResponse) {
    var rateLimitAttempts = 0
    var timeoutAttempts = 0

    while true {
        let data: Data
        let urlResponse: URLResponse
        do {
            (data, urlResponse) = try await request()
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                throw GrammarProviderError.networkUnavailable
            case .timedOut:
                throw GrammarProviderError.serverError(0, "Request timed out. Try again.")
            default:
                throw GrammarProviderError.networkUnavailable
            }
        }

        guard let http = urlResponse as? HTTPURLResponse else {
            throw GrammarProviderError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return (data, http)
        case 401:
            throw GrammarProviderError.unauthorized
        case 408:
            if timeoutAttempts < 1 {
                timeoutAttempts += 1
                try await sleeper(1.0)
                continue
            }
            throw GrammarProviderError.serverError(408, "Request timed out")
        case 429:
            if rateLimitAttempts < maxRateLimitRetries {
                let delay = retryAfterDelay(from: http, attempt: rateLimitAttempts)
                rateLimitAttempts += 1
                try await sleeper(delay)
                continue
            }
            throw GrammarProviderError.rateLimited
        default:
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw GrammarProviderError.serverError(http.statusCode, msg)
        }
    }
}

private func retryAfterDelay(from response: HTTPURLResponse, attempt: Int) -> TimeInterval {
    if let value = response.value(forHTTPHeaderField: "Retry-After"),
       let seconds = Double(value) {
        return seconds
    }
    let delays: [TimeInterval] = [1, 2, 4]
    return delays[min(attempt, delays.count - 1)]
}
