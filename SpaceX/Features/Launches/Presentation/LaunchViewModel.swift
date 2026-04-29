import Foundation

class LaunchViewModel {
    private static let logger = AppLogger.make("LaunchViewModel")

    private let launchRepository: LaunchRepositoryProtocol
    private var statesByRocketId: [String: LaunchPaginationState] = [:]
    
    init(launchRepository: LaunchRepositoryProtocol) {
        self.launchRepository = launchRepository
    }
    
    func numberOfLaunches(for rocketId: String) -> Int {
        state(for: rocketId).launches.count
    }
    
    func launch(at index: Int, for rocketId: String) -> Launch? {
        let sortedLaunches = state(for: rocketId).launches
        
        guard index < sortedLaunches.count else { return nil }
        return sortedLaunches[index]
    }
    
    func fetchInitialLaunches(
        rocketId: String,
        completion: @escaping (Result<[Launch], Error>) -> Void
    ) {
        let state = state(for: rocketId)
        Self.logger.debug("Fetching initial launches for rocket id=\(rocketId, privacy: .public). cachedCount=\(state.launches.count, privacy: .public) hasNext=\(state.hasNextPage, privacy: .public)")

        if !state.launches.isEmpty {
            completion(.success(state.launches))
            return
        }

        fetchPage(for: rocketId, page: 1, reset: true, completion: completion)
    }

    func loadNextPageIfNeeded(
        rocketId: String,
        currentIndex: Int,
        completion: @escaping (Result<[Launch], Error>) -> Void
    ) {
        let state = state(for: rocketId)
        let thresholdIndex = max(state.launches.count - 5, 0)

        guard currentIndex >= thresholdIndex else { return }
        guard state.hasNextPage, let nextPage = state.nextPage else { return }
        guard !state.isLoadingPage else { return }

        Self.logger.debug("Loading next launches page for rocket id=\(rocketId, privacy: .public) currentIndex=\(currentIndex, privacy: .public) nextPage=\(nextPage, privacy: .public)")
        fetchPage(for: rocketId, page: nextPage, reset: false, completion: completion)
    }

    func hasLoadedLaunches(for rocketId: String) -> Bool {
        !state(for: rocketId).launches.isEmpty
    }

    func isLoadingPage(for rocketId: String) -> Bool {
        state(for: rocketId).isLoadingPage
    }

    func hasNextPage(for rocketId: String) -> Bool {
        state(for: rocketId).hasNextPage
    }

    private func fetchPage(
        for rocketId: String,
        page: Int,
        reset: Bool,
        completion: @escaping (Result<[Launch], Error>) -> Void
    ) {
        var launchState = state(for: rocketId)
        launchState.isLoadingPage = true
        statesByRocketId[rocketId] = launchState

        Self.logger.debug("Starting launch page fetch for rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) reset=\(reset, privacy: .public)")

        Task {
            do {
                let pageResult: LaunchPageResult
                if page == 1 {
                    pageResult = try await launchRepository.fetchInitialLaunches(for: rocketId)
                } else {
                    pageResult = try await launchRepository.fetchNextLaunchPage(for: rocketId, page: page)
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    var updatedState = self.state(for: rocketId)
                    updatedState.isLoadingPage = false
                    
                    let mergedLaunches = reset ? pageResult.launches : (updatedState.launches + pageResult.launches)
                    updatedState.launches = mergedLaunches.sorted { $0.dateUtc > $1.dateUtc }
                    updatedState.hasNextPage = pageResult.hasNextPage
                    updatedState.nextPage = pageResult.nextPage
                    self.statesByRocketId[rocketId] = updatedState
                    
                    Self.logger.debug(
                        "Launch page fetch succeeded for rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) totalLaunches=\(updatedState.launches.count, privacy: .public) hasNext=\(updatedState.hasNextPage, privacy: .public) nextPage=\(String(describing: updatedState.nextPage), privacy: .public)"
                    )
                    completion(.success(updatedState.launches))
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    var updatedState = self.state(for: rocketId)
                    updatedState.isLoadingPage = false
                    self.statesByRocketId[rocketId] = updatedState
                    
                    Self.logger.error("Launch page fetch failed for rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func state(for rocketId: String) -> LaunchPaginationState {
        statesByRocketId[rocketId] ?? LaunchPaginationState()
    }
}

private struct LaunchPaginationState {
    var launches: [Launch] = []
    var nextPage: Int? = 1
    var hasNextPage = true
    var isLoadingPage = false
}
