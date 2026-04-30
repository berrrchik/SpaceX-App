import Foundation

struct LaunchLinks: Codable {
    let patchSmall: URL?
    let patchLarge: URL?
    let wikipedia: URL?
    let article: URL?
    let webcast: URL?

    init(
        patchSmall: URL? = nil,
        patchLarge: URL? = nil,
        wikipedia: URL? = nil,
        article: URL? = nil,
        webcast: URL? = nil
    ) {
        self.patchSmall = patchSmall
        self.patchLarge = patchLarge
        self.wikipedia = wikipedia
        self.article = article
        self.webcast = webcast
    }
}
