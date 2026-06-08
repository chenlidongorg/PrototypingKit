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
        self.note = note
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
