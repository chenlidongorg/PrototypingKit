import Foundation
import UIKit

public enum PrototypingDraftKind: String, Codable, CaseIterable, Identifiable {
    case appPage
    case webPage
    case flowNote
    case deviceShowcase

    public var id: String { rawValue }

    public static var allCases: [PrototypingDraftKind] {
        [.appPage, .webPage]
    }

    public var normalized: PrototypingDraftKind {
        self == .webPage ? .webPage : .appPage
    }

    public var title: String {
        switch self {
        case .appPage:
            return PrototypingL10n.text("draft_kind.app_page")
        case .webPage:
            return PrototypingL10n.text("draft_kind.web_page")
        case .flowNote:
            return PrototypingL10n.text("draft_kind.flow_note")
        case .deviceShowcase:
            return PrototypingL10n.text("draft_kind.device_showcase")
        }
    }
}

public enum PrototypingDeviceKind: String, Codable, CaseIterable, Identifiable {
    case phone
    case tablet

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .phone:
            return PrototypingL10n.text("device.phone")
        case .tablet:
            return PrototypingL10n.text("device.tablet")
        }
    }

    public var canvasSize: PrototypingCanvasSize {
        canvasSize(for: .portrait)
    }

    public func canvasSize(for orientation: PrototypingDeviceOrientation) -> PrototypingCanvasSize {
        switch self {
        case .phone:
            return orientation == .portrait ? .phonePortrait : .phoneLandscape
        case .tablet:
            return orientation == .portrait ? .tabletPortrait : .tabletLandscape
        }
    }
}

public enum PrototypingDeviceOrientation: String, Codable, CaseIterable, Identifiable {
    case portrait
    case landscape

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .portrait:
            return PrototypingL10n.text("orientation.portrait")
        case .landscape:
            return PrototypingL10n.text("orientation.landscape")
        }
    }
}

public enum PrototypingTemplate: String, Codable, CaseIterable, Identifiable {
    case blank
    case blankPhone
    case blankTablet
    case login
    case list
    case detail
    case form
    case chat
    case onboarding
    case profile
    case settings
    case checkout
    case tabletDashboard
    case calendar
    case kanban
    case mediaFeed
    case finance
    case habitTracker
    case webHome
    case dashboard
    case landing
    case pricing
    case webPortfolio
    case webBlog
    case webDocs
    case webSaaS
    case webAgency
    case webCourse
    case webEvent
    case webProduct
    case webGallery
    case webContact
    case webStatus

    public var id: String { rawValue }

    public static var appTemplates: [PrototypingTemplate] {
        [
            .blank,
            .list,
            .detail,
            .form,
            .login,
            .chat,
            .onboarding,
            .profile,
            .settings,
            .checkout,
            .tabletDashboard,
            .calendar,
            .kanban,
            .mediaFeed,
            .finance,
            .habitTracker
        ]
    }

    public static var webTemplates: [PrototypingTemplate] {
        [
            .blank,
            .webHome,
            .landing,
            .pricing,
            .dashboard,
            .webPortfolio,
            .webBlog,
            .webDocs,
            .webSaaS,
            .webAgency,
            .webCourse,
            .webEvent,
            .webProduct,
            .webGallery,
            .webContact,
            .webStatus
        ]
    }

    public var title: String {
        switch self {
        case .blank:
            return PrototypingL10n.text("template.blank")
        case .blankPhone:
            return PrototypingL10n.text("template.blank_phone")
        case .blankTablet:
            return PrototypingL10n.text("template.blank_tablet")
        case .login:
            return PrototypingL10n.text("template.login")
        case .list:
            return PrototypingL10n.text("template.list")
        case .detail:
            return PrototypingL10n.text("template.detail")
        case .form:
            return PrototypingL10n.text("template.form")
        case .chat:
            return PrototypingL10n.text("template.chat")
        case .onboarding:
            return PrototypingL10n.text("template.onboarding")
        case .profile:
            return PrototypingL10n.text("template.profile")
        case .settings:
            return PrototypingL10n.text("template.settings")
        case .checkout:
            return PrototypingL10n.text("template.checkout")
        case .tabletDashboard:
            return PrototypingL10n.text("template.tablet_dashboard")
        case .calendar:
            return PrototypingL10n.text("template.calendar")
        case .kanban:
            return PrototypingL10n.text("template.kanban")
        case .mediaFeed:
            return PrototypingL10n.text("template.media_feed")
        case .finance:
            return PrototypingL10n.text("template.finance")
        case .habitTracker:
            return PrototypingL10n.text("template.habit_tracker")
        case .webHome:
            return PrototypingL10n.text("template.web_home")
        case .dashboard:
            return PrototypingL10n.text("template.dashboard")
        case .landing:
            return PrototypingL10n.text("template.landing")
        case .pricing:
            return PrototypingL10n.text("template.pricing")
        case .webPortfolio:
            return PrototypingL10n.text("template.web_portfolio")
        case .webBlog:
            return PrototypingL10n.text("template.web_blog")
        case .webDocs:
            return PrototypingL10n.text("template.web_docs")
        case .webSaaS:
            return PrototypingL10n.text("template.web_saas")
        case .webAgency:
            return PrototypingL10n.text("template.web_agency")
        case .webCourse:
            return PrototypingL10n.text("template.web_course")
        case .webEvent:
            return PrototypingL10n.text("template.web_event")
        case .webProduct:
            return PrototypingL10n.text("template.web_product")
        case .webGallery:
            return PrototypingL10n.text("template.web_gallery")
        case .webContact:
            return PrototypingL10n.text("template.web_contact")
        case .webStatus:
            return PrototypingL10n.text("template.web_status")
        }
    }

    public var kind: PrototypingDraftKind {
        switch self {
        case .webHome,
             .dashboard,
             .landing,
             .pricing,
             .webPortfolio,
             .webBlog,
             .webDocs,
             .webSaaS,
             .webAgency,
             .webCourse,
             .webEvent,
             .webProduct,
             .webGallery,
             .webContact,
             .webStatus:
            return .webPage
        default:
            return .appPage
        }
    }

    public var preferredDevice: PrototypingDeviceKind? {
        switch self {
        case .blank:
            return nil
        case .blankPhone:
            return .phone
        case .blankTablet, .tabletDashboard:
            return .tablet
        case .webHome,
             .dashboard,
             .landing,
             .pricing,
             .webPortfolio,
             .webBlog,
             .webDocs,
             .webSaaS,
             .webAgency,
             .webCourse,
             .webEvent,
             .webProduct,
             .webGallery,
             .webContact,
             .webStatus:
            return nil
        default:
            return nil
        }
    }
}

