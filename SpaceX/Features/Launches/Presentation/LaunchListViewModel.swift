import Foundation

enum LaunchListState {
    case initialLoading
    case content([LaunchCellViewModel])
    case paginating([LaunchCellViewModel])
    case empty
    case error(String)
}

final class LaunchListViewModel {
    private static let logger = AppLogger.make("LaunchListViewModel")

    private let launchRepository: LaunchRepositoryProtocol
    private let dateFormatter: DateFormatting
    private(set) var state: LaunchListState = .initialLoading

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

    func loadInitialLaunches(for rocketId: String, completion: @escaping (LaunchListState) -> Void) {
        state = .initialLoading
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
                        self.state = .empty
                        completion(.empty)
                    } else {
                        self.state = .content(viewModels)
                        completion(.content(viewModels))
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    Self.logger.error(
                        "Initial launches failed. rocket=\(rocketId, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                    )
                    let errorState = LaunchListState.error(L10n.launchesNetworkError)
                    self.state = errorState
                    completion(errorState)
                }
            }
        }
    }

    func loadNextPageIfNeeded(
        for rocketId: String,
        currentIndex: Int,
        totalItems: Int,
        completion: @escaping (LaunchListState) -> Void
    ) {
        // Stop if pagination has finished
        guard !loadedAll else { return }
        // Only trigger from a stable content state; .paginating acts as the in-flight guard
        guard case .content(let currentViewModels) = state else { return }

        let threshold = max(0, totalItems - 5)
        guard currentIndex >= threshold else { return }

        state = .paginating(currentViewModels)
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
                    self.state = .content(allViewModels)
                    completion(.content(allViewModels))
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    // Roll back page counter so the same page is retried on next scroll
                    self.currentPage -= 1
                    Self.logger.error(
                        "Next page failed. rocket=\(rocketId, privacy: .public) page=\(pageToFetch, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                    )
                    self.state = .content(currentViewModels)
                    completion(.content(currentViewModels))
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
                name: launch.name,
                date: launch.formattedDate,
                statusImageName: statusImageName
            )
        }
    }
}
