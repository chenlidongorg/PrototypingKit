import Foundation
import UIKit

public enum PrototypingDraftKind: String, Codable, CaseIterable, Identifiable {
    case appPage
    case webPage
    case flowNote
    case deviceShowcase

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .appPage:
            return "App页面"
        case .webPage:
            return "Web页面"
        case .flowNote:
            return "流程说明"
        case .deviceShowcase:
            return "设备展示"
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
            return "手机"
        case .tablet:
            return "平板"
        }
    }

    public var canvasSize: PrototypingCanvasSize {
        switch self {
        case .phone:
            return .phone
        case .tablet:
            return .tablet
        }
    }
}

public enum PrototypingTemplate: String, Codable, CaseIterable, Identifiable {
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
    case webHome
    case dashboard
    case landing
    case pricing

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blankPhone:
            return "空白手机页"
        case .blankTablet:
            return "空白平板页"
        case .login:
            return "登录页"
        case .list:
            return "列表页"
        case .detail:
            return "详情页"
        case .form:
            return "表单页"
        case .chat:
            return "聊天页"
        case .onboarding:
            return "引导页"
        case .profile:
            return "个人中心"
        case .settings:
            return "设置页"
        case .checkout:
            return "确认订单"
        case .tabletDashboard:
            return "平板看板"
        case .webHome:
            return "Web首页"
        case .dashboard:
            return "后台Dashboard"
        case .landing:
            return "Landing页"
        case .pricing:
            return "价格页"
        }
    }

    public var kind: PrototypingDraftKind {
        switch self {
        case .webHome, .dashboard, .landing, .pricing:
            return .webPage
        default:
            return .appPage
        }
    }

    public var preferredDevice: PrototypingDeviceKind? {
        switch self {
        case .blankPhone:
            return .phone
        case .blankTablet, .tabletDashboard:
            return .tablet
        case .webHome, .dashboard, .landing, .pricing:
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
            return "标题"
        case .subtitle:
            return "副标题"
        case .button:
            return "按钮"
        case .input:
            return "输入框"
        case .search:
            return "搜索框"
        case .card:
            return "卡片"
        case .listRow:
            return "列表行"
        case .imagePlaceholder:
            return "图片占位"
        case .bottomNavigation:
            return "底部导航"
        case .topNavigation:
            return "顶部导航"
        case .segmentedControl:
            return "分段控件"
        case .avatar:
            return "头像"
        case .tag:
            return "标签"
        case .toggle:
            return "开关"
        case .checkbox:
            return "勾选项"
        case .progress:
            return "进度条"
        case .chart:
            return "图表"
        case .table:
            return "表格"
        case .sidebar:
            return "侧边栏"
        case .dialog:
            return "弹窗"
        case .arrow:
            return "箭头"
        case .aiNote:
            return "AI标注"
        }
    }
}

public enum PrototypingImportIntent: String, Codable {
    case setAsBackground
    case insertAsMovableObject
    case importAsNewPages
    case sendToAI
    case exportOnly
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

    public static let phone = PrototypingCanvasSize(width: 390, height: 844)
    public static let tablet = PrototypingCanvasSize(width: 834, height: 1194)
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
}

public struct PrototypingCanvasElement: Codable, Identifiable, Hashable {
    public var id: String
    public var component: PrototypingComponent
    public var title: String?
    public var frame: PrototypingElementFrame

