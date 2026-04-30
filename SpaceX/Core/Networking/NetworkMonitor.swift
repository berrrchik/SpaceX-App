import Foundation
import Combine
import Network

enum ConnectivityStatus: Equatable {
    case unknown
    case connected
    case disconnected
}

protocol NetworkMonitorProtocol {
    var connectivityPublisher: AnyPublisher<ConnectivityStatus, Never> { get }
    var connectionRestoredPublisher: AnyPublisher<Void, Never> { get }
    var connectivityStatus: ConnectivityStatus { get }
    func isConnected() -> Bool
}

final class NetworkMonitor: NetworkMonitorProtocol {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.spacex.networkMonitor")
    private let connectivitySubject = CurrentValueSubject<ConnectivityStatus, Never>(.unknown)
    private let connectionRestoredSubject = PassthroughSubject<Void, Never>()
    private var isMonitoring = false

    var connectivityPublisher: AnyPublisher<ConnectivityStatus, Never> {
        connectivitySubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var connectionRestoredPublisher: AnyPublisher<Void, Never> {
        connectionRestoredSubject.eraseToAnyPublisher()
    }

    var connectivityStatus: ConnectivityStatus {
        Self.makeConnectivityStatus(from: monitor.currentPath.status)
    }

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func isConnected() -> Bool {
        connectivityStatus == .connected
    }

    private func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let previousStatus = self.connectivitySubject.value
            let newStatus = Self.makeConnectivityStatus(from: path.status)
            self.connectivitySubject.send(newStatus)

            if previousStatus != .connected, newStatus == .connected {
                self.connectionRestoredSubject.send(())
            }
        }
        connectivitySubject.send(connectivityStatus)
        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }

    private static func makeConnectivityStatus(from status: NWPath.Status) -> ConnectivityStatus {
        switch status {
        case .satisfied:
            return .connected
        case .unsatisfied, .requiresConnection:
            return .disconnected
        @unknown default:
            return .unknown
        }
    }
}
