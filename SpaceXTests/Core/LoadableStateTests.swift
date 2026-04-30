import XCTest
@testable import SpaceX

final class LoadableStateTests: XCTestCase {
    func test_idle_valueIsNil() {
        let state: LoadableState<[String]> = .idle
        XCTAssertNil(state.value)
        XCTAssertFalse(state.isLoading)
    }

    func test_loaded_freshData_isStale_false() {
        let state: LoadableState<[String]> = .loaded(["a"], isStale: false)
        XCTAssertEqual(state.value, ["a"])
    }

    func test_loaded_staleData_isStale_true() {
        let state: LoadableState<[String]> = .loaded(["b"], isStale: true)
        if case .loaded(_, let isStale) = state {
            XCTAssertTrue(isStale)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func test_failed_withCachedValue_cachedValueAccessible() {
        let state: LoadableState<[String]> = .failed(message: "Error", cachedValue: ["cached"])
        XCTAssertEqual(state.value, ["cached"])
    }

    func test_failed_withNilCache_valueIsNil() {
        let state: LoadableState<[String]> = .failed(message: "Error", cachedValue: nil)
        XCTAssertNil(state.value)
    }
}