    public init(
        id: String = UUID().uuidString,
        component: PrototypingComponent,
        title: String? = nil,
        frame: PrototypingElementFrame
    ) {
        self.id = id
        self.component = component
        self.title = title
        self.frame = frame
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

public struct PrototypingDraftDocument: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var revisionID: String
    public var kind: PrototypingDraftKind
    public var template: PrototypingTemplate
    public var device: PrototypingDeviceKind
    public var canvasSize: PrototypingCanvasSize
    public var gridSize: Double
    public var enabledComponents: [PrototypingComponent]
    public var elements: [PrototypingCanvasElement]
    public var note: String

    public init(
        id: String = UUID().uuidString,
        title: String = PrototypingDraftDocument.defaultTitle(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        revisionID: String = UUID().uuidString,
        kind: PrototypingDraftKind = .appPage,
        template: PrototypingTemplate = .blankPhone,
        device: PrototypingDeviceKind = .phone,
        canvasSize: PrototypingCanvasSize = .phone,
        gridSize: Double = 12,
        enabledComponents: [PrototypingComponent] = [.title, .search, .card, .listRow, .bottomNavigation, .aiNote],
        elements: [PrototypingCanvasElement]? = nil,
        note: String = "核心功能"
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.revisionID = revisionID
        self.kind = kind
        self.template = template
        self.device = device
        self.canvasSize = canvasSize
        self.gridSize = gridSize
        self.enabledComponents = enabledComponents
        self.elements = elements ?? PrototypingDraftDocument.defaultElements(for: template, canvasSize: canvasSize)
        self.note = note
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
        case canvasSize
        case gridSize
        case enabledComponents
        case elements
        case note
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        revisionID = try container.decode(String.self, forKey: .revisionID)
        kind = try container.decode(PrototypingDraftKind.self, forKey: .kind)
        template = try container.decode(PrototypingTemplate.self, forKey: .template)
        device = try container.decodeIfPresent(PrototypingDeviceKind.self, forKey: .device)
            ?? (try container.decode(PrototypingCanvasSize.self, forKey: .canvasSize).width > 600 ? .tablet : .phone)
        canvasSize = try container.decode(PrototypingCanvasSize.self, forKey: .canvasSize)
        gridSize = try container.decodeIfPresent(Double.self, forKey: .gridSize) ?? 12
        enabledComponents = try container.decodeIfPresent([PrototypingComponent].self, forKey: .enabledComponents) ?? []
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? "核心功能"
        elements = try container.decodeIfPresent([PrototypingCanvasElement].self, forKey: .elements)
            ?? PrototypingDraftDocument.defaultElements(for: template, canvasSize: canvasSize)
    }

    public static func defaultTitle(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return "未命名 \(formatter.string(from: now))"
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

    public static func defaultElements(
        for template: PrototypingTemplate,
        canvasSize: PrototypingCanvasSize
    ) -> [PrototypingCanvasElement] {
        let size = canvasSize.cgSize
        let isWeb = template.kind == .webPage

        if isWeb {
            switch template {
            case .dashboard:
                return [
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
                return [
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
                return [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 320, y: 90, width: 320, height: 42),
                    element(.subtitle, x: 286, y: 150, width: 388, height: 30),
                    element(.card, x: 92, y: 228, width: 230, height: 250),
                    element(.card, x: 365, y: 208, width: 230, height: 282),
                    element(.card, x: 638, y: 228, width: 230, height: 250),
                    element(.tag, x: 438, y: 232, width: 84, height: 30),
                    element(.button, x: 400, y: 412, width: 160, height: 44),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            default:
                return [
                    element(.topNavigation, x: 40, y: 24, width: 880, height: 52),
                    element(.title, x: 64, y: 70, width: 300, height: 42),
                    element(.subtitle, x: 64, y: 126, width: 340, height: 28),
                    element(.button, x: 64, y: 158, width: 160, height: 48),
                    element(.imagePlaceholder, x: 520, y: 70, width: 330, height: 190),
                    element(.card, x: 64, y: 318, width: 250, height: 120),
                    element(.card, x: 354, y: 318, width: 250, height: 120),
                    element(.card, x: 644, y: 318, width: 250, height: 120),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            }
        }

        let baseElements: [PrototypingCanvasElement]
        switch template {
        case .login:
            baseElements = [
                element(.title, x: 66, y: 154, width: 250, height: 34),
                element(.imagePlaceholder, x: 154, y: 226, width: 82, height: 82),
                element(.input, x: 62, y: 344, width: 266, height: 46),
                element(.input, x: 62, y: 410, width: 266, height: 46),
                element(.button, x: 84, y: 492, width: 222, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .form:
            baseElements = [
                element(.title, x: 44, y: 52, width: 230, height: 34),
                element(.input, x: 44, y: 120, width: 280, height: 46),
                element(.input, x: 44, y: 188, width: 280, height: 46),
                element(.input, x: 44, y: 256, width: 220, height: 46),
                element(.card, x: 44, y: 330, width: 302, height: 126),
                element(.button, x: 44, y: 488, width: 160, height: 48),
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
                element(.button, x: 42, y: 526, width: 160, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .onboarding:
            baseElements = [
                element(.imagePlaceholder, x: 74, y: 98, width: 242, height: 210),
                element(.title, x: 58, y: 360, width: 250, height: 36),
                element(.subtitle, x: 58, y: 420, width: 278, height: 28),
                element(.progress, x: 128, y: 510, width: 134, height: 18),
                element(.button, x: 76, y: 580, width: 238, height: 48),
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
                element(.button, x: 34, y: 514, width: 170, height: 48),
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
                element(.button, x: 34, y: 646, width: 322, height: 52),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .tabletDashboard:
            return [
                element(.sidebar, x: 32, y: 40, width: 156, height: 1114),
                element(.topNavigation, x: 216, y: 40, width: 586, height: 56),
                element(.title, x: 216, y: 132, width: 260, height: 38),
                element(.card, x: 216, y: 206, width: 272, height: 132),
                element(.card, x: 530, y: 206, width: 272, height: 132),
                element(.chart, x: 216, y: 382, width: 586, height: 250),
                element(.table, x: 216, y: 672, width: 586, height: 310),
                element(.aiNote, x: 668, y: 132, width: 112, height: 38)
            ]
        case .blankPhone, .blankTablet, .list, .webHome, .dashboard, .landing, .pricing:
            baseElements = [
                element(.title, x: 34, y: 36, width: 220, height: 34),
                element(.search, x: 34, y: 96, width: 284, height: 44),
                element(.card, x: 34, y: 170, width: 322, height: 92),
                element(.card, x: 34, y: 286, width: 322, height: 92),
                element(.listRow, x: 44, y: 414, width: 292, height: 56),
                element(.button, x: 34, y: 520, width: 170, height: 48),
                element(.bottomNavigation, x: 26, y: 746, width: 338, height: 72),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        }

        guard canvasSize != .phone else { return baseElements }
        return scaledElements(baseElements, from: PrototypingCanvasSize.phone.cgSize, to: canvasSize.cgSize)
    }

    private static func scaledElements(
        _ elements: [PrototypingCanvasElement],
        from sourceSize: CGSize,
        to targetSize: CGSize
    ) -> [PrototypingCanvasElement] {
        guard sourceSize.width > 0, sourceSize.height > 0 else { return elements }
        let scale = min(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        let xOffset = max(0, (targetSize.width - sourceSize.width * scale) / 2)
        let yOffset = max(0, (targetSize.height - sourceSize.height * scale) / 2)

        return elements.map { element in
            var copy = element
            copy.frame = PrototypingElementFrame(
                x: Double(xOffset + CGFloat(element.frame.x) * scale),
                y: Double(yOffset + CGFloat(element.frame.y) * scale),
                width: Double(CGFloat(element.frame.width) * scale),
                height: Double(CGFloat(element.frame.height) * scale)
            )
            return copy
        }
    }

    public static func defaultFrame(
        for component: PrototypingComponent,
        canvasSize: PrototypingCanvasSize
    ) -> PrototypingElementFrame {
        let size = canvasSize.cgSize
        let centerX = max(24, (size.width - defaultSize(for: component).width) / 2)
        let centerY = max(24, (size.height - defaultSize(for: component).height) / 2)
        return PrototypingElementFrame(
            x: Double(centerX),
            y: Double(centerY),
            width: Double(defaultSize(for: component).width),
            height: Double(defaultSize(for: component).height)
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
            return CGSize(width: 112, height: 38)
        }
    }

    private static func element(
        _ component: PrototypingComponent,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) -> PrototypingCanvasElement {
        PrototypingCanvasElement(
            component: component,
            title: component.title,
            frame: PrototypingElementFrame(x: x, y: y, width: width, height: height)
        )
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
