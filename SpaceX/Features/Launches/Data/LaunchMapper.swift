import Foundation

struct LaunchMapper {
    func map(_ dto: LaunchDTO) -> Launch {
        Launch(
            name: dto.name,
            dateUtc: dto.dateUtc,
            formattedDate: dto.dateUtc.formatDate() ?? "-",
            success: dto.success,
            rocketId: dto.rocket
        )
    }
    
    func map(_ dtos: [LaunchDTO]) -> [Launch] {
        dtos.map { map($0) }
    }
    
    func map(_ pageDTO: LaunchPageDTO) -> LaunchPageResult {
        LaunchPageResult(
            launches: map(pageDTO.docs),
            hasNextPage: pageDTO.hasNextPage,
            nextPage: pageDTO.nextPage
        )
    }
}
