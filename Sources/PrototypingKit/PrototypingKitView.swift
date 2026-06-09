import SwiftUI
import UIKit

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
    case help
    case applyTemplate(PrototypingTemplate)

    var id: String {
        switch self {
        case .message(let message):
            return "message-\(message)"
        case .help:
            return "help"
        case .applyTemplate(let template):
            return "template-\(template.rawValue)"
        }
    }
}

private struct TemplatePreviewContext {
    let kind: PrototypingDraftKind
    let device: PrototypingDeviceKind
    let orientation: PrototypingDeviceOrientation
    let canvasSize: PrototypingCanvasSize
}

private struct PrototypingComponentItem: Identifiable, Hashable {
    let component: PrototypingComponent
    let buttonStyle: PrototypingButtonStyle?

    var id: String {
        if let buttonStyle {
            return "button.\(buttonStyle.rawValue)"
        }
        return component.rawValue
    }

    var title: String {
        guard component == .button, let buttonStyle else {
            return component.title
        }
        return PrototypingL10n.text("component.button_variant_format", PrototypingComponent.button.title, buttonStyle.componentTitle)
    }

    static func component(_ component: PrototypingComponent) -> PrototypingComponentItem {
        PrototypingComponentItem(component: component, buttonStyle: nil)
    }

    static func button(_ style: PrototypingButtonStyle) -> PrototypingComponentItem {
        PrototypingComponentItem(component: .button, buttonStyle: style)
    }
}

