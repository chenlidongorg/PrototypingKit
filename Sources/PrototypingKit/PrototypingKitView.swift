import SwiftUI

private enum PrototypingKitColors {
    static let surface = Color(red: 0.98, green: 0.985, blue: 0.99)
    static let panel = Color.white
    static let canvasSurface = Color(red: 0.965, green: 0.972, blue: 0.98)
    static let controlSurface = Color(red: 0.94, green: 0.965, blue: 0.99)
    static let controlSurfaceMuted = Color(red: 0.965, green: 0.968, blue: 0.972)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let secondaryInk = Color(red: 0.44, green: 0.49, blue: 0.56)
    static let subtleInk = Color(red: 0.62, green: 0.66, blue: 0.72)
    static let accent = Color(red: 0.02, green: 0.48, blue: 0.98)
    static let separator = Color.black.opacity(0.12)
}

private enum PrototypingLibrarySheet: String, Identifiable {
    case templates
    case components

    var id: String { rawValue }
}

private enum PrototypingKitAlert: Identifiable {
    case message(String)
    case applyTemplate(PrototypingTemplate)

    var id: String {
        switch self {
        case .message(let message):
            return "message-\(message)"
        case .applyTemplate(let template):
            return "template-\(template.rawValue)"
        }
    }
}

@available(iOS 14.0, macCatalyst 14.0, *)
public struct PrototypingKitView: View {
    @ObservedObject private var store: PrototypingDraftStore
    private let onExport: (PrototypingExportResult) -> Void
    private let onClose: () -> Void

    @State private var activeAlert: PrototypingKitAlert?
    @State private var selectedElementID: String?
    @State private var isSidebarExpanded = false
    @State private var inspectorExpandedOverride: Bool?
    @State private var activeLibrary: PrototypingLibrarySheet?
    @AppStorage("PrototypingKit.recentTemplateIDs") private var recentTemplateIDs = ""
    @AppStorage("PrototypingKit.recentComponentIDs") private var recentComponentIDs = ""
    @AppStorage("PrototypingKit.showTemplateSection") private var isTemplateSectionVisible = false
    @AppStorage("PrototypingKit.showGridSection") private var isGridSectionVisible = false

