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

public enum PrototypingTemplate: String, Codable, CaseIterable, Identifiable {
    case blankPhone
    case login
    case list
    case detail
    case form
    case chat
    case webHome
    case dashboard

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blankPhone:
            return "空白手机页"
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
        case .webHome:
            return "Web首页"
        case .dashboard:
            return "后台Dashboard"
        }
    }

    public var kind: PrototypingDraftKind {
        switch self {
        case .webHome, .dashboard:
            return .webPage
        default:
            return .appPage
        }
    }
}

public enum PrototypingComponent: String, Codable, CaseIterable, Identifiable {
    case title
    case button
    case input
    case search
    case card
    case listRow
    case imagePlaceholder
    case bottomNavigation
    case dialog
    case arrow
    case aiNote

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .title:
            return "标题"
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
    public var canvasSize: PrototypingCanvasSize
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
        canvasSize: PrototypingCanvasSize = .phone,
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
        self.canvasSize = canvasSize
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
        case canvasSize
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
        canvasSize = try container.decode(PrototypingCanvasSize.self, forKey: .canvasSize)
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
                    element(.title, x: 190, y: 44, width: 220, height: 34),
                    element(.card, x: 190, y: 104, width: 210, height: 112),
                    element(.card, x: 424, y: 104, width: 210, height: 112),
                    element(.card, x: 658, y: 104, width: 210, height: 112),
                    element(.listRow, x: 206, y: 270, width: 600, height: 54),
                    element(.listRow, x: 206, y: 342, width: 600, height: 54),
                    element(.aiNote, x: size.width - 150, y: 28, width: 112, height: 38)
                ]
            default:
                return [
                    element(.title, x: 64, y: 70, width: 300, height: 42),
                    element(.button, x: 64, y: 158, width: 160, height: 48),
                    element(.imagePlaceholder, x: 520, y: 70, width: 330, height: 190),
                    element(.card, x: 64, y: 318, width: 250, height: 120),
                    element(.card, x: 354, y: 318, width: 250, height: 120),
                    element(.card, x: 644, y: 318, width: 250, height: 120),
                    element(.aiNote, x: size.width - 150, y: 88, width: 112, height: 38)
                ]
            }
        }

        switch template {
        case .login:
            return [
                element(.title, x: 66, y: 154, width: 250, height: 34),
                element(.imagePlaceholder, x: 154, y: 226, width: 82, height: 82),
                element(.input, x: 62, y: 344, width: 266, height: 46),
                element(.input, x: 62, y: 410, width: 266, height: 46),
                element(.button, x: 84, y: 492, width: 222, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .form:
            return [
                element(.title, x: 44, y: 52, width: 230, height: 34),
                element(.input, x: 44, y: 120, width: 280, height: 46),
                element(.input, x: 44, y: 188, width: 280, height: 46),
                element(.input, x: 44, y: 256, width: 220, height: 46),
                element(.card, x: 44, y: 330, width: 302, height: 126),
                element(.button, x: 44, y: 488, width: 160, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .chat:
            return [
                element(.title, x: 44, y: 52, width: 220, height: 34),
                element(.dialog, x: 40, y: 122, width: 230, height: 68),
                element(.dialog, x: 120, y: 218, width: 230, height: 68),
                element(.dialog, x: 40, y: 314, width: 196, height: 68),
                element(.search, x: 34, y: 718, width: 322, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .detail:
            return [
                element(.title, x: 44, y: 52, width: 220, height: 34),
                element(.imagePlaceholder, x: 42, y: 112, width: 306, height: 180),
                element(.card, x: 42, y: 320, width: 306, height: 80),
                element(.listRow, x: 42, y: 430, width: 306, height: 54),
                element(.button, x: 42, y: 526, width: 160, height: 48),
                element(.aiNote, x: 244, y: 92, width: 112, height: 38)
            ]
        case .blankPhone, .list, .webHome, .dashboard:
            return [
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