private extension PrototypingButtonStyle {
    var componentTitle: String {
        switch self {
        case .primary:
            return PrototypingL10n.text("button_variant.rounded")
        case .secondary:
            return PrototypingL10n.text("button_variant.dark")
        case .outline:
            return PrototypingL10n.text("button_variant.outline")
        case .soft:
            return PrototypingL10n.text("button_variant.soft")
        case .ghost:
            return PrototypingL10n.text("button_variant.text")
        case .pill:
            return PrototypingL10n.text("button_variant.pill")
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
                    title: Text(PrototypingL10n.text("app.title")),
                    message: Text(message),
                    dismissButton: .default(Text(PrototypingL10n.text("action.ok")))
                )
            case .help:
                return Alert(
                    title: Text(PrototypingL10n.text("help.title")),
                    message: Text(PrototypingL10n.text("help.message")),
                    dismissButton: .default(Text(PrototypingL10n.text("action.ok")))
                )
            case .applyTemplate(let template):
                return Alert(
                    title: Text(PrototypingL10n.text("alert.apply_template.title")),
                    message: Text(PrototypingL10n.text("alert.apply_template.message")),
                    primaryButton: .destructive(Text(PrototypingL10n.text("action.apply"))) {
                        commitTemplate(template)
                    },
                    secondaryButton: .cancel(Text(PrototypingL10n.text("action.cancel")))
                )
            }
        }
    }

    private var toolbar: some View {
        GeometryReader { proxy in
            toolbarContent(isCompact: proxy.size.width < 560)
        }
        .frame(height: 58)
    }

    private func toolbarContent(isCompact: Bool) -> some View {
        HStack(spacing: isCompact ? 8 : 10) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PrototypingKitColors.secondaryInk)
                    .frame(width: 32, height: 34)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(PrototypingL10n.text("action.cancel"))

            toolbarTitleField(isCompact: isCompact)

            HStack(spacing: isCompact ? 12 : 22) {
                Button(action: createDraft) {
                    toolbarSystemActionLabel(
                        title: PrototypingL10n.text("toolbar.new"),
                        systemImage: "plus",
                        isCompact: isCompact
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(PrototypingL10n.text("toolbar.new"))

                HStack(spacing: isCompact ? 12 : 12) {
                    Button(action: insertIntoHost) {
                        toolbarInsertCanvasLabel(isCompact: isCompact)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(PrototypingL10n.text("toolbar.insert_canvas"))

                    Menu {
                        Button(action: { exportPDF(recommendedIntent: .savePDF) }) {
                            Label(PrototypingL10n.text("export.save_pdf"), systemImage: "doc.badge.plus")
                        }
                        Button(action: { exportPDF(recommendedIntent: .sharePDF) }) {
                            Label(PrototypingL10n.text("export.share_pdf"), systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        toolbarSystemActionLabel(
                            title: PrototypingL10n.text("toolbar.export"),
                            systemImage: "square.and.arrow.up",
                            isCompact: isCompact
                        )
                    }
                    .accessibilityLabel(PrototypingL10n.text("toolbar.export"))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, isCompact ? 10 : 18)
        .padding(.vertical, 10)
    }

    private func toolbarTitleField(isCompact: Bool) -> some View {
        let titleWidth = max(
            isCompact ? 150 : 220,
            CGFloat(store.currentDocument.title.count) * (isCompact ? 16 : 18) + 30
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            TextField(PrototypingL10n.text("field.title"), text: titleBinding)
                .font(.system(size: isCompact ? 19 : 20, weight: .semibold))
                .foregroundColor(PrototypingKitColors.ink)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(width: titleWidth, alignment: .leading)
        }
        .frame(height: 34)
        .clipped()
        .layoutPriority(1)
    }

    private func toolbarSystemActionLabel(title: String, systemImage: String, isCompact: Bool) -> some View {
        Group {
            if isCompact {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 34, height: 34)
            } else {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .foregroundColor(PrototypingKitColors.ink)
    }

    private func toolbarInsertCanvasLabel(isCompact: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "square.on.square.squareshape.controlhandles")
                .font(.system(size: isCompact ? 22 : 16, weight: .semibold))
                .frame(width: isCompact ? 24 : 18, height: isCompact ? 24 : 18)
            if !isCompact {
                Text(PrototypingL10n.text("toolbar.insert_canvas"))
            }
        }
        .frame(width: isCompact ? 34 : nil, height: 34)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(PrototypingKitColors.ink)
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
                Text(PrototypingL10n.text("sidebar.recent_drafts"))
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
                            isSelected: record.id == store.currentDocument.id,
                            onOpen: {
                                openDraft(id: record.id)
                            },
                            onRename: { title in
                                store.renameDraft(id: record.id, title: title)
                            }
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var sidebarLauncher: some View {
        Button(action: { isSidebarExpanded = true }) {
            Image(systemName: "list.bullet")
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 42, height: 34)
            .foregroundColor(PrototypingKitColors.accent)
            .background(PrototypingKitColors.panel.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PrototypingKitColors.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(PrototypingL10n.text("sidebar.recent_drafts"))
    }

    private var inspectorLauncher: some View {
        Button(action: { inspectorExpandedOverride = true }) {
            Image(systemName: "ipad.landscape.and.iphone")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 42, height: 34)
            .foregroundColor(PrototypingKitColors.accent)
            .background(PrototypingKitColors.panel.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PrototypingKitColors.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(PrototypingL10n.text("launcher.tools"))
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    sectionTitle(PrototypingL10n.text("section.actions"))

                    Button(action: { activeAlert = .help }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PrototypingKitColors.secondaryInk)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(PrototypingL10n.text("help.button"))

                    Spacer()
                    Button(action: { inspectorExpandedOverride = false }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(PrototypingKitColors.secondaryInk)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack {
                    ChoiceChip(title: PrototypingL10n.text("action.multi_select"), isSelected: isMultiSelectionEnabled) {
                        toggleMultiSelection()
                    }
                    .frame(width: 78)

                    ChoiceChip(title: PrototypingL10n.text("action.annotation"), isSelected: selectedElement?.component == .aiNote) {
                        addAnnotationFromUI()
                    }
                    .frame(width: 78)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle(PrototypingL10n.text("section.draft_kind"))

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
                        sectionTitle(PrototypingL10n.text("section.device"))

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
                                Text(PrototypingL10n.text("section.template"))
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

                        MoreIconButton {
                            activeLibrary = .templates
                        }
                    }

                    if isTemplateSectionVisible {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                            ForEach(quickTemplates) { template in
                                TemplateCard(
                                    template: template,
                                    isSelected: store.currentDocument.template == template,
                                    previewContext: templatePreviewContext(for: template)
                                ) {
                                    applyTemplateFromUI(template)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionTitle(PrototypingL10n.text("section.components"))
                        Spacer()
                        MoreIconButton {
                            activeLibrary = .components
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                        ForEach(quickComponentItems) { item in
                            ChoiceChip(
                                title: item.title,
                                isSelected: isSelectedComponentItem(item)
                            ) {
                                addComponentFromUI(item)
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
                                Text(PrototypingL10n.text("section.grid"))
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
                    previewContext: templatePreviewContext(for:),
                    onClose: { activeLibrary = nil },
                    onSelect: { template in
                        selectTemplateFromLibrary(template)
                    }
                )
            case .components:
                ComponentLibraryView(
                    items: allComponentItems,
                    selectedItem: selectedComponentItem,
                    onClose: { activeLibrary = nil },
                    onSelect: { item in
                        activeLibrary = nil
                        addComponentFromUI(item)
                    }
                )
            }
        }
    }

    private var availableTemplates: [PrototypingTemplate] {
        switch store.currentDocument.kind {
        case .webPage:
            return PrototypingTemplate.webTemplates
        case .flowNote, .deviceShowcase, .appPage:
            return PrototypingTemplate.appTemplates
        }
    }

    private var quickTemplates: [PrototypingTemplate] {
        Array(uniqueTemplates(recentTemplates + recommendedTemplates).prefix(2))
    }

    private var recommendedTemplates: [PrototypingTemplate] {
        switch store.currentDocument.kind {
        case .webPage:
            return [.blank, .webHome, .webSaaS, .dashboard]
        case .deviceShowcase, .flowNote, .appPage:
            return store.currentDocument.device == .tablet
                ? [.blank, .tabletDashboard, .finance, .kanban]
                : [.blank, .list, .detail, .mediaFeed]
        }
    }

    private func templatePreviewContext(for template: PrototypingTemplate) -> TemplatePreviewContext {
        let targetKind: PrototypingDraftKind = template.kind == .webPage
            ? .webPage
            : store.currentDocument.kind.normalized
        let targetDevice = template.preferredDevice ?? store.currentDocument.device
        let targetOrientation = store.currentDocument.orientation
        let canvasSize = targetKind == .webPage
            ? PrototypingCanvasSize.web
            : targetDevice.canvasSize(for: targetOrientation)

        return TemplatePreviewContext(
            kind: targetKind,
            device: targetDevice,
            orientation: targetOrientation,
            canvasSize: canvasSize
        )
    }

    private var recentTemplates: [PrototypingTemplate] {
        recentTemplateIDs
            .split(separator: ",")
            .compactMap { PrototypingTemplate(rawValue: String($0)) }
            .filter { availableTemplates.contains($0) }
    }

    private var quickComponentItems: [PrototypingComponentItem] {
        Array(uniqueComponentItems(recentComponentItems + recommendedComponentItems).prefix(8))
    }

    private var recommendedComponentItems: [PrototypingComponentItem] {
        if store.currentDocument.kind == .webPage {
            return [
                .component(.title),
                .component(.subtitle),
                .button(.primary),
                .button(.outline),
                .component(.topNavigation),
                .component(.card),
                .component(.chart),
                .component(.table)
            ]
        }

        return [
            .component(.title),
            .button(.primary),
            .button(.pill),
            .component(.input),
            .component(.search),
            .component(.card),
            .component(.listRow),
            .component(.imagePlaceholder)
        ]
    }

    private var recentComponentItems: [PrototypingComponentItem] {
        recentComponentIDs
            .split(separator: ",")
            .compactMap { componentItem(rawValue: String($0)) }
    }

    private var allComponentItems: [PrototypingComponentItem] {
        PrototypingButtonStyle.allCases.map(PrototypingComponentItem.button)
            + PrototypingComponent.allCases
                .filter { $0 != .button && $0 != .aiNote }
                .map(PrototypingComponentItem.component)
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

    private var selectedComponentItem: PrototypingComponentItem? {
        guard let selectedElement else { return nil }
        if selectedElement.component == .button {
            return .button(selectedElement.buttonStyle ?? .primary)
        }
        guard selectedElement.component != .aiNote else { return nil }
        return .component(selectedElement.component)
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

    private func addComponentFromUI(_ item: PrototypingComponentItem) {
        if item.component == .button,
           let style = item.buttonStyle,
           let selectedElement,
           selectedElement.component == .button
        {
            rememberComponent(item)
            store.updateButtonStyle(id: selectedElement.id, style: style)
            selectedElementIDs = [selectedElement.id]
            return
        }

        rememberComponent(item)
        store.addComponent(item.component, buttonStyle: item.buttonStyle)
        selectedElementIDs = store.currentDocument.elements.last.map { [$0.id] } ?? []
    }

    private func addComponentFromUI(_ component: PrototypingComponent) {
        store.addComponent(component)
        selectedElementIDs = store.currentDocument.elements.last.map { [$0.id] } ?? []
    }

    private func addAnnotationFromUI() {
        addComponentFromUI(.aiNote)
    }

    private func rememberTemplate(_ template: PrototypingTemplate) {
        recentTemplateIDs = prepending(template.rawValue, to: recentTemplateIDs, limit: 8)
    }

    private func rememberComponent(_ item: PrototypingComponentItem) {
        recentComponentIDs = prepending(item.id, to: recentComponentIDs, limit: 12)
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

    private func uniqueComponentItems(_ items: [PrototypingComponentItem]) -> [PrototypingComponentItem] {
        var result: [PrototypingComponentItem] = []
        for item in items where !result.contains(item) && item.component != .aiNote {
            result.append(item)
        }
        return result
    }

    private func componentItem(rawValue: String) -> PrototypingComponentItem? {
        if rawValue.hasPrefix("button.") {
            let styleRawValue = String(rawValue.dropFirst("button.".count))
            return PrototypingButtonStyle(rawValue: styleRawValue).map(PrototypingComponentItem.button)
        }

        guard let component = PrototypingComponent(rawValue: rawValue),
              component != .button,
              component != .aiNote
        else { return nil }
        return .component(component)
    }

    private func isSelectedComponentItem(_ item: PrototypingComponentItem) -> Bool {
        selectedComponentItem == item
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
            activeAlert = .message(PrototypingL10n.text("error.pdf_export_failed", error.localizedDescription))
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
    let previewContext: (PrototypingTemplate) -> TemplatePreviewContext
    let onClose: () -> Void
    let onSelect: (PrototypingTemplate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            libraryHeader(title: PrototypingL10n.text("section.template"), onClose: onClose)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 12)], spacing: 12) {
                    ForEach(templates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate == template,
                            previewContext: previewContext(template)
                        ) {
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
    let items: [PrototypingComponentItem]
    let selectedItem: PrototypingComponentItem?
    let onClose: () -> Void
    let onSelect: (PrototypingComponentItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            libraryHeader(title: PrototypingL10n.text("section.components"), onClose: onClose)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 98), spacing: 8)], spacing: 8) {
                    ForEach(items) { item in
                        ChoiceChip(title: item.title, isSelected: selectedItem == item) {
                            onSelect(item)
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
            Text(PrototypingL10n.text("action.done"))
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

@available(iOS 14.0, macCatalyst 14.0, *)
private struct DraftRecordRow: View {
    let record: PrototypingDraftRecord
    let isSelected: Bool
    let onOpen: () -> Void
    let onRename: (String) -> Void

    @State private var isEditingTitle = false
    @State private var editingTitle = ""

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
                if isEditingTitle {
                    HStack(spacing: 6) {
                        DraftTitleRenameField(
                            text: $editingTitle,
                            isFirstResponder: isEditingTitle,
                            onCommit: finishEditing
                        )
                        .frame(height: 24)

                        Button(action: finishEditing) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(PrototypingKitColors.accent)
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(PrototypingL10n.text("action.done"))
                    }
                } else {
                    Text(record.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(PrototypingKitColors.ink)
                        .lineLimit(1)
                }

                Text(formattedUpdatedAt)
                    .font(.caption)
                    .foregroundColor(PrototypingKitColors.secondaryInk)
            }

            Spacer()
        }
        .padding(8)
        .background(isSelected ? PrototypingKitColors.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditingTitle else { return }
            onOpen()
        }
        .onLongPressGesture {
            beginEditing()
        }
        .onAppear {
            if editingTitle.isEmpty {
                editingTitle = record.title
            }
        }
        .onChange(of: record.title) { title in
            guard !isEditingTitle else { return }
            editingTitle = title
        }
    }

    private var formattedUpdatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: record.updatedAt)
    }

    private func beginEditing() {
        editingTitle = record.title
        isEditingTitle = true
    }

    private func finishEditing() {
        let trimmedTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmedTitle.isEmpty ? record.title : trimmedTitle
        editingTitle = resolvedTitle
        isEditingTitle = false

        if resolvedTitle != record.title {
            onRename(resolvedTitle)
        }
    }
}

private struct DraftTitleRenameField: UIViewRepresentable {
    @Binding var text: String
    let isFirstResponder: Bool
    let onCommit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 13, weight: .semibold)
        textField.textColor = UIColor.black.withAlphaComponent(0.86)
        textField.tintColor = UIColor(red: 0.02, green: 0.48, blue: 0.98, alpha: 1)
        textField.returnKeyType = .done
        textField.clearButtonMode = .never
        textField.borderStyle = .none
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.onCommit = onCommit

        if uiView.text != text {
            uiView.text = text
        }

        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                uiView.selectAll(nil)
            }
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var onCommit: () -> Void

        init(text: Binding<String>, onCommit: @escaping () -> Void) {
            self.text = text
            self.onCommit = onCommit
        }

        @objc func textDidChange(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            text.wrappedValue = textField.text ?? ""
            onCommit()
            return true
        }
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

private struct MoreIconButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(PrototypingKitColors.secondaryInk)
                .frame(width: 44, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct TemplateCard: View {
    let template: PrototypingTemplate
    let isSelected: Bool
    let previewContext: TemplatePreviewContext
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TemplateThumbnail(template: template, previewContext: previewContext)
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
    let previewContext: TemplatePreviewContext

    var body: some View {
        GeometryReader { proxy in
            let document = previewDocument
            let canvasSize = document.canvasSize.cgSize
            let scale = min(proxy.size.width / canvasSize.width, proxy.size.height / canvasSize.height)
            let previewSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)

            ZStack {
                PrototypingDraftCanvas(document: document)
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: previewSize.width, height: previewSize.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.12), lineWidth: 1))
        }
    }

    private var previewDocument: PrototypingDraftDocument {
        PrototypingDraftDocument(
            kind: previewContext.kind,
            template: template,
            device: previewContext.device,
            orientation: previewContext.orientation,
            canvasSize: previewContext.canvasSize
        )
    }
}
