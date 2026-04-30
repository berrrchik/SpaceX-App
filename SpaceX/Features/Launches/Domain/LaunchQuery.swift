import Foundation

struct LaunchQuery {
    var searchText: String = ""
    var statusFilter: LaunchStatusFilter = .all
    var year: Int?
    var sortOrder: LaunchSortOrder = .newestFirst
}
