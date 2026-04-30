import UIKit
import SnapKit
import Kingfisher

final class LaunchDetailView: UIView {
    let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingOverlayView = LoadingView()

    private let heroImageView = UIImageView()
    private let missionTitleLabel = UILabel()
    private let statusBadgeLabel = UILabel()
    private let cachedBadgeLabel = UILabel()

    private let timelineValueLabel = UILabel()
    private let descriptionValueLabel = UILabel()
    private let rocketValueLabel = UILabel()
    private let padValueLabel = UILabel()
    private let payloadValueLabel = UILabel()
    private let crewValueLabel = UILabel()
    private let shipsValueLabel = UILabel()
    private let capsulesValueLabel = UILabel()

    private let wikipediaButton = UIButton(type: .system)
    private let articleButton = UIButton(type: .system)
    private let webcastButton = UIButton(type: .system)

    var onOpenURL: ((URL) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(detail: LaunchDetail) {
        missionTitleLabel.text = detail.launch.name
        timelineValueLabel.text = detail.launch.formattedDate
        descriptionValueLabel.text = detail.launch.details
        descriptionValueLabel.superview?.isHidden = detail.launch.details?.isEmpty ?? true
        if let rocket = detail.rocket {
            if let type = rocket.type, !type.isEmpty {
                rocketValueLabel.text = "\(rocket.name) (\(type.capitalized))"
            } else {
                rocketValueLabel.text = rocket.name
            }
        } else {
            rocketValueLabel.text = detail.launch.rocketId
        }

        if let pad = detail.launchpad {
            let location = [pad.name, pad.locality, pad.region].compactMap { $0 }.joined(separator: ", ")
            padValueLabel.text = location
            padValueLabel.superview?.isHidden = false
        } else {
            padValueLabel.superview?.isHidden = true
        }

        payloadValueLabel.text = detail.payloads.isEmpty ? nil : detail.payloads.map(payloadDisplayText).joined(separator: "\n")
        payloadValueLabel.superview?.isHidden = detail.payloads.isEmpty
        crewValueLabel.text = detail.crewMembers.isEmpty ? nil : detail.crewMembers.map(crewDisplayText).joined(separator: "\n")
        crewValueLabel.superview?.isHidden = detail.crewMembers.isEmpty
        shipsValueLabel.text = detail.ships.isEmpty ? nil : detail.ships.map(shipDisplayText).joined(separator: "\n")
        shipsValueLabel.superview?.isHidden = detail.ships.isEmpty
        capsulesValueLabel.text = detail.capsules.isEmpty ? nil : detail.capsules.map(capsuleDisplayText).joined(separator: "\n")
        capsulesValueLabel.superview?.isHidden = detail.capsules.isEmpty

        if let patchURL = sanitizedURL(detail.launch.links?.patchLarge ?? detail.launch.links?.patchSmall) {
            heroImageView.kf.setImage(with: patchURL)
        } else {
            heroImageView.image = nil
        }

        statusBadgeLabel.text = statusText(success: detail.launch.success, upcoming: detail.launch.upcoming)
        cachedBadgeLabel.isHidden = !detail.isStale

        configureLinkButton(wikipediaButton, url: sanitizedURL(detail.launch.links?.wikipedia))
        configureLinkButton(articleButton, url: sanitizedURL(detail.launch.links?.article))
        configureLinkButton(webcastButton, url: sanitizedURL(detail.launch.links?.webcast))
    }

    private func setupView() {
        backgroundColor = AppColors.black
        addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView.snp.width).offset(-32)
        }

        let heroCard = makeCard()
        heroCard.addSubview(heroImageView)
        heroCard.addSubview(missionTitleLabel)
        heroCard.addSubview(statusBadgeLabel)
        heroCard.addSubview(cachedBadgeLabel)
        heroImageView.contentMode = .scaleAspectFit
        missionTitleLabel.font = AppFonts.bold18
        missionTitleLabel.textColor = AppColors.white
        statusBadgeLabel.font = AppFonts.bold14
        statusBadgeLabel.textColor = AppColors.white
        cachedBadgeLabel.font = AppFonts.bold14
        cachedBadgeLabel.textColor = AppColors.white
        cachedBadgeLabel.text = L10n.launchesCachedBadge
        cachedBadgeLabel.isHidden = true

        heroImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(120)
        }
        missionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(heroImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        statusBadgeLabel.snp.makeConstraints { make in
            make.top.equalTo(missionTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        cachedBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(statusBadgeLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        contentStack.addArrangedSubview(heroCard)
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailTimelineTitle, valueLabel: timelineValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailDescriptionTitle, valueLabel: descriptionValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailRocketTitle, valueLabel: rocketValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailPadTitle, valueLabel: padValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailPayloadTitle, valueLabel: payloadValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailCrewTitle, valueLabel: crewValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailShipsTitle, valueLabel: shipsValueLabel))
        contentStack.addArrangedSubview(makeSection(title: L10n.launchDetailCapsulesTitle, valueLabel: capsulesValueLabel))
        contentStack.addArrangedSubview(makeLinksSection())

        addSubview(loadingOverlayView)
        loadingOverlayView.isHidden = true
        loadingOverlayView.isUserInteractionEnabled = false
        loadingOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }
    }

    func showLoadingOverlay() {
        loadingOverlayView.isHidden = false
        loadingOverlayView.startRotationAnimation()
    }

    func hideLoadingOverlay() {
        loadingOverlayView.isHidden = true
        loadingOverlayView.stopRotationAnimation()
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = AppColors.cardGray
        view.layer.cornerRadius = 12
        return view
    }

    private func makeSection(title: String, valueLabel: UILabel) -> UIView {
        let card = makeCard()
        let titleLabel = UILabel()
        titleLabel.font = AppFonts.bold16
        titleLabel.textColor = AppColors.white
        titleLabel.text = title
        titleLabel.accessibilityTraits.insert(.header)

        valueLabel.font = AppFonts.regular14
        valueLabel.textColor = AppColors.labelGray79
        valueLabel.numberOfLines = 0

        card.addSubview(titleLabel)
        card.addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
        return card
    }

    private func makeLinksSection() -> UIView {
        let card = makeCard()
        let titleLabel = UILabel()
        titleLabel.font = AppFonts.bold16
        titleLabel.textColor = AppColors.white
        titleLabel.text = L10n.launchDetailLinksTitle
        titleLabel.accessibilityTraits.insert(.header)
        card.addSubview(titleLabel)

        let stack = UIStackView(arrangedSubviews: [wikipediaButton, articleButton, webcastButton])
        stack.axis = .vertical
        stack.spacing = 8
        card.addSubview(stack)

        [wikipediaButton, articleButton, webcastButton].forEach {
            $0.setTitleColor(AppColors.white, for: .normal)
            $0.titleLabel?.font = AppFonts.medium16
            $0.contentHorizontalAlignment = .left
        }
        wikipediaButton.setTitle(L10n.launchDetailOpenWikipedia, for: .normal)
        articleButton.setTitle(L10n.launchDetailOpenArticle, for: .normal)
        webcastButton.setTitle(L10n.launchDetailOpenWebcast, for: .normal)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
        return card
    }

    private func configureLinkButton(_ button: UIButton, url: URL?) {
        button.isHidden = (url == nil)
        button.removeTarget(nil, action: nil, for: .touchUpInside)
        guard let url else { return }
        button.addAction(UIAction { [weak self] _ in
            self?.onOpenURL?(url)
        }, for: .touchUpInside)
    }

    private func sanitizedURL(_ url: URL?) -> URL? {
        guard let url else { return nil }
        if url.scheme?.lowercased() == "https" {
            return url
        }
        if url.scheme?.lowercased() == "http",
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.scheme = "https"
            return components.url
        }
        return nil
    }

    private func payloadDisplayText(_ payload: Payload) -> String {
        let namePart = payload.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let typePart = payload.type?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (namePart?.isEmpty == false ? namePart : nil, typePart?.isEmpty == false ? typePart : nil) {
        case let (name?, type?):
            return "\(name) (\(type))"
        case let (name?, nil):
            return name
        case let (nil, type?):
            return "\(payload.id) (\(type))"
        default:
            return payload.id
        }
    }

    private func crewDisplayText(_ crew: CrewMember) -> String {
        let namePart = crew.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rolePart = crew.role?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (namePart?.isEmpty == false ? namePart : nil, rolePart?.isEmpty == false ? rolePart : nil) {
        case let (name?, role?):
            return "\(name) — \(role)"
        case let (name?, nil):
            return name
        case let (nil, role?):
            return "\(crew.crewId) — \(role)"
        default:
            return crew.crewId
        }
    }

    private func capsuleDisplayText(_ capsule: Capsule) -> String {
        let serialPart = capsule.serial?.trimmingCharacters(in: .whitespacesAndNewlines)
        let typePart = capsule.type?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (serialPart?.isEmpty == false ? serialPart : nil, typePart?.isEmpty == false ? typePart : nil) {
        case let (serial?, type?):
            return "\(serial) (\(type))"
        case let (serial?, nil):
            return serial
        case let (nil, type?):
            return "\(capsule.id) (\(type))"
        default:
            return capsule.id
        }
    }

    private func shipDisplayText(_ ship: Ship) -> String {
        let namePart = ship.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let typePart = ship.type?.trimmingCharacters(in: .whitespacesAndNewlines)
        let portPart = ship.homePort?.trimmingCharacters(in: .whitespacesAndNewlines)

        let base: String
        switch (namePart?.isEmpty == false ? namePart : nil, typePart?.isEmpty == false ? typePart : nil) {
        case let (name?, type?):
            base = "\(name) (\(type))"
        case let (name?, nil):
            base = name
        case let (nil, type?):
            base = "\(ship.id) (\(type))"
        default:
            base = ship.id
        }

        if let port = portPart, !port.isEmpty {
            return "\(base) — \(port)"
        }
        return base
    }

    private func statusText(success: Bool?, upcoming: Bool) -> String {
        if upcoming { return L10n.launchesFilterUpcoming }
        if success == true { return L10n.launchesFilterSuccessful }
        if success == false { return L10n.launchesFilterFailed }
        return "-"
    }
}
