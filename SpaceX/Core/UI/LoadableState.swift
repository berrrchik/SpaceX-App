import Foundation

enum LoadableState<Value> {
    case idle
    case loading
    case loaded(Value, isStale: Bool)
    case empty(message: String)
    case failed(message: String, cachedValue: Value?)
}

extension LoadableState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: Value? {
        switch self {
        case .loaded(let value, _):
            return value
        case .failed(_, let cachedValue):
            return cachedValue
        default:
            return nil
        }
    }
}
