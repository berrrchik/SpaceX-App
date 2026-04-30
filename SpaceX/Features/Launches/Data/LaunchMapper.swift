import Foundation

struct LaunchMapper {
    private let logger = AppLogger.make("LaunchMapper")

    func map(_ dto: LaunchDTO) -> Launch? {
        guard let id = dto.id else {
            logger.debug("Skipping launch with missing id")
            return nil
        }

        return Launch(
            id: id,
            name: dto.name,
            dateUtc: dto.dateUtc,
            formattedDate: dto.dateUtc.formatDate() ?? "-",
            success: dto.success,
            rocketId: dto.rocket,
            launchpadId: dto.launchpad,
            upcoming: dto.upcoming ?? false,
            details: dto.details,
            links: dto.links.map(mapLinks),
            cores: mapCores(dto.cores),
            payloadIds: dto.payloads ?? [],
            crew: mapCrew(dto.crew),
            shipIds: dto.ships ?? [],
            capsuleIds: dto.capsules ?? []
        )
    }
    
    func map(_ dtos: [LaunchDTO]) -> [Launch] {
        dtos.compactMap { map($0) }
    }
    
    func map(_ pageDTO: LaunchPageDTO) -> LaunchPageResult {
        LaunchPageResult(
            launches: map(pageDTO.docs),
            hasNextPage: pageDTO.hasNextPage,
            nextPage: pageDTO.nextPage
        )
    }

    private func mapLinks(_ dto: LaunchLinksDTO) -> LaunchLinks {
        LaunchLinks(
            wikipedia: dto.wikipedia.flatMap(URL.init(string:)),
            article: dto.article.flatMap(URL.init(string:)),
            webcast: dto.webcast.flatMap(URL.init(string:))
        )
    }

    private func mapCores(_ dtos: [CoreDTO]?) -> [Core] {
        guard let dtos else { return [] }
        return dtos.compactMap { dto in
            guard let coreId = dto.core else { return nil }
            return Core(
                coreId: coreId,
                reused: dto.reused ?? false,
                landingSuccess: dto.landingSuccess
            )
        }
    }

    private func mapCrew(_ dtos: [CrewMemberDTO]?) -> [CrewMember] {
        guard let dtos else { return [] }
        return dtos.compactMap { dto in
            guard let crewId = dto.crew else { return nil }
            return CrewMember(crewId: crewId, role: dto.role)
        }
    }
}
