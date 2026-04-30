import Foundation

struct LaunchPageResult {
    let launches: [Launch]
    let hasNextPage: Bool
    let nextPage: Int?
    let isStale: Bool

    init(
        launches: [Launch],
        hasNextPage: Bool,
        nextPage: Int?,
        isStale: Bool = false
    ) {
        self.launches = launches
        self.hasNextPage = hasNextPage
        self.nextPage = nextPage
        self.isStale = isStale
    }
}