public enum PrototypingComponent: String, Codable, CaseIterable, Identifiable {
    case title
    case subtitle
    case button
    case input
    case search
    case card
    case listRow
    case imagePlaceholder
    case bottomNavigation
    case topNavigation
    case segmentedControl
    case avatar
    case tag
    case toggle
    case checkbox
    case progress
    case chart
    case table
    case sidebar
    case dialog
    case arrow
    case aiNote

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .title:
            return PrototypingL10n.text("component.title")
        case .subtitle:
            return PrototypingL10n.text("component.subtitle")
        case .button:
            return PrototypingL10n.text("component.button")
        case .input:
            return PrototypingL10n.text("component.input")
        case .search:
            return PrototypingL10n.text("component.search")
        case .card:
            return PrototypingL10n.text("component.card")
        case .listRow:
            return PrototypingL10n.text("component.list_row")
        case .imagePlaceholder:
            return PrototypingL10n.text("component.image_placeholder")
        case .bottomNavigation:
            return PrototypingL10n.text("component.bottom_navigation")
        case .topNavigation:
            return PrototypingL10n.text("component.top_navigation")
        case .segmentedControl:
            return PrototypingL10n.text("component.segmented_control")
        case .avatar:
            return PrototypingL10n.text("component.avatar")
        case .tag:
            return PrototypingL10n.text("component.tag")
        case .toggle:
            return PrototypingL10n.text("component.toggle")
        case .checkbox:
            return PrototypingL10n.text("component.checkbox")
        case .progress:
            return PrototypingL10n.text("component.progress")
        case .chart:
            return PrototypingL10n.text("component.chart")
        case .table:
            return PrototypingL10n.text("component.table")
        case .sidebar:
            return PrototypingL10n.text("component.sidebar")
        case .dialog:
            return PrototypingL10n.text("component.dialog")
        case .arrow:
            return PrototypingL10n.text("component.arrow")
        case .aiNote:
            return PrototypingL10n.text("component.annotation")
        }
    }
}

public enum PrototypingButtonStyle: String, Codable, CaseIterable, Identifiable {
    case primary
    case secondary
    case outline
    case soft
    case ghost
    case pill

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .primary:
            return PrototypingL10n.text("button_style.primary")
        case .secondary:
            return PrototypingL10n.text("button_style.secondary")
        case .outline:
            return PrototypingL10n.text("button_style.outline")
        case .soft:
            return PrototypingL10n.text("button_style.soft")
        case .ghost:
            return PrototypingL10n.text("button_style.ghost")
        case .pill:
            return PrototypingL10n.text("button_style.pill")
        }
    }
}

public enum PrototypingImportIntent: String, Codable {
    case setAsBackground
    case insertAsMovableObject
    case importAsNewPages
    case sendToAI
    case exportOnly
    case savePDF
    case sharePDF
}

public struct PrototypingCanvasSize: Codable, Hashable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public var cgSize: CGSize {
        CGSize(width: width, height: height)
    }

    public static let phonePortrait = PrototypingCanvasSize(width: 390, height: 844)
    public static let phoneLandscape = PrototypingCanvasSize(width: 844, height: 390)
    public static let tabletPortrait = PrototypingCanvasSize(width: 834, height: 1194)
    public static let tabletLandscape = PrototypingCanvasSize(width: 1194, height: 834)
    public static let phone = phonePortrait
    public static let tablet = tabletPortrait
    public static let web = PrototypingCanvasSize(width: 960, height: 540)
}

public struct PrototypingElementFrame: Codable, Hashable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    public func moved(by translation: CGSize, inside canvasSize: CGSize) -> PrototypingElementFrame {
        let nextX = max(0, min(canvasSize.width - width, x + Double(translation.width)))
        let nextY = max(0, min(canvasSize.height - height, y + Double(translation.height)))
        return PrototypingElementFrame(x: nextX, y: nextY, width: width, height: height)
    }

    public func constrained(
        inside canvasSize: CGSize,
        minimumSize: CGSize,
        maximumSize: CGSize
    ) -> PrototypingElementFrame {
        let proposedWidth = CGFloat(width)
        let proposedHeight = CGFloat(height)
        let proposedX = CGFloat(x)
        let proposedY = CGFloat(y)
        let resolvedWidth = min(
            min(maximumSize.width, canvasSize.width),
            max(minimumSize.width, proposedWidth)
        )
        let resolvedHeight = min(
            min(maximumSize.height, canvasSize.height),
            max(minimumSize.height, proposedHeight)
        )
        let resolvedX = max(0, min(canvasSize.width - resolvedWidth, proposedX))
        let resolvedY = max(0, min(canvasSize.height - resolvedHeight, proposedY))

        return PrototypingElementFrame(
            x: Double(resolvedX),
            y: Double(resolvedY),
            width: Double(resolvedWidth),
            height: Double(resolvedHeight)
        )
    }
}

public struct PrototypingCanvasPoint: Codable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(_ point: CGPoint) {
        self.x = Double(point.x)
        self.y = Double(point.y)
    }

    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

public enum PrototypingAnnotationAnchor: String, Codable, CaseIterable, Identifiable {
    case top
    case bottom
    case left
    case right

    public var id: String { rawValue }
}

public struct PrototypingAnnotationArrow: Codable, Hashable {
    public var anchor: PrototypingAnnotationAnchor
    public var target: PrototypingCanvasPoint

    public init(anchor: PrototypingAnnotationAnchor, target: PrototypingCanvasPoint) {
        self.anchor = anchor
        self.target = target
    }
}

public struct PrototypingCanvasElement: Codable, Identifiable, Hashable {
    public var id: String
    public var component: PrototypingComponent
    public var title: String?
    public var frame: PrototypingElementFrame
    public var annotationArrow: PrototypingAnnotationArrow?
    public var buttonStyle: PrototypingButtonStyle?

    public init(
        id: String = UUID().uuidString,
        component: PrototypingComponent,
        title: String? = nil,
        frame: PrototypingElementFrame,
        annotationArrow: PrototypingAnnotationArrow? = nil,
        buttonStyle: PrototypingButtonStyle? = nil
    ) {
        self.id = id
        self.component = component
        self.title = title
        self.frame = frame
        self.annotationArrow = annotationArrow
        self.buttonStyle = component == .button ? buttonStyle : nil
    }
}

public struct PrototypingDraftRecord: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var thumbnailFileName: String?

    public init(
        id: String,
        title: String,
        createdAt: Date,
        updatedAt: Date,
        thumbnailFileName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailFileName = thumbnailFileName
    }
}

