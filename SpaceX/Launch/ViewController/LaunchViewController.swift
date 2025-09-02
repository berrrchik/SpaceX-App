import UIKit

class LaunchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let rocketId: String
    private let rocketName: String
    private let launchViewModel: LaunchViewModel
    private let launchView = LaunchView()
    private var launches: [LaunchElement] = []
    private var errorMessage: String?
    weak var coordinator: AppCoordinator?
    
    init(rocketId: String, rocketName: String, launchViewModel: LaunchViewModel = LaunchViewModel()) {
        self.rocketId = rocketId
        self.rocketName = rocketName
        self.launchViewModel = launchViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupTableView()
        setupBackButtonHandler()
        loadLaunchesData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
    }
        
    private func setupViewController() {
        view = launchView
        launchView.backgroundColor = AppColors.black
        
        let backButton = UIBarButtonItem()
        backButton.title = "Назад"
        navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        navigationItem.title = rocketName
        navigationController?.navigationBar.barTintColor = AppColors.black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: AppColors.white]
    }
    
    private func setupTableView() {
        launchView.tableView.dataSource = self
        launchView.tableView.delegate = self
        launchView.tableView.register(LaunchCell.self, forCellReuseIdentifier: "LaunchCell")
    }
    
    private func setupBackButtonHandler() {
        launchView.onBackButtonTap = { [weak self] in
            self?.coordinator?.popViewController()
        }
    }
    
    private func loadLaunchesData() {
            self.launchViewModel.loadAllLaunches { [weak self] result in
                guard let self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.fetchFilteredLaunches()
                    case .failure:
                        self.showError("ОКАК! Что-то пошло не так, проверьте соединение")
                    }
                }
            }
        }
    
    private func fetchFilteredLaunches() {
        launchViewModel.fetchLaunches(rocketId: rocketId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                switch result {
                case .success(let launches):
                    if launches.isEmpty {
                        self.showError("Нет данных о запуске этой ракеты")
                    } else {
                        self.launches = launches
                        self.errorMessage = nil
                        self.launchView.tableView.reloadData()
                    }
                case .failure:
                    self.showError("ОКАК! Что-то пошло не так, проверьте соединение")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        launches = []
        launchView.tableView.reloadData()
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return errorMessage != nil ? 1 : launches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let errorMessage = errorMessage {
            return createErrorCell(with: errorMessage)
        } else {
            return createLaunchCell(for: indexPath)
        }
    }
    
    private func createErrorCell(with message: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = AppColors.clear
        cell.textLabel?.text = message
        cell.textLabel?.textColor = AppColors.textGray56
        cell.textLabel?.font = AppFonts.regular14
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .none
        return cell
    }
    
    private func createLaunchCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = launchView.tableView.dequeueReusableCell(withIdentifier: "LaunchCell", for: indexPath)
        guard let launchCell = cell as? LaunchCell else { return cell}
        let launch = launches[indexPath.row]
        launchCell.configure(with: launch)
        return launchCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return errorMessage != nil ? Constants.errorRowHeight : UITableView.automaticDimension
    }
}

private extension LaunchViewController {
    enum Constants {
        static let errorRowHeight: CGFloat = 100
    }
}
