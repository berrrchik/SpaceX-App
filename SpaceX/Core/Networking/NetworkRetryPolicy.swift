import Foundation

struct NetworkRetryPolicy {
    let maxAttempts: Int
    let backoffDelays: [TimeInterval]

    /// 3 attempts with progressive back-off: 0.5 s → 1.5 s.
    /// Gives two retries after the first failure, with enough time between
    /// them for a fresh TCP/TLS handshake to succeed after a QUIC drop.
    static let `default` = NetworkRetryPolicy(
        maxAttempts: 3,
        backoffDelays: [0.5, 1.5]
    )

    func delay(forAttempt attempt: Int) -> TimeInterval {
        guard !backoffDelays.isEmpty else { return 0 }
        let index = min(max(attempt - 1, 0), backoffDelays.count - 1)
        return backoffDelays[index]
    }
}
