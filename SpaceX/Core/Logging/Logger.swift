import Foundation
import OSLog

enum AppLogger {
    static func make(_ category: String) -> Logger {
        Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
            category: category
        )
    }
}
