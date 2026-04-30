import Foundation

final class LaunchListViewModel {
    private static let logger = AppLogger.make("LaunchListViewModel")

    private let launchRepository: LaunchRepositoryProtocol
    private let dateFormatter: DateFormatting
    private(set) var state: LoadableState<[LaunchCellViewModel]> = .idle
    private(set) var currentQuery = LaunchQuery()
    private var cachedLaunches: [Launch] = []
    private var currentRocketId: String?

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
        currentRocketId = rocketId
        currentQuery = LaunchQuery()
        state = .loading
        completion(state)
        currentPage = 1
        loadedAll = false
        seenLaunchIDs = []
        cachedLaunches = []
        Self.logger.debug("Loading initial launches page. rocket=\(rocketId, privacy: .public) offset=0 limit=20")

        Task {
            do {
                let result = try await launchRepository.fetchInitialLaunches(for: rocketId)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let newLaunches = result.launches.filter { self.seenLaunchIDs.insert($0.id).inserted }
                    self.cachedLaunches = newLaunches
                    self.loadedAll = !result.hasNextPage || newLaunches.isEmpty
                    Self.logger.debug(
                        "Initial launches loaded. rocket=\(rocketId, privacy: .public) received=\(result.launches.count, privacy: .public) appended=\(newLaunches.count, privacy: .public) hasNextPage=\(result.hasNextPage, privacy: .public) loadedAll=\(self.loadedAll, privacy: .public)"
                    )
                    self.publishFilteredState(isStale: result.isStale, completion: completion)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    Self.logger.error(
                        "Initial launches failed. rocket=\(rocketId, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                    )
                    let cached = self.launchRepository.fetchAllCachedLaunches(for: rocketId)
                    self.cachedLaunches = cached
                    let filtered = self.filteredLaunches(for: self.currentQuery)
                    let cachedVMs = filtered.isEmpty ? nil : self.mapToViewModels(filtered)
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
        guard currentQuery.searchText.isEmpty, currentQuery.statusFilter == .all, currentQuery.year == nil else { return }

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
                    self.cachedLaunches += newLaunches
                    let allViewModels = self.mapToViewModels(self.cachedLaunches)
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

    func applyQuery(_ query: LaunchQuery, completion: @escaping (LoadableState<[LaunchCellViewModel]>) -> Void) {
        currentQuery = query
        Self.logger.debug(
            "applyQuery: status=\(query.statusFilter.rawValue, privacy: .public) year=\(String(describing: query.year), privacy: .public) search='\(query.searchText, privacy: .public)' sort=\(query.sortOrder.rawValue, privacy: .public)"
        )
        publishFilteredState(isStale: stateIsStale, completion: completion)
    }

    func filterItems() -> [LaunchFilterItem] {
        let status: [LaunchFilterItem] = [
            LaunchFilterItem(id: "status_all", title: L10n.launchesFilterAll, isSelected: currentQuery.statusFilter == .all),
            LaunchFilterItem(id: "status_successful", title: L10n.launchesFilterSuccessful, isSelected: currentQuery.statusFilter == .successful),
            LaunchFilterItem(id: "status_failed", title: L10n.launchesFilterFailed, isSelected: currentQuery.statusFilter == .failed),
            LaunchFilterItem(id: "status_upcoming", title: L10n.launchesFilterUpcoming, isSelected: currentQuery.statusFilter == .upcoming)
        ]
        let years = Set(cachedLaunches.compactMap { Int($0.dateUtc.prefix(4)) }).sorted(by: >)
        let yearItems = years.map { year in
            LaunchFilterItem(id: "year_\(year)", title: String(year), isSelected: currentQuery.year == year)
        }
        let sortItems: [LaunchFilterItem] = [
            LaunchFilterItem(id: "sort_newest", title: L10n.launchesSortNewest, isSelected: currentQuery.sortOrder == .newestFirst),
            LaunchFilterItem(id: "sort_oldest", title: L10n.launchesSortOldest, isSelected: currentQuery.sortOrder == .oldestFirst)
        ]
        return status + yearItems + sortItems
    }

    func availableYears() -> [Int] {
        Set(cachedLaunches.compactMap { Int($0.dateUtc.prefix(4)) }).sorted(by: >)
    }

    private func publishFilteredState(
        isStale: Bool,
        completion: @escaping (LoadableState<[LaunchCellViewModel]>) -> Void
    ) {
        let filtered = filteredLaunches(for: currentQuery)
        Self.logger.debug("Filter result: \(filtered.count, privacy: .public) of \(self.cachedLaunches.count, privacy: .public)")
        if filtered.isEmpty {
            state = .empty(message: cachedLaunches.isEmpty ? L10n.launchesNoData : L10n.launchesNoMatches)
        } else {
            state = .loaded(mapToViewModels(filtered), isStale: isStale)
        }
        completion(state)
    }

    private var stateIsStale: Bool {
        if case .loaded(_, let isStale) = state {
            return isStale
        }
        return false
    }

    private func filteredLaunches(for query: LaunchQuery) -> [Launch] {
        var filtered = cachedLaunches

        switch query.statusFilter {
        case .all:
            break
        case .successful:
            filtered = filtered.filter { $0.success == true && !$0.upcoming }
        case .failed:
            filtered = filtered.filter { $0.success == false && !$0.upcoming }
        case .upcoming:
            filtered = filtered.filter { $0.upcoming }
        }

        if let year = query.year {
            filtered = filtered.filter { Int($0.dateUtc.prefix(4)) == year }
        }

        if !query.searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query.searchText) }
        }

        filtered.sort { lhs, rhs in
            query.sortOrder == .newestFirst ? lhs.dateUtc > rhs.dateUtc : lhs.dateUtc < rhs.dateUtc
        }

        return filtered
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
