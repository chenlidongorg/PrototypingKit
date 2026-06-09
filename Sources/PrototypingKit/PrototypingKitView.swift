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
    @State private var selectedElementIDs: Set<String> = []
    @State private var isMultiSelectionEnabled = false
    @State private var isSidebarExpanded = false
    @State private var inspectorExpandedOverride: Bool?
    @State private var activeLibrary: PrototypingLibrarySheet?
    @AppStorage("PrototypingKit.recentTemplateIDs") private var recentTemplateIDs = ""
    @AppStorage("PrototypingKit.recentComponentIDs") private var recentComponentIDs = ""
    @AppStorage("PrototypingKit.showTemplateSection.v2") private var isTemplateSectionVisible = true
    @AppStorage("PrototypingKit.showGridSection.v2") private var isGridSectionVisible = true
    @AppStorage("PrototypingKit.stageZoomMode") private var stageZoomMode = "fit"
    @AppStorage("PrototypingKit.stageZoom") private var manualStageZoom = 1.0

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

            HStack(spacing: 22) {
                Button(action: createDraft) {
                    Label("新建", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(PrototypingKitColors.ink)
                }

                HStack(spacing: 12) {
                    Button(action: insertIntoHost) {
                        HStack(spacing: 6) {
                            InsertCanvasIcon()
                                .frame(width: 18, height: 18)
                            Text("放进画布")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(PrototypingKitColors.ink)
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
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var content: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 900
            let inspectorIsExpanded = inspectorExpandedOverride ?? isWide
            let inspectorWidth = min(max(proxy.size.width * 0.28, 250), 340)
            let stageWidth = inspectorIsExpanded && isWide ? proxy.size.width - inspectorWidth - 1 : proxy.size.width
            let stageSize = CGSize(width: max(1, stageWidth), height: max(1, proxy.size.height))

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    stageArea(availableSize: stageSize)

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

    private func stageArea(availableSize: CGSize) -> some View {
        let canvasSize = store.currentDocument.canvasSize.cgSize
        let fitScale = stageFitScale(availableSize: availableSize)
        let scale = stageZoomMode == "fit" ? fitScale : clampStageZoom(CGFloat(manualStageZoom))
        let scaledCanvasSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
        let contentSize = stageContentSize(
            availableSize: availableSize,
            canvasSize: canvasSize,
            scale: scale
        )
        let centerResetID = stageCenterResetID(scale: scale, canvasSize: canvasSize, availableSize: availableSize)

        return ZStack(alignment: .bottom) {
            ScrollViewReader { scrollProxy in
                ScrollView([.vertical, .horizontal], showsIndicators: true) {
                    ZStack {
                        PrototypingEditableDraftCanvas(
                            document: store.currentDocument,
                            selectedElementIDs: selectedElementIDs,
                            isMultiSelectionEnabled: isMultiSelectionEnabled,
                            onSelect: selectElement,
                            onToggleSelection: toggleElementSelection,
                            onDeselect: deselectElement,
                            onMove: { id, frame, persist in
                                let snappedFrame = store.snappedFrame(id: id, proposedFrame: frame)
                                store.moveElement(id: id, to: snappedFrame, persist: persist)
                            },
                            onMoveElements: { framesByID, persist in
                                store.moveElements(framesByID, persist: persist)
                            },
                            onUpdateAnnotationArrow: { id, anchor, target, persist in
                                store.updateAnnotationArrow(id: id, anchor: anchor, target: target, persist: persist)
                            },
                            onUpdateAnnotationText: { id, text, persist in
                                store.updateAnnotationText(id: id, text: text, persist: persist)
                            },
                            onDelete: deleteElement
                        )
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .scaleEffect(scale, anchor: .center)
                        .frame(width: scaledCanvasSize.width, height: scaledCanvasSize.height)

                        Color.clear
                            .frame(width: 1, height: 1)
                            .id(stageCenterAnchorID)
                    }
                    .frame(width: contentSize.width, height: contentSize.height, alignment: .center)
                }
                .background(PrototypingKitColors.canvasSurface)
                .onAppear {
                    centerStage(scrollProxy, animated: false)
                }
                .onChange(of: centerResetID) { _ in
                    centerStage(scrollProxy, animated: false)
                }
            }

            stageZoomControls(scale: scale)
                .padding(.bottom, 18)
        }
        .frame(width: availableSize.width, height: availableSize.height)
    }

    private func stageZoomControls(scale: CGFloat) -> some View {
        HStack(spacing: 6) {
            Button(action: {
                setManualStageZoom(scale - 0.1)
            }) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                stageZoomMode = "fit"
            }) {
                Text("\(Int((scale * 100).rounded()))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(stageZoomMode == "fit" ? PrototypingKitColors.accent : PrototypingKitColors.secondaryInk)
                    .frame(width: 46, height: 30)
                    .background(stageZoomMode == "fit" ? PrototypingKitColors.accent.opacity(0.10) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                setManualStageZoom(scale + 0.1)
            }) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .foregroundColor(PrototypingKitColors.ink)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(PrototypingKitColors.panel.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PrototypingKitColors.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private func stageFitScale(availableSize: CGSize) -> CGFloat {
        let canvasSize = store.currentDocument.canvasSize.cgSize
        guard canvasSize.width > 0, canvasSize.height > 0 else { return 1 }

        let margin = stageMargin
        let availableWidth = max(120, availableSize.width - margin * 2)
        let availableHeight = max(120, availableSize.height - margin * 2)
        let scale = min(availableWidth / canvasSize.width, availableHeight / canvasSize.height)
        return clampStageZoom(scale)
    }

    private func stageContentSize(
        availableSize: CGSize,
        canvasSize: CGSize,
        scale: CGFloat
    ) -> CGSize {
        let width = max(availableSize.width, canvasSize.width * scale + stageMargin * 2)
        let height = max(availableSize.height, canvasSize.height * scale + stageMargin * 2)
        return CGSize(width: width, height: height)
    }

    private func stageCenterResetID(
        scale: CGFloat,
        canvasSize: CGSize,
        availableSize: CGSize
    ) -> String {
        [
            store.currentDocument.activeBoardID,
            "\(Int(canvasSize.width))x\(Int(canvasSize.height))",
            "\(Int((scale * 100).rounded()))",
            "\(Int(availableSize.width))x\(Int(availableSize.height))"
        ].joined(separator: "-")
    }

    private var stageMargin: CGFloat {
        44
    }

    private var stageCenterAnchorID: String {
        "prototyping-stage-center-anchor"
    }

    private func centerStage(_ scrollProxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.18)) {
                    scrollProxy.scrollTo(stageCenterAnchorID, anchor: .center)
                }
            } else {
                scrollProxy.scrollTo(stageCenterAnchorID, anchor: .center)
            }
        }
    }

    private func setManualStageZoom(_ scale: CGFloat) {
        stageZoomMode = "manual"
        manualStageZoom = Double(clampStageZoom(scale))
    }

    private func clampStageZoom(_ scale: CGFloat) -> CGFloat {
        min(2.0, max(0.18, scale))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近草稿")
                    .font(.headline)
                    .foregroundColor(PrototypingKitColors.ink)
                Spacer()
                Button(action: { isSidebarExpanded = false }) {
                    Image(systemName: "chevron.left")
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

                HStack {
                    ChoiceChip(title: "多选", isSelected: isMultiSelectionEnabled) {
                        toggleMultiSelection()
                    }
                    .frame(width: 78)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("草稿类型")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                        ForEach(PrototypingDraftKind.allCases) { kind in
                            ChoiceChip(title: kind.title, isSelected: store.currentDocument.kind == kind) {
                                selectedElementIDs = []
                                store.applyKind(kind)
                            }
                        }
                    }
                }

                if store.currentDocument.kind != .webPage {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("设备")

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(PrototypingDeviceKind.allCases) { device in
                                ChoiceChip(title: device.title, isSelected: store.currentDocument.device == device) {
                                    selectedElementIDs = []
                                    store.applyDevice(device)
                                }
                            }
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(PrototypingDeviceOrientation.allCases) { orientation in
                                ChoiceChip(title: orientation.title, isSelected: store.currentDocument.orientation == orientation) {
                                    selectedElementIDs = []
                                    store.applyOrientation(orientation)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Button(action: {
                            isTemplateSectionVisible.toggle()
                        }) {
                            HStack {
                                Text("模板")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(PrototypingKitColors.secondaryInk)
                                Image(systemName: isTemplateSectionVisible ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PrototypingKitColors.subtleInk)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        Button(action: { activeLibrary = .templates }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 28, height: 28)
                        }
                        .accessibilityLabel(Text("更多模板"))
                        .buttonStyle(PlainButtonStyle())
                    }

                    if isTemplateSectionVisible {
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
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 28, height: 28)
                        }
                        .accessibilityLabel(Text("更多组件"))
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

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Button(action: {
                            isGridSectionVisible.toggle()
                        }) {
                            HStack {
                                Text("网格")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(PrototypingKitColors.secondaryInk)
                                Image(systemName: isGridSectionVisible ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PrototypingKitColors.subtleInk)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }

                    if isGridSectionVisible {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                            ForEach(gridSizeOptions, id: \.self) { gridSize in
                                ChoiceChip(
                                    title: "\(Int(gridSize))",
                                    isSelected: Int(store.currentDocument.gridSize) == Int(gridSize)
                                ) {
                                    selectedElementIDs = []
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
                        selectTemplateFromLibrary(template)
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
        Array(uniqueTemplates(recentTemplates + recommendedTemplates).prefix(2))
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
        Array(uniqueComponents(recentComponents + recommendedComponents).prefix(8))
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

    private var selectedElement: PrototypingCanvasElement? {
        guard let selectedElementID = singleSelectedElementID else { return nil }
        return store.currentDocument.elements.first { $0.id == selectedElementID }
    }

    private var singleSelectedElementID: String? {
        selectedElementIDs.count == 1 ? selectedElementIDs.first : nil
    }

    private func selectElement(_ id: String) {
        selectedElementIDs = [id]
        store.bringElementToFront(id: id)
    }

    private func toggleElementSelection(_ id: String) {
        if selectedElementIDs.contains(id) {
            selectedElementIDs.remove(id)
        } else {
            selectedElementIDs.insert(id)
            store.bringElementToFront(id: id)
        }
    }

    private func deselectElement() {
        selectedElementIDs = []
    }

    private func toggleMultiSelection() {
        isMultiSelectionEnabled.toggle()
        if !isMultiSelectionEnabled {
            selectedElementIDs = []
        }
    }

    private func createDraft() {
        selectedElementIDs = []
        store.createNewDraft()
        isSidebarExpanded = false
    }

    private func openDraft(id: String) {
        selectedElementIDs = []
        store.openDraft(id: id)
        isSidebarExpanded = false
    }

    private func applyTemplateFromUI(_ template: PrototypingTemplate) {
        selectedElementIDs = []
        if store.currentDocument.elements.isEmpty {
            commitTemplate(template)
        } else {
            activeAlert = .applyTemplate(template)
        }
    }

    private func selectTemplateFromLibrary(_ template: PrototypingTemplate) {
        activeLibrary = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            applyTemplateFromUI(template)
        }
    }

    private func commitTemplate(_ template: PrototypingTemplate) {
        rememberTemplate(template)
        store.applyTemplate(template)
    }

    private func addComponentFromUI(_ component: PrototypingComponent) {
        rememberComponent(component)
        store.addComponent(component)
        selectedElementIDs = store.currentDocument.elements.last.map { [$0.id] } ?? []
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
        selectedElementIDs.remove(id)
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

private struct InsertCanvasIcon: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let strokeWidth = max(1.5, size * 0.11)
            let handleSize = max(3, size * 0.18)
            let inset = handleSize / 2
            let rect = CGRect(
                x: inset,
                y: inset,
                width: size - inset * 2,
                height: size - inset * 2
            )

            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .stroke(PrototypingKitColors.ink, lineWidth: strokeWidth)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                RoundedRectangle(cornerRadius: size * 0.10)
                    .stroke(PrototypingKitColors.ink.opacity(0.72), lineWidth: strokeWidth)
                    .frame(width: rect.width * 0.52, height: rect.height * 0.52)
                    .position(x: rect.midX + size * 0.08, y: rect.midY)

                ForEach(Array(handlePoints(in: rect).enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(PrototypingKitColors.ink)
                        .frame(width: handleSize, height: handleSize)
                        .position(point)
                }
            }
            .frame(width: size, height: size)
        }
    }

    private func handlePoints(in rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
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
