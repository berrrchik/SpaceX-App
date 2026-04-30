import Foundation

final class LaunchListViewModel {
    private static let logger = AppLogger.make("LaunchListViewModel")

    private let launchRepository: LaunchRepositoryProtocol
    private let dateFormatter: DateFormatting
    private(set) var state: LoadableState<[LaunchCellViewModel]> = .idle

    // Pagination state
    private var currentPage: Int = 1
    private var loadedAll: Bool = false
    private var seenLaunchIDs: Set<String> = []

    init(
        launchRepository: LaunchRepositoryProtocol,
        dateFormatter: DateFormatting = DefaultDateFormatter()
    ) {
        self.launchRepository = launchRepository
        self.dateFormatter = dateFormatter
    }

    func loadInitialLaunches(for rocketId: String, completion: @escaping (LoadableState<[LaunchCellViewModel]>) -> Void) {
        state = .loading
        completion(state)
        currentPage = 1
        loadedAll = false
        seenLaunchIDs = []
        Self.logger.debug("Loading initial launches page. rocket=\(rocketId, privacy: .public) offset=0 limit=20")

        Task {
            do {
                let result = try await launchRepository.fetchInitialLaunches(for: rocketId)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let newLaunches = result.launches.filter { self.seenLaunchIDs.insert($0.id).inserted }
                    let viewModels = self.mapToViewModels(newLaunches)
                    self.loadedAll = !result.hasNextPage || newLaunches.isEmpty
                    Self.logger.debug(
                        "Initial launches loaded. rocket=\(rocketId, privacy: .public) received=\(result.launches.count, privacy: .public) appended=\(newLaunches.count, privacy: .public) hasNextPage=\(result.hasNextPage, privacy: .public) loadedAll=\(self.loadedAll, privacy: .public)"
                    )
                    if viewModels.isEmpty {
                        self.state = .empty(message: L10n.launchesNoData)
                        completion(self.state)
                    } else {
                        self.state = .loaded(viewModels, isStale: result.isStale)
                        completion(self.state)
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    Self.logger.error(
                        "Initial launches failed. rocket=\(rocketId, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                    )
                    let cached = self.launchRepository.fetchAllCachedLaunches(for: rocketId)
                    let cachedVMs = cached.isEmpty ? nil : self.mapToViewModels(cached)
                    self.state = .failed(message: L10n.launchesNetworkError, cachedValue: cachedVMs)
                    completion(self.state)
                }
            }
        }
    }

    func loadNextPageIfNeeded(
        for rocketId: String,
        currentIndex: Int,
        totalItems: Int,
        completion: @escaping (LoadableState<[LaunchCellViewModel]>) -> Void
    ) {
        // Stop if pagination has finished
        guard !loadedAll else { return }
        guard case .loaded(let currentViewModels, _) = state else { return }

        let threshold = max(0, totalItems - 5)
        guard currentIndex >= threshold else { return }

        state = .loading
        completion(state)
        currentPage += 1
        let pageToFetch = currentPage
        Self.logger.debug(
            "Loading next launches page. rocket=\(rocketId, privacy: .public) page=\(pageToFetch, privacy: .public)"
        )

        Task {
            do {
                let result = try await launchRepository.fetchNextLaunchPage(for: rocketId, page: pageToFetch)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let newLaunches = result.launches.filter { self.seenLaunchIDs.insert($0.id).inserted }
                    let newViewModels = self.mapToViewModels(newLaunches)
                    let allViewModels = currentViewModels + newViewModels
                    self.loadedAll = !result.hasNextPage || newLaunches.isEmpty
                    Self.logger.debug(
                        "Next page loaded. rocket=\(rocketId, privacy: .public) page=\(pageToFetch, privacy: .public) received=\(result.launches.count, privacy: .public) appended=\(newLaunches.count, privacy: .public) nextOffset=\(pageToFetch * 20, privacy: .public) hasNextPage=\(result.hasNextPage, privacy: .public) loadedAll=\(self.loadedAll, privacy: .public)"
                    )
                    self.state = .loaded(allViewModels, isStale: result.isStale)
                    completion(self.state)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    // Roll back page counter so the same page is retried on next scroll
                    self.currentPage -= 1
                    Self.logger.error(
                        "Next page failed. rocket=\(rocketId, privacy: .public) page=\(pageToFetch, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                    )
                    self.state = .failed(message: L10n.launchesNetworkError, cachedValue: currentViewModels)
                    completion(self.state)
                }
            }
        }
    }

    private func mapToViewModels(_ launches: [Launch]) -> [LaunchCellViewModel] {
        launches.map { launch in
            let statusImageName: String
            if let success = launch.success {
                statusImageName = success ? "LaunchSuccess" : "LaunchFail"
            } else {
                statusImageName = "unknown"
            }
            return LaunchCellViewModel(
                id: launch.id,
                name: launch.name,
                date: launch.formattedDate,
                statusImageName: statusImageName
            )
        }
    }
}
