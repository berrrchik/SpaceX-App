import XCTest
@testable import SpaceX

final class LaunchCacheStoreTests: XCTestCase {
    private static let suiteName = "com.test.launchCacheStore"

    private var testDefaults: UserDefaults!
    private var sut: UserDefaultsLaunchCacheStore!

    override func setUp() {
        super.setUp()
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else {
            XCTFail("Failed to create test defaults suite")
            return
        }
        testDefaults = defaults
        sut = UserDefaultsLaunchCacheStore(defaults: defaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        sut = nil
        testDefaults = nil
        super.tearDown()
    }

    func test_save_thenLoad_returnsIdenticalLaunches() {
        let launches = [Self.makeLaunch(id: "l1"), Self.makeLaunch(id: "l2")]
        sut.save(launches, for: "rocketA")

        let loaded = sut.load(for: "rocketA")

        XCTAssertEqual(loaded?.map(\.id), ["l1", "l2"])
    }

    func test_load_missingKey_returnsNil() {
        XCTAssertNil(sut.load(for: "unknownRocket"))
    }

    func test_save_overwritesExistingEntry() {
        sut.save([Self.makeLaunch(id: "old")], for: "rocketA")
        sut.save([Self.makeLaunch(id: "new1"), Self.makeLaunch(id: "new2")], for: "rocketA")

        let loaded = sut.load(for: "rocketA")

        XCTAssertEqual(loaded?.map(\.id), ["new1", "new2"])
    }

    func test_clear_removesEntry_returnsNil() {
        sut.save([Self.makeLaunch(id: "x")], for: "rocketA")
        sut.clear(for: "rocketA")

        XCTAssertNil(sut.load(for: "rocketA"))
    }

    func test_cacheKey_scopedByRocketId_isolatesEntries() {
        sut.save([Self.makeLaunch(id: "a")], for: "rocketA")
        sut.save([Self.makeLaunch(id: "b")], for: "rocketB")

        XCTAssertEqual(sut.load(for: "rocketA")?.first?.id, "a")
        XCTAssertEqual(sut.load(for: "rocketB")?.first?.id, "b")
    }

    func test_load_corruptData_returnsNil_doesNotCrash() {
        testDefaults.set("broken-json".data(using: .utf8), forKey: "launches_v4_corruptRocket")

        XCTAssertNil(sut.load(for: "corruptRocket"))
    }

    func test_load_ignoresLegacyCacheEntries() {
        let legacyLaunches = [Self.makeLaunch(id: "legacy")]
        let encoder = JSONEncoder()
        let legacyData = try? encoder.encode(legacyLaunches)
        testDefaults.set(legacyData, forKey: "launches_rocketA")
        testDefaults.set(legacyData, forKey: "launches_v2_rocketA")
        testDefaults.set(legacyData, forKey: "launches_v3_rocketA")
        testDefaults.set(["rocketA"], forKey: "launchCache_knownRocketIds")
        testDefaults.set(["rocketA"], forKey: "launchCache_v2_knownRocketIds")
        testDefaults.set(["rocketA"], forKey: "launchCache_v3_knownRocketIds")

        XCTAssertNil(sut.load(for: "rocketA"))
        XCTAssertFalse(sut.allKnownRocketIds().contains("rocketA"))
    }

    func test_allKnownRocketIds_tracksInsertedRocketIds() {
        sut.save([Self.makeLaunch(id: "a")], for: "rocketA")
        sut.save([Self.makeLaunch(id: "b")], for: "rocketB")

        let ids = Set(sut.allKnownRocketIds())
        XCTAssertEqual(ids, Set(["rocketA", "rocketB"]))
    }

    func test_clear_removesRocketIdFromKnownIds() {
        sut.save([Self.makeLaunch(id: "a")], for: "rocketA")
        sut.clear(for: "rocketA")

        XCTAssertFalse(sut.allKnownRocketIds().contains("rocketA"))
    }
}

private extension LaunchCacheStoreTests {
    static func makeLaunch(id: String) -> Launch {
        Launch(
            id: id,
            name: "Mission \(id)",
            dateUtc: "2024-01-01T00:00:00.000Z",
            formattedDate: "01.01.2024",
            success: true,
            rocketId: "rocket-id"
        )
    }
}
