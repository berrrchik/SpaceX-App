import Foundation

struct NetworkRetryPolicy {
    let maxAttempts: Int
    let backoffDelays: [TimeInterval]

    static let `default` = NetworkRetryPolicy(
        maxAttempts: 2,
        backoffDelays: [0.35]
    )

    func delay(forAttempt attempt: Int) -> TimeInterval {
        guard !backoffDelays.isEmpty else { return 0 }
        let index = min(max(attempt - 1, 0), backoffDelays.count - 1)
        return backoffDelays[index]
    }
}