public struct PrototypingDraftBoard: Codable, Identifiable, Hashable {
    public var id: String
    public var kind: PrototypingDraftKind
    public var template: PrototypingTemplate
    public var device: PrototypingDeviceKind?
    public var orientation: PrototypingDeviceOrientation?
    public var canvasSize: PrototypingCanvasSize
    public var enabledComponents: [PrototypingComponent]
    public var elements: [PrototypingCanvasElement]

    public init(
        id: String,
        kind: PrototypingDraftKind,
        template: PrototypingTemplate,
        device: PrototypingDeviceKind? = nil,
        orientation: PrototypingDeviceOrientation? = nil,
        canvasSize: PrototypingCanvasSize,
        enabledComponents: [PrototypingComponent],
        elements: [PrototypingCanvasElement]
    ) {
        self.id = id
        self.kind = kind.normalized
        self.template = template
        self.device = device
        self.orientation = orientation
        self.canvasSize = canvasSize
        self.enabledComponents = enabledComponents
        self.elements = elements
    }
}

public struct PrototypingDraftDocument: Codable, Identifiable, Hashable {
    public static var defaultAnnotationText: String {
        PrototypingL10n.text("default.annotation_text")
    }
    private static var legacyDefaultAnnotationText: String {
        PrototypingL10n.text("default.legacy_annotation_text")
    }

    public static func annotationTextOrDefault(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == legacyDefaultAnnotationText {
            return defaultAnnotationText
        }
        return text
    }

    public var id: String
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var revisionID: String
    public var kind: PrototypingDraftKind
    public var template: PrototypingTemplate
    public var device: PrototypingDeviceKind
    public var orientation: PrototypingDeviceOrientation
    public var canvasSize: PrototypingCanvasSize
    public var gridSize: Double
    public var enabledComponents: [PrototypingComponent]
    public var elements: [PrototypingCanvasElement]
    public var note: String
    public var activeBoardID: String
    public var boards: [String: PrototypingDraftBoard]
    public var orientationPreferences: [String: PrototypingDeviceOrientation]

