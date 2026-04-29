import Foundation

enum LaunchListState {
    case initialLoading
    case content([LaunchCellViewModel])
    case paginating([LaunchCellViewModel])
    case empty
    case error(String)
}

final class LaunchListViewModel {
    private let launchRepository: LaunchRepositoryProtocol
    private let dateFormatter: DateFormatting
    private(set) var state: LaunchListState = .initialLoading
    private var currentPage: Int = 1
    
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
        
        Task {
            do {
                let result = try await launchRepository.fetchInitialLaunches(for: rocketId)
                let viewModels = mapToViewModels(result.launches)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
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
                    let errorState = LaunchListState.error("ОКАК! Что-то пошло не так, проверьте соединение")
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
        guard case .content(let currentViewModels) = state else { return }
        
        let threshold = totalItems - 5
        guard currentIndex >= threshold else { return }
        
        state = .paginating(currentViewModels)
        currentPage += 1
        
        Task {
            do {
                let result = try await launchRepository.fetchNextLaunchPage(for: rocketId, page: currentPage)
                let newViewModels = mapToViewModels(result.launches)
                let allViewModels = currentViewModels + newViewModels
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.state = .content(allViewModels)
                    completion(.content(allViewModels))
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.state = .content(currentViewModels)
                    completion(.content(currentViewModels))
                }
            }
        }
    }
    
    private func mapToViewModels(_ launches: [Launch]) -> [LaunchCellViewModel] {
        return launches.map { launch in
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