    @MainActor
    public init(
        store: PrototypingDraftStore? = nil,
        onExport: @escaping (PrototypingExportResult) -> Void,
        onClose: @escaping () -> Void = {}
    ) {
        self.store = store ?? PrototypingDraftStore()
        self.onExport = onExport
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .background(PrototypingKitColors.surface)
        .foregroundColor(PrototypingKitColors.ink)
        .accentColor(PrototypingKitColors.accent)
        .environment(\.colorScheme, .light)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .message(let message):
                return Alert(
                    title: Text("原型设计测试版"),
                    message: Text(message),
                    dismissButton: .default(Text("好"))
                )
            case .applyTemplate(let template):
                return Alert(
                    title: Text("套用模板？"),
                    message: Text("会替换当前设备和方向里的组件。已做好的其它设备状态会保留。"),
                    primaryButton: .destructive(Text("套用")) {
                        commitTemplate(template)
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PrototypingKitColors.secondaryInk)
            }
            .buttonStyle(PlainButtonStyle())

            TextField("标题", text: titleBinding)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(PrototypingKitColors.ink)
                .textFieldStyle(PlainTextFieldStyle())

            HStack(spacing: 8) {
                Button(action: createDraft) {
                    Label("新建", systemImage: "plus")
                }
            }
            .padding(.horizontal, 4)

            HStack(spacing: 8) {
                Button(action: insertIntoHost) {
                    Label("插入画布", systemImage: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(PrototypingKitColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())

                Menu {
                    Button(action: { exportPDF(recommendedIntent: .savePDF) }) {
                        Label("保存 PDF", systemImage: "doc.badge.plus")
                    }
                    Button(action: { exportPDF(recommendedIntent: .sharePDF) }) {
                        Label("分享 PDF", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("导出", systemImage: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(PrototypingKitColors.ink)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var content: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 900
            let inspectorIsExpanded = inspectorExpandedOverride ?? isWide
            let inspectorWidth = min(max(proxy.size.width * 0.28, 250), 340)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ScrollView([.vertical, .horizontal], showsIndicators: true) {
                        PrototypingEditableDraftCanvas(
                            document: store.currentDocument,
                            selectedElementID: selectedElementID,
                            onSelect: selectElement,
                            onDeselect: deselectElement,
                            onMove: { id, frame, persist in
                                let snappedFrame = store.snappedFrame(id: id, proposedFrame: frame)
                                store.moveElement(id: id, to: snappedFrame, persist: persist)
                            },
                            onUpdateAnnotationArrow: { id, anchor, target, persist in
                                store.updateAnnotationArrow(id: id, anchor: anchor, target: target, persist: persist)
                            },
                            onDelete: deleteElement
                        )
                            .frame(
                                width: store.currentDocument.canvasSize.cgSize.width,
                                height: store.currentDocument.canvasSize.cgSize.height
                            )
                            .padding(28)
                    }
                    .background(PrototypingKitColors.canvasSurface)

                    if inspectorIsExpanded && isWide {
                        Divider()

                        inspector
                            .frame(width: inspectorWidth)
                    }
                }

                if isSidebarExpanded {
                    Color.black.opacity(0.08)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isSidebarExpanded = false
                        }

                    sidebar
                        .frame(width: min(max(proxy.size.width * 0.24, 230), 300))
                        .frame(maxHeight: .infinity)
                        .background(PrototypingKitColors.panel)
                        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 10, y: 0)
                        .transition(.move(edge: .leading))
                } else {
                    sidebarLauncher
                        .padding(.leading, 14)
                        .padding(.top, 14)
                }

                if inspectorIsExpanded && !isWide {
                    Color.black.opacity(0.08)
                        .ignoresSafeArea()
                        .onTapGesture {
                            inspectorExpandedOverride = false
                        }

                    inspector
                        .frame(width: inspectorWidth)
                        .frame(maxHeight: .infinity)
                        .background(PrototypingKitColors.panel)
                        .shadow(color: Color.black.opacity(0.16), radius: 18, x: -10, y: 0)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.move(edge: .trailing))
                } else if !inspectorIsExpanded {
                    inspectorLauncher
                        .padding(.trailing, 14)
                        .padding(.top, 14)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近草稿")
                    .font(.headline)
                    .foregroundColor(PrototypingKitColors.ink)
                Spacer()
                Button(action: createDraft) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(PrototypingKitColors.accent)
                }
                Button(action: { isSidebarExpanded = false }) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(PrototypingKitColors.secondaryInk)
                }
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.records) { record in
                        DraftRecordRow(
                            record: record,
                            isSelected: record.id == store.currentDocument.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openDraft(id: record.id)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var sidebarLauncher: some View {
        Button(action: { isSidebarExpanded = true }) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(store.records.count)")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(PrototypingKitColors.accent)
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(PrototypingKitColors.panel.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PrototypingKitColors.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var inspectorLauncher: some View {
        Button(action: { inspectorExpandedOverride = true }) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                Text("工具")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(PrototypingKitColors.accent)
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(PrototypingKitColors.panel.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PrototypingKitColors.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    sectionTitle("操作工具")
                    Spacer()
                    Button(action: { inspectorExpandedOverride = false }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(PrototypingKitColors.secondaryInk)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("草稿类型")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                        ForEach(PrototypingDraftKind.allCases) { kind in
                            ChoiceChip(title: kind.title, isSelected: store.currentDocument.kind == kind) {
                                selectedElementID = nil
                                store.applyKind(kind)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle(store.currentDocument.kind == .webPage ? "画布" : "设备")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                        if store.currentDocument.kind == .webPage {
                            ChoiceChip(title: "Web画布", isSelected: true) {}
                        } else {
                            ForEach(PrototypingDeviceKind.allCases) { device in
                                ChoiceChip(title: device.title, isSelected: store.currentDocument.device == device) {
                                    selectedElementID = nil
                                    store.applyDevice(device)
                                }
                            }
                        }
                    }

                    if store.currentDocument.kind != .webPage {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(PrototypingDeviceOrientation.allCases) { orientation in
                                ChoiceChip(title: orientation.title, isSelected: store.currentDocument.orientation == orientation) {
                                    selectedElementID = nil
                                    store.applyOrientation(orientation)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    DisclosureHeader(title: "模板", isExpanded: isTemplateSectionVisible) {
                        isTemplateSectionVisible.toggle()
                    }

                    if isTemplateSectionVisible {
                        HStack {
                            Spacer()
                            Button(action: { activeLibrary = .templates }) {
                                Label("更多", systemImage: "ellipsis.circle")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                            ForEach(quickTemplates) { template in
                                TemplateCard(template: template, isSelected: store.currentDocument.template == template) {
                                    applyTemplateFromUI(template)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionTitle("常用组件")
                        Spacer()
                        Button(action: { activeLibrary = .components }) {
                            Label("更多", systemImage: "ellipsis.circle")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                        ForEach(quickComponents) { component in
                            ChoiceChip(
                                title: component.title,
                                isSelected: selectedElement?.component == component
                            ) {
                                addComponentFromUI(component)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("注释")
                    TextField("例如：核心功能", text: noteBinding)
                        .font(.system(size: 14))
                        .foregroundColor(PrototypingKitColors.ink)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(PrototypingKitColors.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PrototypingKitColors.separator, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 10) {
                    DisclosureHeader(title: "网格", isExpanded: isGridSectionVisible) {
                        isGridSectionVisible.toggle()
                    }

                    if isGridSectionVisible {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                            ForEach(gridSizeOptions, id: \.self) { gridSize in
                                ChoiceChip(
                                    title: "\(Int(gridSize))",
                                    isSelected: Int(store.currentDocument.gridSize) == Int(gridSize)
                                ) {
                                    selectedElementID = nil
                                    store.updateGridSize(gridSize)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .sheet(item: $activeLibrary) { sheet in
            switch sheet {
            case .templates:
                TemplateLibraryView(
                    templates: availableTemplates,
                    selectedTemplate: store.currentDocument.template,
                    onClose: { activeLibrary = nil },
                    onSelect: { template in
                        activeLibrary = nil
                        applyTemplateFromUI(template)
                    }
                )
            case .components:
                ComponentLibraryView(
                    components: PrototypingComponent.allCases,
                    selectedComponent: selectedElement?.component,
                    onClose: { activeLibrary = nil },
                    onSelect: { component in
                        activeLibrary = nil
                        addComponentFromUI(component)
                    }
                )
            }
        }
    }

    private var availableTemplates: [PrototypingTemplate] {
        switch store.currentDocument.kind {
        case .webPage:
            return [.blank, .webHome, .landing, .pricing, .dashboard]
        case .flowNote, .deviceShowcase, .appPage:
            return [.blank, .list, .detail, .form, .login, .chat, .onboarding, .profile, .settings, .checkout, .tabletDashboard]
        }
    }

    private var quickTemplates: [PrototypingTemplate] {
        Array(uniqueTemplates(recentTemplates + recommendedTemplates).prefix(4))
    }

    private var recommendedTemplates: [PrototypingTemplate] {
        switch store.currentDocument.kind {
        case .webPage:
            return [.blank, .webHome, .landing, .pricing]
        case .deviceShowcase, .flowNote, .appPage:
            return store.currentDocument.device == .tablet
                ? [.blank, .tabletDashboard, .list, .profile]
                : [.blank, .list, .detail, .form]
        }
    }

    private var recentTemplates: [PrototypingTemplate] {
        recentTemplateIDs
            .split(separator: ",")
            .compactMap { PrototypingTemplate(rawValue: String($0)) }
            .filter { availableTemplates.contains($0) }
    }

    private var quickComponents: [PrototypingComponent] {
        Array(uniqueComponents(recentComponents + recommendedComponents).prefix(9))
    }

    private var recommendedComponents: [PrototypingComponent] {
        if store.currentDocument.kind == .webPage {
            return [.title, .subtitle, .button, .topNavigation, .card, .chart, .table, .tag, .aiNote]
        }

        return [.title, .button, .input, .search, .card, .listRow, .imagePlaceholder, .bottomNavigation, .aiNote]
    }

    private var recentComponents: [PrototypingComponent] {
        recentComponentIDs
            .split(separator: ",")
            .compactMap { PrototypingComponent(rawValue: String($0)) }
    }

    private var gridSizeOptions: [Double] {
        [8, 12, 16, 24]
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { store.currentDocument.title },
            set: { value in
                store.update { document in
                    document.title = value.isEmpty ? PrototypingDraftDocument.defaultTitle() : value
                }
            }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { store.currentDocument.note },
            set: { value in
                store.update { document in
                    document.note = value
                }
            }
        )
    }

    private var selectedElement: PrototypingCanvasElement? {
        guard let selectedElementID else { return nil }
        return store.currentDocument.elements.first { $0.id == selectedElementID }
    }

    private func selectElement(_ id: String) {
        selectedElementID = id
        store.bringElementToFront(id: id)
    }

    private func deselectElement() {
        selectedElementID = nil
    }

    private func createDraft() {
        selectedElementID = nil
        store.createNewDraft()
        isSidebarExpanded = false
    }

    private func openDraft(id: String) {
        selectedElementID = nil
        store.openDraft(id: id)
        isSidebarExpanded = false
    }

    private func applyTemplateFromUI(_ template: PrototypingTemplate) {
        selectedElementID = nil
        if store.currentDocument.elements.isEmpty {
            commitTemplate(template)
        } else {
            activeAlert = .applyTemplate(template)
        }
    }

    private func commitTemplate(_ template: PrototypingTemplate) {
        rememberTemplate(template)
        store.applyTemplate(template)
    }

    private func addComponentFromUI(_ component: PrototypingComponent) {
        rememberComponent(component)
        store.addComponent(component)
        selectedElementID = store.currentDocument.elements.last?.id
    }

    private func rememberTemplate(_ template: PrototypingTemplate) {
        recentTemplateIDs = prepending(template.rawValue, to: recentTemplateIDs, limit: 8)
    }

    private func rememberComponent(_ component: PrototypingComponent) {
        recentComponentIDs = prepending(component.rawValue, to: recentComponentIDs, limit: 12)
    }

    private func prepending(_ value: String, to rawValue: String, limit: Int) -> String {
        let values = [value] + rawValue.split(separator: ",").map(String.init).filter { $0 != value }
        return values.prefix(limit).joined(separator: ",")
    }

    private func uniqueTemplates(_ templates: [PrototypingTemplate]) -> [PrototypingTemplate] {
        var result: [PrototypingTemplate] = []
        for template in templates where availableTemplates.contains(template) && !result.contains(template) {
            result.append(template)
        }
        return result
    }

    private func uniqueComponents(_ components: [PrototypingComponent]) -> [PrototypingComponent] {
        var result: [PrototypingComponent] = []
        for component in components where !result.contains(component) {
            result.append(component)
        }
        return result
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(PrototypingKitColors.secondaryInk)
    }

    private func insertIntoHost() {
        onExport(store.exportImage(recommendedIntent: .setAsBackground))
    }

    private func exportPDF(recommendedIntent: PrototypingImportIntent) {
        do {
            let result = try store.exportPDF(recommendedIntent: recommendedIntent)
            onExport(result)
        } catch {
            activeAlert = .message("PDF 导出失败：\(error.localizedDescription)")
        }
    }

    private func deleteElement(_ id: String) {
        store.deleteElement(id: id)
        self.selectedElementID = nil
    }
}

@available(iOS 14.0, macCatalyst 14.0, *)
private struct TemplateLibraryView: View {
    let templates: [PrototypingTemplate]
    let selectedTemplate: PrototypingTemplate
    let onClose: () -> Void
    let onSelect: (PrototypingTemplate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            libraryHeader(title: "模板", onClose: onClose)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 12)], spacing: 12) {
                    ForEach(templates) { template in
                        TemplateCard(template: template, isSelected: selectedTemplate == template) {
                            onSelect(template)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(PrototypingKitColors.surface)
        .environment(\.colorScheme, .light)
    }
}

@available(iOS 14.0, macCatalyst 14.0, *)
private struct ComponentLibraryView: View {
    let components: [PrototypingComponent]
    let selectedComponent: PrototypingComponent?
    let onClose: () -> Void
    let onSelect: (PrototypingComponent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            libraryHeader(title: "组件", onClose: onClose)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 98), spacing: 8)], spacing: 8) {
                    ForEach(components) { component in
                        ChoiceChip(title: component.title, isSelected: selectedComponent == component) {
                            onSelect(component)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(PrototypingKitColors.surface)
        .environment(\.colorScheme, .light)
    }
}

private func libraryHeader(title: String, onClose: @escaping () -> Void) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(PrototypingKitColors.ink)
        Spacer()
        Button(action: onClose) {
            Text("完成")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(PrototypingKitColors.accent)
        }
        .buttonStyle(PlainButtonStyle())
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(PrototypingKitColors.panel)
    .overlay(Rectangle().fill(PrototypingKitColors.separator).frame(height: 1), alignment: .bottom)
}

private struct DisclosureHeader: View {
    let title: String
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PrototypingKitColors.secondaryInk)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PrototypingKitColors.subtleInk)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct DraftRecordRow: View {
    let record: PrototypingDraftRecord
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? PrototypingKitColors.accent.opacity(0.16) : PrototypingKitColors.controlSurfaceMuted)
                .frame(width: 44, height: 52)
                .overlay(
                    Image(systemName: "rectangle.3.group")
                        .foregroundColor(isSelected ? PrototypingKitColors.accent : PrototypingKitColors.subtleInk)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PrototypingKitColors.ink)
                    .lineLimit(1)
                Text(formattedUpdatedAt)
                    .font(.caption)
                    .foregroundColor(PrototypingKitColors.secondaryInk)
            }

            Spacer()
        }
        .padding(8)
        .background(isSelected ? PrototypingKitColors.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var formattedUpdatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: record.updatedAt)
    }
}

private struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? PrototypingKitColors.accent : PrototypingKitColors.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? PrototypingKitColors.accent.opacity(0.12) : PrototypingKitColors.controlSurfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct TemplateCard: View {
    let template: PrototypingTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TemplateThumbnail(template: template)
                    .frame(height: 78)
                Text(template.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? PrototypingKitColors.accent : PrototypingKitColors.ink)
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? PrototypingKitColors.accent.opacity(0.12) : PrototypingKitColors.controlSurfaceMuted)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? PrototypingKitColors.accent.opacity(0.55) : PrototypingKitColors.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct TemplateThumbnail: View {
    let template: PrototypingTemplate

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.22))
                .frame(width: 44, height: 6)

            if template == .blank {
                Spacer(minLength: 0)
            } else if template == .login {
                Circle().stroke(Color.black.opacity(0.18), lineWidth: 1).frame(width: 22, height: 22)
                line(width: 54)
                line(width: 54)
            } else if template == .dashboard {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.10)).frame(width: 18)
                    VStack(spacing: 5) {
                        HStack(spacing: 5) {
                            miniCard
                            miniCard
                        }
                        line(width: 52)
                        line(width: 52)
                    }
                }
            } else {
                line(width: 62)
                line(width: 72)
                line(width: 58)
                line(width: 68)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    private var miniCard: some View {
        RoundedRectangle(cornerRadius: 3)
            .stroke(Color.black.opacity(0.14), lineWidth: 1)
            .frame(width: 24, height: 18)
    }

    private func line(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.black.opacity(0.14))
            .frame(width: width, height: 5)
    }
}
