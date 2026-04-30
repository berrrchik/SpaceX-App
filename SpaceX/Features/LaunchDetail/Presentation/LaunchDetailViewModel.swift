import Foundation

final class LaunchDetailViewModel {
    private static let logger = AppLogger.make("LaunchDetailViewModel")

    private let launchId: String
    private let repository: LaunchDetailRepositoryProtocol

    private(set) var state: LoadableState<LaunchDetail> = .idle
    var onStateChange: ((LoadableState<LaunchDetail>) -> Void)?

    init(launchId: String, repository: LaunchDetailRepositoryProtocol) {
        self.launchId = launchId
        self.repository = repository
    }

    func load() {
        state = .loading
        onStateChange?(state)
        Self.logger.debug("Loading detail for launch \(self.launchId, privacy: .public)")

        Task {
            do {
                let detail = try await repository.fetchDetail(for: launchId)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.state = .loaded(detail, isStale: detail.isStale)
                    self.onStateChange?(self.state)
                    Self.logger.debug("Detail state -> loaded")
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.state = .failed(message: L10n.launchDetailLoadError, cachedValue: nil)
                    self.onStateChange?(self.state)
                    Self.logger.error("Detail state -> failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
}
