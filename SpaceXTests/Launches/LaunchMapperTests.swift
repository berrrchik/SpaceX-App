import XCTest
@testable import SpaceX

final class LaunchMapperTests: XCTestCase {
    private var sut: LaunchMapper!

    override func setUp() {
        super.setUp()
        sut = LaunchMapper()
    }

    func test_map_fullDTO_returnsCorrectDomainModel() {
        let dto = LaunchDTO.fixture(id: "abc123", name: "Falcon 9")

        let result = sut.map(dto)

        XCTAssertEqual(result?.id, "abc123")
        XCTAssertEqual(result?.name, "Falcon 9")
        XCTAssertEqual(result?.launchpadId, "launchpad-1")
        XCTAssertEqual(result?.crew.first?.crewId, "crew-1")
        XCTAssertEqual(result?.cores.first?.reused, true)
        XCTAssertEqual(result?.payloadIds, ["payload-1"])
    }

    func test_map_missingId_returnsNil() {
        let dto = LaunchDTO.fixture(id: nil)
        XCTAssertNil(sut.map(dto))
    }

    func test_map_nullOptionalFields_doesNotCrash() {
        let dto = LaunchDTO.fixture(
            id: "x",
            links: nil,
            cores: nil,
            crew: nil,
            ships: nil,
            capsules: nil
        )

        let result = sut.map(dto)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.links)
        XCTAssertTrue(result?.crew.isEmpty == true)
        XCTAssertTrue(result?.capsuleIds.isEmpty == true)
        XCTAssertTrue(result?.shipIds.isEmpty == true)
    }

    func test_map_pageDTO_propagatesHasNextPage() {
        let dto = LaunchPageDTO(
            docs: [LaunchDTO.fixture(id: "one"), LaunchDTO.fixture(id: nil)],
            hasNextPage: true,
            nextPage: 2
        )

        let result = sut.map(dto)

        XCTAssertEqual(result.launches.map(\.id), ["one"])
        XCTAssertTrue(result.hasNextPage)
        XCTAssertEqual(result.nextPage, 2)
    }
}

private extension LaunchDTO {
    static func fixture(
        id: String? = "test-id",
        name: String = "Test Launch",
        dateUtc: String = "2024-01-01T00:00:00.000Z",
        success: Bool? = true,
        rocket: String = "rocket-id",
        upcoming: Bool? = false,
        details: String? = "details",
        launchpad: String? = "launchpad-1",
        links: LaunchLinksDTO? = LaunchLinksDTO(
            wikipedia: "https://wikipedia.org/wiki/Falcon_9",
            article: "https://example.com/article",
            webcast: "https://youtube.com/watch?v=abc"
        ),
        cores: [CoreDTO]? = [CoreDTO(core: "core-1", reused: true, landingSuccess: true)],
        payloads: [String]? = ["payload-1"],
        crew: [CrewMemberDTO]? = [CrewMemberDTO(crew: "crew-1", role: "Commander")],
        ships: [String]? = ["ship-1"],
        capsules: [String]? = ["capsule-1"]
    ) -> LaunchDTO {
        LaunchDTO(
            id: id,
            name: name,
            dateUtc: dateUtc,
            success: success,
            rocket: rocket,
            upcoming: upcoming,
            details: details,
            launchpad: launchpad,
            links: links,
            cores: cores,
            payloads: payloads,
            crew: crew,
            ships: ships,
            capsules: capsules
        )
    }
}