    public init(
        id: String = UUID().uuidString,
        title: String = PrototypingDraftDocument.defaultTitle(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        revisionID: String = UUID().uuidString,
        kind: PrototypingDraftKind = .appPage,
        template: PrototypingTemplate = .blank,
        device: PrototypingDeviceKind = .phone,
        orientation: PrototypingDeviceOrientation = .portrait,
        canvasSize: PrototypingCanvasSize? = nil,
        gridSize: Double = 12,
        enabledComponents: [PrototypingComponent] = [.title, .search, .card, .listRow, .bottomNavigation],
        elements: [PrototypingCanvasElement]? = nil,
        note: String = PrototypingDraftDocument.defaultAnnotationText,
        activeBoardID: String? = nil,
        boards: [String: PrototypingDraftBoard]? = nil,
        orientationPreferences: [String: PrototypingDeviceOrientation]? = nil
    ) {
        let normalizedKind = kind.normalized
        let resolvedCanvasSize = canvasSize ?? (normalizedKind == .webPage ? .web : device.canvasSize(for: orientation))
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.revisionID = revisionID
        self.kind = normalizedKind
        self.template = template
        self.device = device
        self.orientation = orientation
        self.canvasSize = resolvedCanvasSize
        self.gridSize = gridSize
        self.enabledComponents = enabledComponents
        self.elements = elements ?? PrototypingDraftDocument.defaultElements(for: template, canvasSize: resolvedCanvasSize)
        self.note = note
        self.activeBoardID = activeBoardID ?? PrototypingDraftDocument.boardID(
            kind: normalizedKind,
            device: device,
            orientation: orientation
        )
        self.boards = boards ?? [:]
        self.orientationPreferences = orientationPreferences
            ?? PrototypingDraftDocument.defaultOrientationPreferences(device: device, orientation: orientation)
        syncActiveBoardFromCompatibilityFields()
        ensureStandardBoards()
        loadActiveBoard()
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
        case updatedAt
        case revisionID
        case kind
        case template
        case device
        case orientation
        case canvasSize
        case gridSize
        case enabledComponents
        case elements
        case note
        case activeBoardID
        case boards
        case orientationPreferences
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        revisionID = try container.decode(String.self, forKey: .revisionID)
        kind = try container.decode(PrototypingDraftKind.self, forKey: .kind).normalized
        template = try container.decode(PrototypingTemplate.self, forKey: .template)
        device = try container.decodeIfPresent(PrototypingDeviceKind.self, forKey: .device)
            ?? (try container.decode(PrototypingCanvasSize.self, forKey: .canvasSize).width > 600 ? .tablet : .phone)
        canvasSize = try container.decode(PrototypingCanvasSize.self, forKey: .canvasSize)
        orientation = try container.decodeIfPresent(PrototypingDeviceOrientation.self, forKey: .orientation)
            ?? (canvasSize.width > canvasSize.height ? .landscape : .portrait)
        gridSize = try container.decodeIfPresent(Double.self, forKey: .gridSize) ?? 12
        enabledComponents = try container.decodeIfPresent([PrototypingComponent].self, forKey: .enabledComponents) ?? []
        note = Self.annotationTextOrDefault(
            try container.decodeIfPresent(String.self, forKey: .note) ?? Self.defaultAnnotationText
        )
        elements = try container.decodeIfPresent([PrototypingCanvasElement].self, forKey: .elements)
            ?? PrototypingDraftDocument.defaultElements(for: template, canvasSize: canvasSize)
        activeBoardID = try container.decodeIfPresent(String.self, forKey: .activeBoardID)
            ?? PrototypingDraftDocument.boardID(kind: kind, device: device, orientation: orientation)
        boards = try container.decodeIfPresent([String: PrototypingDraftBoard].self, forKey: .boards) ?? [:]
        orientationPreferences = try container.decodeIfPresent([String: PrototypingDeviceOrientation].self, forKey: .orientationPreferences)
            ?? PrototypingDraftDocument.defaultOrientationPreferences(device: device, orientation: orientation)
        syncActiveBoardFromCompatibilityFields()
        ensureStandardBoards()
        loadActiveBoard()
    }

    public static func defaultTitle(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MM-dd HH:mm"
        return "\(PrototypingL10n.text("default.untitled")) \(formatter.string(from: now))"
    }

    public var record: PrototypingDraftRecord {
        PrototypingDraftRecord(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            thumbnailFileName: "thumbnail.png"
        )
    }

    public static let webBoardID = "web"

    public static func boardID(
        kind: PrototypingDraftKind,
        device: PrototypingDeviceKind,
        orientation: PrototypingDeviceOrientation
    ) -> String {
        if kind.normalized == .webPage {
            return webBoardID
        }

        return "app.\(device.rawValue).\(orientation.rawValue)"
    }

    public static var appBoardDescriptors: [(PrototypingDeviceKind, PrototypingDeviceOrientation)] {
        [
            (.phone, .portrait),
            (.phone, .landscape),
            (.tablet, .portrait),
            (.tablet, .landscape)
        ]
    }

    public mutating func activateBoard(
        kind targetKind: PrototypingDraftKind,
        device targetDevice: PrototypingDeviceKind,
        orientation targetOrientation: PrototypingDeviceOrientation
    ) {
        syncActiveBoardFromCompatibilityFields()
        kind = targetKind.normalized
        device = targetDevice
        orientation = targetOrientation
        setPreferredOrientation(targetOrientation, for: targetDevice)
        activeBoardID = PrototypingDraftDocument.boardID(
            kind: kind,
            device: device,
            orientation: orientation
        )
        ensureStandardBoards()
        loadActiveBoard()
    }

    public mutating func syncActiveBoardFromCompatibilityFields() {
        kind = kind.normalized
        canvasSize = kind == .webPage ? .web : device.canvasSize(for: orientation)
        if kind != .webPage {
            setPreferredOrientation(orientation, for: device)
        }
        activeBoardID = PrototypingDraftDocument.boardID(
            kind: kind,
            device: device,
            orientation: orientation
        )
        boards[activeBoardID] = PrototypingDraftBoard(
            id: activeBoardID,
            kind: kind,
            template: template,
            device: kind == .webPage ? nil : device,
            orientation: kind == .webPage ? nil : orientation,
            canvasSize: canvasSize,
            enabledComponents: enabledComponents,
            elements: elements
        )
    }

    public mutating func ensureStandardBoards() {
        for (device, orientation) in PrototypingDraftDocument.appBoardDescriptors {
            let id = PrototypingDraftDocument.boardID(kind: .appPage, device: device, orientation: orientation)
            if boards[id] == nil {
                let size = device.canvasSize(for: orientation)
                boards[id] = PrototypingDraftDocument.defaultBoard(
                    id: id,
                    kind: .appPage,
                    template: .blank,
                    device: device,
                    orientation: orientation,
                    canvasSize: size
                )
            }
        }

        if boards[PrototypingDraftDocument.webBoardID] == nil {
            boards[PrototypingDraftDocument.webBoardID] = PrototypingDraftDocument.defaultBoard(
                id: PrototypingDraftDocument.webBoardID,
                kind: .webPage,
                template: .blank,
                device: nil,
                orientation: nil,
                canvasSize: .web
            )
        }
    }

    public mutating func loadActiveBoard() {
        guard let board = boards[activeBoardID] else { return }

        kind = board.kind.normalized
        template = board.template
        device = board.device ?? device
        orientation = board.orientation ?? orientation
        if kind != .webPage {
            setPreferredOrientation(orientation, for: device)
        }
        canvasSize = board.canvasSize
        enabledComponents = board.enabledComponents
        elements = board.elements
    }

    public func preferredOrientation(for device: PrototypingDeviceKind) -> PrototypingDeviceOrientation {
        orientationPreferences[device.rawValue] ?? .portrait
    }

    public mutating func setPreferredOrientation(
        _ orientation: PrototypingDeviceOrientation,
        for device: PrototypingDeviceKind
    ) {
        orientationPreferences[device.rawValue] = orientation
    }

    public mutating func resizeAnnotationElementsForCurrentNote() {
        let size = canvasSize.cgSize
        elements = elements.map { element in
            guard element.component == .aiNote else { return element }
            var copy = element
            let trimmedTitle = element.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let annotationText = trimmedTitle.isEmpty || trimmedTitle == PrototypingComponent.aiNote.title
                ? Self.annotationTextOrDefault(note)
                : trimmedTitle
            copy.frame = PrototypingDraftDocument.annotationFrame(
                for: annotationText,
                existingFrame: element.frame,
                canvasSize: size
            )
            return copy
        }
    }

    public func exportDocumentsForCurrentKind(boardIDs selectedBoardIDs: [String]? = nil) -> [PrototypingDraftDocument] {
        var exportSource = self
        exportSource.syncActiveBoardFromCompatibilityFields()
        exportSource.ensureStandardBoards()

        let allowedBoardIDs: [String]
        if exportSource.kind == .webPage {
            allowedBoardIDs = [PrototypingDraftDocument.webBoardID]
        } else {
            allowedBoardIDs = PrototypingDraftDocument.appBoardDescriptors.map {
                PrototypingDraftDocument.boardID(kind: .appPage, device: $0.0, orientation: $0.1)
            }
        }

        let boardIDs = selectedBoardIDs
            .map { selected in
                selected.filter { allowedBoardIDs.contains($0) }
            }
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? allowedBoardIDs

        return boardIDs.compactMap { boardID in
            guard exportSource.boards[boardID]?.elements.isEmpty == false else { return nil }
            var document = exportSource
            document.activeBoardID = boardID
            document.loadActiveBoard()
            return document
        }
    }

    public static func defaultElements(
        for template: PrototypingTemplate,
        canvasSize: PrototypingCanvasSize
    ) -> [PrototypingCanvasElement] {
        let size = canvasSize.cgSize
        let isWeb = template.kind == .webPage

        if template == .blank || template == .blankPhone || template == .blankTablet {
            return []
        }

        if isWeb {
            let elements: [PrototypingCanvasElement]
            switch template {
            case .dashboard:
                elements = [
                    element(.sidebar, x: 0, y: 0, width: 150, height: size.height),
                    element(.title, x: 190, y: 44, width: 220, height: 34),
                    element(.card, x: 190, y: 104, width: 210, height: 112),
                    element(.card, x: 424, y: 104, width: 210, height: 112),
                    element(.card, x: 658, y: 104, width: 210, height: 112),
                    element(.chart, x: 206, y: 248, width: 372, height: 168),
                    element(.table, x: 602, y: 248, width: 260, height: 168),
                    element(.aiNote, x: size.width - 150, y: 28, width: 112, height: 38)
                ]
            case .landing:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 126, width: 310, height: 42),
                    element(.subtitle, x: 64, y: 186, width: 360, height: 30),
                    element(.button, x: 64, y: 246, width: 160, height: 48),
                    element(.imagePlaceholder, x: 542, y: 116, width: 330, height: 200),
                    element(.card, x: 64, y: 384, width: 250, height: 112),
                    element(.card, x: 354, y: 384, width: 250, height: 112),
                    element(.card, x: 644, y: 384, width: 250, height: 112),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .pricing:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 320, y: 90, width: 320, height: 42),
                    element(.subtitle, x: 286, y: 150, width: 388, height: 30),
                    element(.card, x: 92, y: 228, width: 230, height: 250),
                    element(.card, x: 365, y: 208, width: 230, height: 282),
                    element(.card, x: 638, y: 228, width: 230, height: 250),
                    element(.tag, x: 438, y: 232, width: 84, height: 30),
                    element(.button, x: 400, y: 412, width: 160, height: 44, buttonStyle: .pill),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webPortfolio:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 108, width: 280, height: 42),
                    element(.subtitle, x: 64, y: 168, width: 320, height: 30),
                    element(.button, x: 64, y: 232, width: 142, height: 44, buttonStyle: .outline),
                    element(.imagePlaceholder, x: 474, y: 100, width: 370, height: 214),
                    element(.card, x: 64, y: 364, width: 182, height: 104),
                    element(.card, x: 270, y: 364, width: 182, height: 104),
                    element(.card, x: 476, y: 364, width: 182, height: 104),
                    element(.card, x: 682, y: 364, width: 182, height: 104),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webBlog:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 104, width: 300, height: 40),
                    element(.subtitle, x: 64, y: 160, width: 420, height: 30),
                    element(.imagePlaceholder, x: 64, y: 224, width: 360, height: 192),
                    element(.listRow, x: 474, y: 220, width: 330, height: 58),
                    element(.listRow, x: 474, y: 302, width: 330, height: 58),
                    element(.listRow, x: 474, y: 384, width: 330, height: 58),
                    element(.tag, x: 64, y: 438, width: 98, height: 30),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webDocs:
                elements = [
                    element(.sidebar, x: 0, y: 0, width: 180, height: size.height),
                    element(.topNavigation, x: 216, y: 24, width: 684, height: 52),
                    element(.search, x: 236, y: 108, width: 300, height: 44),
                    element(.title, x: 236, y: 184, width: 320, height: 40),
                    element(.subtitle, x: 236, y: 244, width: 420, height: 30),
                    element(.card, x: 236, y: 314, width: 286, height: 128),
                    element(.card, x: 554, y: 314, width: 286, height: 128),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webSaaS:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 112, width: 330, height: 42),
                    element(.subtitle, x: 64, y: 174, width: 360, height: 30),
                    element(.button, x: 64, y: 236, width: 156, height: 46, buttonStyle: .primary),
                    element(.button, x: 240, y: 236, width: 132, height: 46, buttonStyle: .ghost),
                    element(.chart, x: 512, y: 112, width: 346, height: 214),
                    element(.card, x: 64, y: 380, width: 248, height: 104),
                    element(.card, x: 356, y: 380, width: 248, height: 104),
                    element(.card, x: 648, y: 380, width: 248, height: 104),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webAgency:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 110, width: 270, height: 42),
                    element(.subtitle, x: 64, y: 170, width: 340, height: 30),
                    element(.button, x: 64, y: 232, width: 150, height: 46, buttonStyle: .secondary),
                    element(.imagePlaceholder, x: 530, y: 102, width: 320, height: 188),
                    element(.card, x: 64, y: 350, width: 252, height: 126),
                    element(.card, x: 354, y: 350, width: 252, height: 126),
                    element(.card, x: 644, y: 350, width: 252, height: 126),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webCourse:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.imagePlaceholder, x: 58, y: 108, width: 384, height: 234),
                    element(.title, x: 494, y: 112, width: 306, height: 42),
                    element(.subtitle, x: 494, y: 174, width: 318, height: 30),
                    element(.progress, x: 494, y: 238, width: 260, height: 18),
                    element(.button, x: 494, y: 294, width: 156, height: 46, buttonStyle: .pill),
                    element(.listRow, x: 58, y: 386, width: 250, height: 58),
                    element(.listRow, x: 342, y: 386, width: 250, height: 58),
                    element(.listRow, x: 626, y: 386, width: 250, height: 58),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webEvent:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.tag, x: 64, y: 110, width: 104, height: 30),
                    element(.title, x: 64, y: 156, width: 330, height: 42),
                    element(.subtitle, x: 64, y: 218, width: 360, height: 30),
                    element(.button, x: 64, y: 286, width: 150, height: 46, buttonStyle: .primary),
                    element(.card, x: 514, y: 114, width: 330, height: 238),
                    element(.listRow, x: 64, y: 398, width: 234, height: 56),
                    element(.listRow, x: 330, y: 398, width: 234, height: 56),
                    element(.listRow, x: 596, y: 398, width: 234, height: 56),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webProduct:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.imagePlaceholder, x: 76, y: 110, width: 360, height: 282),
                    element(.title, x: 510, y: 118, width: 300, height: 42),
                    element(.subtitle, x: 510, y: 180, width: 320, height: 30),
                    element(.segmentedControl, x: 510, y: 240, width: 240, height: 42),
                    element(.button, x: 510, y: 330, width: 152, height: 46, buttonStyle: .primary),
                    element(.button, x: 684, y: 330, width: 138, height: 46, buttonStyle: .outline),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webGallery:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 106, width: 288, height: 42),
                    element(.segmentedControl, x: 596, y: 106, width: 264, height: 42),
                    element(.imagePlaceholder, x: 64, y: 190, width: 248, height: 126),
                    element(.imagePlaceholder, x: 356, y: 190, width: 248, height: 126),
                    element(.imagePlaceholder, x: 648, y: 190, width: 248, height: 126),
                    element(.imagePlaceholder, x: 64, y: 356, width: 248, height: 126),
                    element(.imagePlaceholder, x: 356, y: 356, width: 248, height: 126),
                    element(.imagePlaceholder, x: 648, y: 356, width: 248, height: 126),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webContact:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 112, width: 280, height: 42),
                    element(.subtitle, x: 64, y: 172, width: 330, height: 30),
                    element(.input, x: 64, y: 242, width: 310, height: 46),
                    element(.input, x: 64, y: 310, width: 310, height: 46),
                    element(.card, x: 482, y: 224, width: 330, height: 164),
                    element(.button, x: 64, y: 386, width: 150, height: 46, buttonStyle: .primary),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            case .webStatus:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.tag, x: 410, y: 110, width: 140, height: 32),
                    element(.title, x: 308, y: 166, width: 344, height: 42),
                    element(.subtitle, x: 278, y: 226, width: 404, height: 30),
                    element(.progress, x: 300, y: 292, width: 360, height: 18),
                    element(.listRow, x: 152, y: 360, width: 266, height: 56),
                    element(.listRow, x: 542, y: 360, width: 266, height: 56),
                    element(.button, x: 400, y: 444, width: 160, height: 44, buttonStyle: .soft),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            default:
                elements = [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 70, width: 300, height: 42),
                    element(.subtitle, x: 64, y: 126, width: 340, height: 28),
                    element(.button, x: 64, y: 158, width: 160, height: 48, buttonStyle: .primary),
                    element(.imagePlaceholder, x: 520, y: 70, width: 330, height: 190),
                    element(.card, x: 64, y: 318, width: 250, height: 120),
                    element(.card, x: 354, y: 318, width: 250, height: 120),
                    element(.card, x: 644, y: 318, width: 250, height: 120),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            }
            return elementsWithoutDefaultAnnotations(elements)
        }

        let baseElements: [PrototypingCanvasElement]
        switch template {
        case .login:
            baseElements = [
                element(.title, x: 66, y: 154, width: 250, height: 34),
                element(.imagePlaceholder, x: 154, y: 226, width: 82, height: 82),
                element(.input, x: 62, y: 344, width: 266, height: 46),
                element(.input, x: 62, y: 410, width: 266, height: 46),
                element(.button, x: 84, y: 492, width: 222, height: 48, buttonStyle: .primary),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .form:
            baseElements = [
                element(.title, x: 44, y: 52, width: 230, height: 34),
                element(.input, x: 44, y: 120, width: 280, height: 46),
                element(.input, x: 44, y: 188, width: 280, height: 46),
                element(.input, x: 44, y: 256, width: 220, height: 46),
                element(.card, x: 44, y: 330, width: 302, height: 126),
                element(.button, x: 44, y: 488, width: 160, height: 48, buttonStyle: .outline),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .chat:
            baseElements = [
                element(.title, x: 44, y: 52, width: 220, height: 34),
                element(.dialog, x: 40, y: 122, width: 230, height: 68),
                element(.dialog, x: 120, y: 218, width: 230, height: 68),
                element(.dialog, x: 40, y: 314, width: 196, height: 68),
                element(.search, x: 34, y: 718, width: 322, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .detail:
            baseElements = [
                element(.title, x: 44, y: 52, width: 220, height: 34),
                element(.imagePlaceholder, x: 42, y: 112, width: 306, height: 180),
                element(.card, x: 42, y: 320, width: 306, height: 80),
                element(.listRow, x: 42, y: 430, width: 306, height: 54),
                element(.button, x: 42, y: 526, width: 160, height: 48, buttonStyle: .soft),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .onboarding:
            baseElements = [
                element(.imagePlaceholder, x: 74, y: 98, width: 242, height: 210),
                element(.title, x: 58, y: 360, width: 250, height: 36),
                element(.subtitle, x: 58, y: 420, width: 278, height: 28),
                element(.progress, x: 128, y: 510, width: 134, height: 18),
                element(.button, x: 76, y: 580, width: 238, height: 48, buttonStyle: .pill),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .profile:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.avatar, x: 44, y: 124, width: 72, height: 72),
                element(.title, x: 136, y: 132, width: 170, height: 34),
                element(.subtitle, x: 136, y: 180, width: 188, height: 24),
                element(.card, x: 34, y: 248, width: 322, height: 92),
                element(.listRow, x: 44, y: 378, width: 292, height: 56),
                element(.listRow, x: 44, y: 454, width: 292, height: 56),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .settings:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.title, x: 34, y: 116, width: 220, height: 34),
                element(.listRow, x: 44, y: 190, width: 292, height: 56),
                element(.toggle, x: 278, y: 202, width: 58, height: 32),
                element(.listRow, x: 44, y: 270, width: 292, height: 56),
                element(.checkbox, x: 222, y: 284, width: 114, height: 28),
                element(.listRow, x: 44, y: 350, width: 292, height: 56),
                element(.button, x: 34, y: 514, width: 170, height: 48, buttonStyle: .secondary),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .checkout:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.title, x: 34, y: 116, width: 220, height: 34),
                element(.card, x: 34, y: 180, width: 322, height: 118),
                element(.input, x: 44, y: 330, width: 280, height: 46),
                element(.listRow, x: 44, y: 410, width: 292, height: 56),
                element(.tag, x: 44, y: 498, width: 102, height: 32),
                element(.button, x: 34, y: 646, width: 322, height: 52, buttonStyle: .primary),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .tabletDashboard:
            baseElements = [
                element(.sidebar, x: 32, y: 40, width: 156, height: 1114),
                element(.topNavigation, x: 216, y: 40, width: 586, height: 56),
                element(.title, x: 216, y: 132, width: 260, height: 38),
                element(.card, x: 216, y: 206, width: 272, height: 132),
                element(.card, x: 530, y: 206, width: 272, height: 132),
                element(.chart, x: 216, y: 382, width: 586, height: 250),
                element(.table, x: 216, y: 672, width: 586, height: 310),
                element(.aiNote, x: 668, y: 132, width: 112, height: 38)
            ]
        case .calendar:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.title, x: 34, y: 116, width: 220, height: 34),
                element(.segmentedControl, x: 34, y: 172, width: 248, height: 42),
                element(.card, x: 34, y: 246, width: 322, height: 234),
                element(.tag, x: 44, y: 512, width: 102, height: 32),
                element(.listRow, x: 44, y: 568, width: 292, height: 54),
                element(.listRow, x: 44, y: 638, width: 292, height: 54),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .kanban:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.title, x: 34, y: 114, width: 220, height: 34),
                element(.segmentedControl, x: 34, y: 170, width: 280, height: 42),
                element(.card, x: 34, y: 244, width: 322, height: 102),
                element(.card, x: 34, y: 370, width: 322, height: 102),
                element(.card, x: 34, y: 496, width: 322, height: 102),
                element(.button, x: 34, y: 644, width: 168, height: 46, buttonStyle: .soft),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .mediaFeed:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.avatar, x: 34, y: 116, width: 56, height: 56),
                element(.avatar, x: 106, y: 116, width: 56, height: 56),
                element(.avatar, x: 178, y: 116, width: 56, height: 56),
                element(.avatar, x: 250, y: 116, width: 56, height: 56),
                element(.imagePlaceholder, x: 34, y: 214, width: 322, height: 238),
                element(.title, x: 34, y: 482, width: 220, height: 34),
                element(.subtitle, x: 34, y: 536, width: 280, height: 28),
                element(.button, x: 34, y: 606, width: 132, height: 42, buttonStyle: .ghost),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .finance:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.title, x: 34, y: 116, width: 220, height: 34),
                element(.segmentedControl, x: 34, y: 172, width: 248, height: 42),
                element(.chart, x: 34, y: 246, width: 322, height: 180),
                element(.card, x: 34, y: 462, width: 150, height: 110),
                element(.card, x: 206, y: 462, width: 150, height: 110),
                element(.table, x: 34, y: 606, width: 322, height: 110),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .habitTracker:
            baseElements = [
                element(.topNavigation, x: 26, y: 36, width: 338, height: 52),
                element(.title, x: 34, y: 116, width: 220, height: 34),
                element(.progress, x: 34, y: 180, width: 292, height: 18),
                element(.card, x: 34, y: 238, width: 322, height: 132),
                element(.checkbox, x: 44, y: 408, width: 116, height: 30),
                element(.checkbox, x: 44, y: 470, width: 116, height: 30),
                element(.checkbox, x: 44, y: 532, width: 116, height: 30),
                element(.button, x: 34, y: 630, width: 170, height: 46, buttonStyle: .pill),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .blank,
             .blankPhone,
             .blankTablet,
             .list,
             .webHome,
             .dashboard,
             .landing,
             .pricing,
             .webPortfolio,
             .webBlog,
             .webDocs,
             .webSaaS,
             .webAgency,
             .webCourse,
             .webEvent,
             .webProduct,
             .webGallery,
             .webContact,
             .webStatus:
            baseElements = [
                element(.title, x: 34, y: 36, width: 220, height: 34),
                element(.search, x: 34, y: 96, width: 284, height: 44),
                element(.card, x: 34, y: 170, width: 322, height: 92),
                element(.card, x: 34, y: 286, width: 322, height: 92),
                element(.listRow, x: 44, y: 414, width: 292, height: 56),
                element(.button, x: 34, y: 520, width: 170, height: 48, buttonStyle: .primary),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        }

        let sourceSize = template == .tabletDashboard
            ? PrototypingCanvasSize.tablet.cgSize
            : PrototypingCanvasSize.phone.cgSize
        let templateElements = elementsWithoutDefaultAnnotations(baseElements)
        guard canvasSize.cgSize != sourceSize else { return templateElements }
        return scaledElements(templateElements, from: sourceSize, to: canvasSize.cgSize)
    }

    private static func elementsWithoutDefaultAnnotations(
        _ elements: [PrototypingCanvasElement]
    ) -> [PrototypingCanvasElement] {
        elements.filter { $0.component != .aiNote }
    }

    private static func scaledElements(
        _ elements: [PrototypingCanvasElement],
        from sourceSize: CGSize,
        to targetSize: CGSize
    ) -> [PrototypingCanvasElement] {
        guard sourceSize.width > 0, sourceSize.height > 0 else { return elements }
        let scaleX = targetSize.width / sourceSize.width
        let scaleY = targetSize.height / sourceSize.height

        return elements.map { element in
            var copy = element
            let minimumSize = element.component == .aiNote
                ? minimumSize(for: .aiNote)
                : CGSize(width: 12, height: 12)
            copy.frame = PrototypingElementFrame(
                x: Double(CGFloat(element.frame.x) * scaleX),
                y: Double(CGFloat(element.frame.y) * scaleY),
                width: Double(CGFloat(element.frame.width) * scaleX),
                height: Double(CGFloat(element.frame.height) * scaleY)
            )
            .constrained(
                inside: targetSize,
                minimumSize: minimumSize,
                maximumSize: maximumSize(for: element.component, canvasSize: targetSize)
            )
            return copy
        }
    }

    public static func defaultFrame(
        for component: PrototypingComponent,
        canvasSize: PrototypingCanvasSize
    ) -> PrototypingElementFrame {
        let size = canvasSize.cgSize
        let margin = size.width >= 700 ? CGFloat(40) : CGFloat(28)
        let defaultSize = defaultSize(for: component)
        var width = min(defaultSize.width, max(48, size.width - margin * 2))
        var height = min(defaultSize.height, max(24, size.height - margin * 2))
        var x = max(0, (size.width - width) / 2)
        var y = max(0, (size.height - height) / 2)

        switch component {
        case .topNavigation:
            width = max(120, size.width - margin * 2)
            x = margin
            y = margin
        case .bottomNavigation:
            width = max(160, size.width - margin * 2)
            x = margin
            y = max(margin, size.height - margin - height)
        case .sidebar:
            width = min(max(120, size.width * 0.2), 180)
            height = max(220, size.height - margin * 2)
            x = margin
            y = margin
        case .title:
            x = margin
            y = margin + 16
        case .subtitle:
            x = margin
            y = margin + 68
        case .button:
            x = margin
            y = min(max(margin, size.height * 0.66), max(margin, size.height - margin - height))
        case .aiNote:
            let annotationSize = annotationPreferredSize(for: Self.defaultAnnotationText, canvasSize: size)
            width = annotationSize.width
            height = annotationSize.height
            x = max(margin, size.width - margin - width)
            y = margin + 60
        case .search, .segmentedControl:
            x = margin
            y = margin + 96
        case .avatar:
            x = margin
            y = margin + 120
        case .tag, .toggle, .checkbox, .progress:
            x = margin
            y = margin + 180
        case .arrow:
            x = margin
            y = min(max(margin, size.height * 0.58), max(margin, size.height - margin - height))
        case .input, .card, .listRow, .imagePlaceholder, .chart, .table, .dialog:
            break
        }

        return PrototypingElementFrame(
            x: Double(x),
            y: Double(y),
            width: Double(width),
            height: Double(height)
        )
    }

    private static func defaultSize(for component: PrototypingComponent) -> CGSize {
        switch component {
        case .title:
            return CGSize(width: 220, height: 34)
        case .subtitle:
            return CGSize(width: 260, height: 28)
        case .button:
            return CGSize(width: 170, height: 48)
        case .input:
            return CGSize(width: 260, height: 46)
        case .search:
            return CGSize(width: 284, height: 44)
        case .card:
            return CGSize(width: 300, height: 92)
        case .listRow:
            return CGSize(width: 292, height: 56)
        case .imagePlaceholder:
            return CGSize(width: 240, height: 150)
        case .bottomNavigation:
            return CGSize(width: 338, height: 72)
        case .topNavigation:
            return CGSize(width: 338, height: 52)
        case .segmentedControl:
            return CGSize(width: 250, height: 42)
        case .avatar:
            return CGSize(width: 72, height: 72)
        case .tag:
            return CGSize(width: 102, height: 32)
        case .toggle:
            return CGSize(width: 58, height: 32)
        case .checkbox:
            return CGSize(width: 116, height: 30)
        case .progress:
            return CGSize(width: 220, height: 18)
        case .chart:
            return CGSize(width: 300, height: 160)
        case .table:
            return CGSize(width: 320, height: 180)
        case .sidebar:
            return CGSize(width: 120, height: 400)
        case .dialog:
            return CGSize(width: 230, height: 68)
        case .arrow:
            return CGSize(width: 150, height: 42)
        case .aiNote:
            return CGSize(width: 128, height: 44)
        }
    }

    public static func minimumSize(for component: PrototypingComponent) -> CGSize {
        switch component {
        case .title:
            return CGSize(width: 88, height: 28)
        case .subtitle:
            return CGSize(width: 96, height: 24)
        case .button:
            return CGSize(width: 86, height: 36)
        case .input:
            return CGSize(width: 120, height: 36)
        case .search:
            return CGSize(width: 132, height: 36)
        case .card:
            return CGSize(width: 140, height: 72)
        case .listRow:
            return CGSize(width: 132, height: 44)
        case .imagePlaceholder:
            return CGSize(width: 96, height: 76)
        case .bottomNavigation:
            return CGSize(width: 180, height: 56)
        case .topNavigation:
            return CGSize(width: 180, height: 42)
        case .segmentedControl:
            return CGSize(width: 132, height: 34)
        case .avatar:
            return CGSize(width: 44, height: 44)
        case .tag:
            return CGSize(width: 62, height: 26)
        case .toggle:
            return CGSize(width: 46, height: 28)
        case .checkbox:
            return CGSize(width: 72, height: 26)
        case .progress:
            return CGSize(width: 96, height: 14)
        case .chart:
            return CGSize(width: 160, height: 96)
        case .table:
            return CGSize(width: 170, height: 116)
        case .sidebar:
            return CGSize(width: 82, height: 180)
        case .dialog:
            return CGSize(width: 120, height: 48)
        case .arrow:
            return CGSize(width: 76, height: 30)
        case .aiNote:
            return CGSize(width: 96, height: 38)
        }
    }

    public static func maximumSize(
        for component: PrototypingComponent,
        canvasSize: CGSize
    ) -> CGSize {
        switch component {
        case .aiNote:
            let maxWidth = min(max(200, canvasSize.width * 0.72), canvasSize.width - 24)
            let maxHeight = min(220, canvasSize.height - 24)
            return CGSize(width: maxWidth, height: maxHeight)
        default:
            return CGSize(width: canvasSize.width, height: canvasSize.height)
        }
    }

    public static func annotationFrame(
        for note: String,
        existingFrame: PrototypingElementFrame,
        canvasSize: CGSize
    ) -> PrototypingElementFrame {
        let size = annotationPreferredSize(for: note, canvasSize: canvasSize)
        let frame = PrototypingElementFrame(
            x: existingFrame.x,
            y: existingFrame.y,
            width: Double(size.width),
            height: Double(size.height)
        )
        return frame.constrained(
            inside: canvasSize,
            minimumSize: minimumSize(for: .aiNote),
            maximumSize: maximumSize(for: .aiNote, canvasSize: canvasSize)
        )
    }

    public static func annotationPreferredSize(
        for note: String,
        canvasSize: CGSize
    ) -> CGSize {
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedText = Self.annotationTextOrDefault(text)
        let minimum = minimumSize(for: .aiNote)
        let maximum = maximumSize(for: .aiNote, canvasSize: canvasSize)
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let horizontalPadding: CGFloat = 28
        let verticalPadding: CGFloat = 18
        let lineWidthLimit = min(maximum.width, max(minimum.width, min(240, canvasSize.width - 24)))
        let longestLineWidth = resolvedText
            .components(separatedBy: .newlines)
            .map { ($0 as NSString).size(withAttributes: attributes).width }
            .max() ?? 0
        let preferredWidth = ceil(longestLineWidth + horizontalPadding)
        let width = min(lineWidthLimit, max(minimum.width, preferredWidth))
        let boundingSize = CGSize(width: max(1, width - horizontalPadding), height: .greatestFiniteMagnitude)
        let textBounds = (resolvedText as NSString).boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        let preferredHeight = ceil(textBounds.height + verticalPadding)
        let height = min(maximum.height, max(minimum.height, preferredHeight))

        return CGSize(width: width, height: height)
    }

    private static func element(
        _ component: PrototypingComponent,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        buttonStyle: PrototypingButtonStyle? = nil
    ) -> PrototypingCanvasElement {
        PrototypingCanvasElement(
            component: component,
            title: component == .aiNote ? Self.defaultAnnotationText : component.title,
            frame: PrototypingElementFrame(x: x, y: y, width: width, height: height),
            buttonStyle: buttonStyle
        )
    }

    private static func defaultBoard(
        id: String,
        kind: PrototypingDraftKind,
        template: PrototypingTemplate,
        device: PrototypingDeviceKind?,
        orientation: PrototypingDeviceOrientation?,
        canvasSize: PrototypingCanvasSize
    ) -> PrototypingDraftBoard {
        PrototypingDraftBoard(
            id: id,
            kind: kind,
            template: template,
            device: device,
            orientation: orientation,
            canvasSize: canvasSize,
            enabledComponents: defaultEnabledComponents(for: kind),
            elements: PrototypingDraftDocument.defaultElements(for: template, canvasSize: canvasSize)
        )
    }

    private static func defaultEnabledComponents(for kind: PrototypingDraftKind) -> [PrototypingComponent] {
        if kind.normalized == .webPage {
            return [.title, .subtitle, .button, .topNavigation, .card, .chart, .table, .tag]
        }

        return [.title, .button, .input, .search, .card, .listRow, .imagePlaceholder, .bottomNavigation]
    }

    private static func defaultOrientationPreferences(
        device: PrototypingDeviceKind,
        orientation: PrototypingDeviceOrientation
    ) -> [String: PrototypingDeviceOrientation] {
        var preferences: [String: PrototypingDeviceOrientation] = [
            PrototypingDeviceKind.phone.rawValue: .portrait,
            PrototypingDeviceKind.tablet.rawValue: .portrait
        ]
        preferences[device.rawValue] = orientation
        return preferences
    }
}

public struct PrototypingExportMetadata: Codable, Hashable {
    public var draftID: String
    public var revisionID: String
    public var title: String
    public var exportedAt: Date
    public var source: String
    public var recommendedIntent: PrototypingImportIntent

    public init(
        draftID: String,
        revisionID: String,
        title: String,
        exportedAt: Date = Date(),
        source: String = "PrototypingKit",
        recommendedIntent: PrototypingImportIntent
    ) {
        self.draftID = draftID
        self.revisionID = revisionID
        self.title = title
        self.exportedAt = exportedAt
        self.source = source
        self.recommendedIntent = recommendedIntent
    }
}

public enum PrototypingExportResult {
    case image(UIImage, metadata: PrototypingExportMetadata)
    case pdf(URL, metadata: PrototypingExportMetadata)

    public var metadata: PrototypingExportMetadata {
        switch self {
        case .image(_, let metadata), .pdf(_, let metadata):
            return metadata
        }
    }
}
