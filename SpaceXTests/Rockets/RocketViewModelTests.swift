import XCTest
@testable import SpaceX

final class RocketViewModelTests: XCTestCase {
    func testFetchRocketsStoresFetchedRockets() {
        let rockets = [
            Rocket(
                id: "rocket-1",
                name: "Falcon Test",
                country: "US",
                costPerLaunch: 1000,
                firstFlightDate: "24.03.2006",
                height: MeasureSize(meters: 10, feet: 32),
                diameter: MeasureSize(meters: 2, feet: 6),
                mass: MeasureWeight(kg: 100, lb: 220),
                firstStage: FirstStage(engines: 1, fuelAmountTons: 10, burnTimeSec: 100),
                secondStage: SecondStage(engines: 1, fuelAmountTons: 5, burnTimeSec: 50),
                payloadWeights: [MeasureWeight(kg: 10, lb: 22)],
                flickrImages: []
            )
        ]
        let viewModel = RocketViewModel(rocketRepository: MockRocketRepository(result: .success(rockets)))
        let expectation = expectation(description: "Rockets loaded")

        viewModel.fetchRockets { result in
            switch result {
            case .success:
                XCTAssertEqual(viewModel.numberOfRockets, 1)
                XCTAssertEqual(viewModel.rocket(at: 0)?.name, "Falcon Test")
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testFetchRocketsForwardsFailureAndKeepsStateEmpty() {
        let viewModel = RocketViewModel(rocketRepository: MockRocketRepository(result: .failure(TestRocketError.failed)))
        let expectation = expectation(description: "Rocket failure forwarded")

        viewModel.fetchRockets { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure:
                XCTAssertEqual(viewModel.numberOfRockets, 0)
                XCTAssertNil(viewModel.rocket(at: 0))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}

private final class MockRocketRepository: RocketRepositoryProtocol {
    let result: Result<[Rocket], Error>

    init(result: Result<[Rocket], Error>) {
        self.result = result
    }

    func fetchRockets() async throws -> [Rocket] {
        return try result.get()
    }
}

private enum TestRocketError: Error {
    case failed
}
