import SwiftUI
import UIKit

struct PrototypingExportCanvas: View {
    let document: PrototypingDraftDocument

    var body: some View {
        PrototypingDraftCanvas(document: document, showsGrid: false)
            .padding(18)
            .background(Color.white)
    }
}

struct PrototypingDraftCanvas: View {
    let document: PrototypingDraftDocument
    var showsGrid = true

    var body: some View {
        canvasShell(document: document, showsGrid: showsGrid) {
            PrototypingCanvasElementsLayer(
                document: document,
                selectedElementIDs: []
            )
        }
    }
}

struct PrototypingEditableDraftCanvas: View {
    let document: PrototypingDraftDocument
    let selectedElementIDs: Set<String>
    let isMultiSelectionEnabled: Bool
    let onSelect: (String) -> Void
    let onToggleSelection: (String) -> Void
    let onDeselect: () -> Void
    let onMove: (String, PrototypingElementFrame, Bool) -> Void
    let onMoveElements: ([String: PrototypingElementFrame], Bool) -> Void
    let onUpdateAnnotationArrow: (String, PrototypingAnnotationAnchor, CGPoint?, Bool) -> Void
    let onUpdateAnnotationText: (String, String, Bool) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        canvasShell(document: document) {
            PrototypingCanvasElementsLayer(
                document: document,
                selectedElementIDs: selectedElementIDs
            )
            SnapGuideOverlay(
                document: document,
                selectedElementIDs: selectedElementIDs
            )
            PrototypingCanvasInteractionOverlay(
                document: document,
                selectedElementIDs: selectedElementIDs,
                isMultiSelectionEnabled: isMultiSelectionEnabled,
                onSelect: onSelect,
                onToggleSelection: onToggleSelection,
                onDeselect: onDeselect,
                onMove: onMove,
                onMoveElements: onMoveElements,
                onUpdateAnnotationArrow: onUpdateAnnotationArrow,
                onUpdateAnnotationText: onUpdateAnnotationText,
                onDelete: onDelete
            )
        }
    }
}

private func canvasShell<Content: View>(
    document: PrototypingDraftDocument,
    showsGrid: Bool = true,
    @ViewBuilder content: () -> Content
) -> some View {
    let cornerRadius = canvasCornerRadius(for: document)

    return ZStack {
        Color.white
        if showsGrid {
            GridBackground(spacing: CGFloat(document.gridSize))
        }
        content()
    }
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.black.opacity(0.16), lineWidth: 2)
    )
}

private func canvasCornerRadius(for document: PrototypingDraftDocument) -> CGFloat {
    if document.kind == .webPage { return 12 }
    return document.device == .tablet ? 24 : 30
}

private func annotationAnchorPoint(in rect: CGRect, anchor: PrototypingAnnotationAnchor) -> CGPoint {
    switch anchor {
    case .top:
        return CGPoint(x: rect.midX, y: rect.minY)
    case .bottom:
        return CGPoint(x: rect.midX, y: rect.maxY)
    case .left:
        return CGPoint(x: rect.minX, y: rect.midY)
    case .right:
        return CGPoint(x: rect.maxX, y: rect.midY)
    }
}

private func annotationControlPoint(in rect: CGRect, anchor: PrototypingAnnotationAnchor) -> CGPoint {
    annotationAnchorPoint(in: rect, anchor: anchor)
}

private enum PrototypingResizeEdge: String, CaseIterable, Identifiable {
    case top
    case bottom
    case left
    case right

    var id: String { rawValue }
}

private func resizeHandlePoint(in rect: CGRect, edge: PrototypingResizeEdge) -> CGPoint {
    switch edge {
    case .top:
        return CGPoint(x: rect.midX, y: rect.minY)
    case .bottom:
        return CGPoint(x: rect.midX, y: rect.maxY)
    case .left:
        return CGPoint(x: rect.minX, y: rect.midY)
    case .right:
        return CGPoint(x: rect.maxX, y: rect.midY)
    }
}

private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(
        x: min(max(0, point.x), size.width),
        y: min(max(0, point.y), size.height)
    )
}

private func annotationText(for element: PrototypingCanvasElement, fallback note: String) -> String {
    let title = element.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let fallbackText = note.trimmingCharacters(in: .whitespacesAndNewlines)

    if !title.isEmpty && title != PrototypingComponent.aiNote.title {
        return PrototypingDraftDocument.annotationTextOrDefault(title)
    }

    return PrototypingDraftDocument.annotationTextOrDefault(fallbackText)
}

private struct PrototypingCanvasElementsLayer: View {
    let document: PrototypingDraftDocument
    let selectedElementIDs: Set<String>

    private var singleSelectedElementID: String? {
        selectedElementIDs.count == 1 ? selectedElementIDs.first : nil
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                AnnotationArrowLayer(document: document)

                ForEach(document.elements) { element in
                    PrototypingElementContainer(
                        element: element,
                        canvasSize: document.canvasSize.cgSize,
                        note: document.note,
                        isSelected: selectedElementIDs.contains(element.id),
                        isSingleSelected: element.id == singleSelectedElementID
                    )
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct PrototypingElementContainer: View {
    let element: PrototypingCanvasElement
    let canvasSize: CGSize
    let note: String
    let isSelected: Bool
    let isSingleSelected: Bool

    var body: some View {
        let rect = element.frame.cgRect

        PrototypingElementView(element: element, note: note)
            .frame(width: rect.width, height: rect.height)
            .overlay(
                SelectionChrome(
                    isSelected: isSelected,
                    showsResizeHandles: isSingleSelected && element.component != .aiNote,
                    showsAnnotationHandles: isSingleSelected && element.component == .aiNote
                )
            )
            .position(x: rect.midX, y: rect.midY)
    }
}

private struct AnnotationArrowLayer: View {
    let document: PrototypingDraftDocument

    var body: some View {
        GeometryReader { _ in
            ForEach(annotatedElements) { element in
                if let arrow = element.annotationArrow {
                    AnnotationArrowShape(
                        start: annotationAnchorPoint(in: element.frame.cgRect, anchor: arrow.anchor),
                        end: clampedPoint(arrow.target.cgPoint, in: document.canvasSize.cgSize)
                    )
                    .stroke(Color.orange.opacity(0.86), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var annotatedElements: [PrototypingCanvasElement] {
        document.elements.filter { $0.component == .aiNote && $0.annotationArrow != nil }
    }
}

private struct AnnotationArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength: CGFloat = 14
        let headAngle: CGFloat = .pi / 7

        path.move(to: start)
        path.addLine(to: end)
        path.move(to: end)
        path.addLine(
            to: CGPoint(
                x: end.x - cos(angle - headAngle) * headLength,
                y: end.y - sin(angle - headAngle) * headLength
            )
        )
        path.move(to: end)
        path.addLine(
            to: CGPoint(
                x: end.x - cos(angle + headAngle) * headLength,
                y: end.y - sin(angle + headAngle) * headLength
            )
        )
        return path
    }
}

private struct SelectionChrome: View {
    let isSelected: Bool
    let showsResizeHandles: Bool
    let showsAnnotationHandles: Bool

    var body: some View {
        GeometryReader { proxy in
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.92), lineWidth: 2.5)
                    .background(Color.blue.opacity(0.035))

                ForEach(Array(cornerPoints(in: proxy.size).enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.blue.opacity(0.92), lineWidth: 2))
                        .frame(width: 9, height: 9)
                        .position(point)
                }

                if showsAnnotationHandles {
                    ForEach(PrototypingAnnotationAnchor.allCases) { anchor in
                        Circle()
                            .fill(Color.orange.opacity(0.96))
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .frame(width: 12, height: 12)
                            .position(annotationControlPoint(in: CGRect(origin: .zero, size: proxy.size), anchor: anchor))
                    }
                }

                if showsResizeHandles {
                    ForEach(PrototypingResizeEdge.allCases) { edge in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.blue.opacity(0.92), lineWidth: 2)
                            )
                            .frame(width: 13, height: 13)
                            .position(resizeHandlePoint(in: CGRect(origin: .zero, size: proxy.size), edge: edge))
                    }
                }
            }
        }
    }

    private func cornerPoints(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]
    }
}

private struct AnnotationInlineEditor: View {
    let element: PrototypingCanvasElement
    let text: String
    let isEditing: Bool
    let onEdit: () -> Void
    let onTextChange: (String) -> Void
    let onDone: () -> Void

    var body: some View {
        let rect = element.frame.cgRect

        ZStack(alignment: .topLeading) {
            if isEditing {
                AnnotationTextView(
                    text: Binding(
                        get: { text },
                        set: { onTextChange($0) }
                    ),
                    isFirstResponder: true
                )
                .frame(width: rect.width, height: rect.height)
                .background(Color.yellow.opacity(0.94))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.45), lineWidth: 1)
                )
                .position(x: rect.midX, y: rect.midY)
            }

            Button(action: isEditing ? onDone : onEdit) {
                Text(isEditing ? PrototypingL10n.text("action.done") : PrototypingL10n.text("action.edit"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(Color.blue.opacity(0.88))
                    .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            .position(
                x: max(34, rect.maxX - 28),
                y: max(13, rect.minY - 15)
            )
        }
    }
}

private struct AnnotationTextView: UIViewRepresentable {
    @Binding var text: String
    let isFirstResponder: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 14, weight: .semibold)
        textView.textColor = UIColor.black.withAlphaComponent(0.82)
        textView.textAlignment = .center
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.maximumNumberOfLines = 0
        textView.isScrollEnabled = false
        textView.alwaysBounceHorizontal = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.returnKeyType = .default
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}

private struct SnapGuideOverlay: View {
    let document: PrototypingDraftDocument
    let selectedElementIDs: Set<String>

    var body: some View {
        GeometryReader { proxy in
            if let rect = selectedRect {
                Path { path in
                    for x in [rect.minX, rect.maxX] {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }

                    for y in [rect.minY, rect.maxY] {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(
                    Color.blue.opacity(0.42),
                    style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [7, 5])
                )

                GuideTag(text: PrototypingL10n.text("guide.grid", Int(document.gridSize)))
                    .position(x: min(rect.maxX + 34, proxy.size.width - 34), y: max(rect.minY - 14, 14))
            }
        }
        .allowsHitTesting(false)
    }

    private var selectedRect: CGRect? {
        let rects = document.elements
            .filter { selectedElementIDs.contains($0.id) }
            .map { $0.frame.cgRect }
        return rects.reduce(nil) { partial, rect in
            partial?.union(rect) ?? rect
        }
    }
}

private struct GuideTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.blue.opacity(0.86))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.88))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.blue.opacity(0.24), lineWidth: 1))
    }
}

private struct PrototypingCanvasInteractionOverlay: View {
    let document: PrototypingDraftDocument
    let selectedElementIDs: Set<String>
    let isMultiSelectionEnabled: Bool
    let onSelect: (String) -> Void
    let onToggleSelection: (String) -> Void
    let onDeselect: () -> Void
    let onMove: (String, PrototypingElementFrame, Bool) -> Void
    let onMoveElements: ([String: PrototypingElementFrame], Bool) -> Void
    let onUpdateAnnotationArrow: (String, PrototypingAnnotationAnchor, CGPoint?, Bool) -> Void
    let onUpdateAnnotationText: (String, String, Bool) -> Void
    let onDelete: (String) -> Void

    @State private var draggingElementID: String?
    @State private var draggingStartFrame: PrototypingElementFrame?
    @State private var draggingAnnotation: AnnotationDrag?
    @State private var draggingResize: ResizeDrag?
    @State private var draggingGroup: GroupDrag?
    @State private var editingAnnotationID: String?
    @State private var editingAnnotationText = ""

    private struct AnnotationDrag {
        let elementID: String
        let anchor: PrototypingAnnotationAnchor
    }

    private struct ResizeDrag {
        let elementID: String
        let edge: PrototypingResizeEdge
        let startFrame: PrototypingElementFrame
        let component: PrototypingComponent
    }

    private struct GroupDrag {
        let startFrames: [String: PrototypingElementFrame]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            PrototypingCanvasGestureView(
                canBeginPan: { point in
                    hitAnnotationControl(at: point) != nil
                        || hitResizeControl(at: point) != nil
                        || hitElement(at: point) != nil
                },
                onSingleTap: handleSingleTap,
                onDoubleTap: { point in
                    guard let element = hitElement(at: point) else { return }
                    onDelete(element.id)
                },
                onPanBegan: handlePanBegan,
                onPanChanged: handlePanChanged,
                onPanEnded: handlePanEnded
            )

            if let selectedAnnotation {
                AnnotationInlineEditor(
                    element: selectedAnnotation,
                    text: editingAnnotationID == selectedAnnotation.id
                        ? editingAnnotationText
                        : annotationText(for: selectedAnnotation, fallback: document.note),
                    isEditing: editingAnnotationID == selectedAnnotation.id,
                    onEdit: {
                        editingAnnotationID = selectedAnnotation.id
                        editingAnnotationText = annotationText(for: selectedAnnotation, fallback: document.note)
                        onSelect(selectedAnnotation.id)
                    },
                    onTextChange: { text in
                        editingAnnotationText = text
                        onUpdateAnnotationText(selectedAnnotation.id, text, false)
                    },
                    onDone: {
                        onUpdateAnnotationText(selectedAnnotation.id, editingAnnotationText, true)
                        editingAnnotationID = nil
                        editingAnnotationText = ""
                    }
                )
            }
        }
    }

    private func handleSingleTap(_ point: CGPoint) {
        if let annotationControl = hitAnnotationControl(at: point) {
            clearAnnotationEditing(keeping: annotationControl.elementID)
            onSelect(annotationControl.elementID)
            return
        }

        if let resizeControl = hitResizeControl(at: point) {
            clearAnnotationEditing(keeping: resizeControl.elementID)
            onSelect(resizeControl.elementID)
            return
        }

        guard let element = hitElement(at: point) else {
            clearAnnotationEditing()
            onDeselect()
            return
        }

        clearAnnotationEditing(keeping: element.id)
        if isMultiSelectionEnabled {
            onToggleSelection(element.id)
        } else {
            onSelect(element.id)
        }
    }

    private func handlePanBegan(_ point: CGPoint) {
        if let annotationControl = hitAnnotationControl(at: point) {
            clearAnnotationEditing(keeping: annotationControl.elementID)
            draggingAnnotation = annotationControl
            draggingResize = nil
            draggingGroup = nil
            draggingElementID = nil
            draggingStartFrame = nil
            onSelect(annotationControl.elementID)
            return
        }

        if let resizeControl = hitResizeControl(at: point) {
            clearAnnotationEditing(keeping: resizeControl.elementID)
            draggingResize = resizeControl
            draggingAnnotation = nil
            draggingGroup = nil
            draggingElementID = nil
            draggingStartFrame = nil
            onSelect(resizeControl.elementID)
            return
        }

        guard let element = hitElement(at: point) else {
            clearAnnotationEditing()
            draggingElementID = nil
            draggingStartFrame = nil
            draggingAnnotation = nil
            draggingResize = nil
            draggingGroup = nil
            return
        }

        clearAnnotationEditing(keeping: element.id)
        let groupStartFrames = selectedGroupStartFrames(for: element)
        if groupStartFrames.count > 1 {
            draggingGroup = GroupDrag(startFrames: groupStartFrames)
            draggingElementID = nil
            draggingStartFrame = nil
            draggingAnnotation = nil
            draggingResize = nil
            return
        }

        draggingElementID = element.id
        draggingStartFrame = element.frame
        draggingAnnotation = nil
        draggingResize = nil
        draggingGroup = nil
        onSelect(element.id)
    }

    private func handlePanChanged(_ point: CGPoint, translation: CGSize) {
        if let draggingAnnotation {
            onUpdateAnnotationArrow(
                draggingAnnotation.elementID,
                draggingAnnotation.anchor,
                annotationTarget(at: point, for: draggingAnnotation),
                false
            )
            return
        }

        if let draggingResize {
            let frame = resizedFrame(
                from: draggingResize.startFrame,
                edge: draggingResize.edge,
                translation: translation,
                component: draggingResize.component
            )
            onMove(draggingResize.elementID, frame, false)
            return
        }

        if let draggingGroup {
            onMoveElements(
                movedFrames(from: draggingGroup.startFrames, by: translation),
                false
            )
            return
        }

        guard let draggingElementID, let draggingStartFrame else { return }
        let frame = draggingStartFrame.moved(by: translation, inside: document.canvasSize.cgSize)
        onMove(draggingElementID, frame, false)
    }

    private func handlePanEnded(_ point: CGPoint, translation: CGSize) {
        if let draggingAnnotation {
            onUpdateAnnotationArrow(
                draggingAnnotation.elementID,
                draggingAnnotation.anchor,
                annotationTarget(at: point, for: draggingAnnotation),
                true
            )
            self.draggingAnnotation = nil
            return
        }

        if let draggingResize {
            let frame = resizedFrame(
                from: draggingResize.startFrame,
                edge: draggingResize.edge,
                translation: translation,
                component: draggingResize.component
            )
            onMove(draggingResize.elementID, frame, true)
            self.draggingResize = nil
            return
        }

        if let draggingGroup {
            onMoveElements(
                movedFrames(from: draggingGroup.startFrames, by: translation),
                true
            )
            self.draggingGroup = nil
            return
        }

        guard let draggingElementID, let draggingStartFrame else { return }
        let frame = draggingStartFrame.moved(by: translation, inside: document.canvasSize.cgSize)
        onMove(draggingElementID, frame, true)
        self.draggingElementID = nil
        self.draggingStartFrame = nil
    }

    private func clearAnnotationEditing(keeping elementID: String? = nil) {
        guard let editingAnnotationID, editingAnnotationID != elementID else { return }
        self.editingAnnotationID = nil
        self.editingAnnotationText = ""
    }

    private func hitAnnotationControl(at point: CGPoint) -> AnnotationDrag? {
        guard selectedElementIDs.count == 1 else { return nil }
        guard let selectedAnnotation = selectedAnnotation else { return nil }
        let rect = selectedAnnotation.frame.cgRect

        for anchor in PrototypingAnnotationAnchor.allCases {
            let controlPoint = annotationControlPoint(in: rect, anchor: anchor)
            if distance(from: point, to: controlPoint) <= 18 {
                return AnnotationDrag(elementID: selectedAnnotation.id, anchor: anchor)
            }
        }

        if let arrow = selectedAnnotation.annotationArrow,
           distance(from: point, to: arrow.target.cgPoint) <= 20 {
            return AnnotationDrag(elementID: selectedAnnotation.id, anchor: arrow.anchor)
        }

        return nil
    }

    private func hitResizeControl(at point: CGPoint) -> ResizeDrag? {
        guard selectedElementIDs.count == 1 else { return nil }
        guard let selectedElement = selectedElement else { return nil }
        guard selectedElement.component != .aiNote else { return nil }
        let rect = selectedElement.frame.cgRect

        for edge in PrototypingResizeEdge.allCases {
            let controlPoint = resizeHandlePoint(in: rect, edge: edge)
            if distance(from: point, to: controlPoint) <= 18 {
                return ResizeDrag(
                    elementID: selectedElement.id,
                    edge: edge,
                    startFrame: selectedElement.frame,
                    component: selectedElement.component
                )
            }
        }

        return nil
    }

    private func annotationTarget(at point: CGPoint, for drag: AnnotationDrag) -> CGPoint? {
        guard let element = document.elements.first(where: { $0.id == drag.elementID }) else { return nil }
        let rect = element.frame.cgRect
        let anchorPoint = annotationAnchorPoint(in: rect, anchor: drag.anchor)
        let target = clampedPoint(point, in: document.canvasSize.cgSize)

        if rect.insetBy(dx: -18, dy: -18).contains(target) || distance(from: target, to: anchorPoint) < 24 {
            return nil
        }

        return target
    }

    private func selectedGroupStartFrames(for hitElement: PrototypingCanvasElement) -> [String: PrototypingElementFrame] {
        guard isMultiSelectionEnabled else { return [:] }
        guard selectedElementIDs.contains(hitElement.id) else { return [:] }

        return document.elements.reduce(into: [:]) { result, element in
            if selectedElementIDs.contains(element.id) {
                result[element.id] = element.frame
            }
        }
    }

    private func movedFrames(
        from startFrames: [String: PrototypingElementFrame],
        by translation: CGSize
    ) -> [String: PrototypingElementFrame] {
        guard let groupRect = startFrames.values.map(\.cgRect).reduce(nil, { partial, rect in
            partial?.union(rect) ?? rect
        }) else {
            return [:]
        }

        let canvasSize = document.canvasSize.cgSize
        let unit = max(4, CGFloat(document.gridSize))
        var dx = snap(translation.width, unit: unit)
        var dy = snap(translation.height, unit: unit)
        dx = min(max(dx, -groupRect.minX), canvasSize.width - groupRect.maxX)
        dy = min(max(dy, -groupRect.minY), canvasSize.height - groupRect.maxY)

        return startFrames.mapValues { frame in
            PrototypingElementFrame(
                x: frame.x + Double(dx),
                y: frame.y + Double(dy),
                width: frame.width,
                height: frame.height
            )
        }
    }

    private func resizedFrame(
        from startFrame: PrototypingElementFrame,
        edge: PrototypingResizeEdge,
        translation: CGSize,
        component: PrototypingComponent
    ) -> PrototypingElementFrame {
        let canvasSize = document.canvasSize.cgSize
        let minimumSize = PrototypingDraftDocument.minimumSize(for: component)
        let maximumSize = PrototypingDraftDocument.maximumSize(for: component, canvasSize: canvasSize)
        let rect = startFrame.cgRect
        var x = rect.minX
        var y = rect.minY
        var width = rect.width
        var height = rect.height

        switch edge {
        case .left:
            let fixedRight = rect.maxX
            let maxWidth = min(maximumSize.width, fixedRight)
            width = clamp(rect.width - translation.width, minimumSize.width, maxWidth)
            x = fixedRight - width
        case .right:
            let maxWidth = min(maximumSize.width, canvasSize.width - rect.minX)
            width = clamp(rect.width + translation.width, minimumSize.width, maxWidth)
        case .top:
            let fixedBottom = rect.maxY
            let maxHeight = min(maximumSize.height, fixedBottom)
            height = clamp(rect.height - translation.height, minimumSize.height, maxHeight)
            y = fixedBottom - height
        case .bottom:
            let maxHeight = min(maximumSize.height, canvasSize.height - rect.minY)
            height = clamp(rect.height + translation.height, minimumSize.height, maxHeight)
        }

        return PrototypingElementFrame(
            x: Double(max(0, x)),
            y: Double(max(0, y)),
            width: Double(width),
            height: Double(height)
        )
        .constrained(
            inside: canvasSize,
            minimumSize: minimumSize,
            maximumSize: maximumSize
        )
    }

    private var selectedAnnotation: PrototypingCanvasElement? {
        guard let selectedElementID = singleSelectedElementID else { return nil }
        return document.elements.first { $0.id == selectedElementID && $0.component == .aiNote }
    }

    private var selectedElement: PrototypingCanvasElement? {
        guard let selectedElementID = singleSelectedElementID else { return nil }
        return document.elements.first { $0.id == selectedElementID }
    }

    private var singleSelectedElementID: String? {
        selectedElementIDs.count == 1 ? selectedElementIDs.first : nil
    }

    private func hitElement(at point: CGPoint) -> PrototypingCanvasElement? {
        let candidates = document.elements.enumerated().filter { _, element in
            element.frame.cgRect.insetBy(dx: -4, dy: -4).contains(point)
        }

        return candidates.sorted { lhs, rhs in
            let lhsArea = lhs.element.frame.cgRect.width * lhs.element.frame.cgRect.height
            let rhsArea = rhs.element.frame.cgRect.width * rhs.element.frame.cgRect.height

            if abs(lhsArea - rhsArea) > 1 {
                return lhsArea < rhsArea
            }

            return lhs.offset > rhs.offset
        }
        .first?
        .element
    }

    private func distance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private func clamp(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
        min(maximum, max(minimum, value))
    }

    private func snap(_ value: CGFloat, unit: CGFloat) -> CGFloat {
        guard unit > 0 else { return value }
        return (value / unit).rounded() * unit
    }
}

private struct PrototypingCanvasGestureView: UIViewRepresentable {
    var canBeginPan: (CGPoint) -> Bool
    var onSingleTap: (CGPoint) -> Void
    var onDoubleTap: (CGPoint) -> Void
    var onPanBegan: (CGPoint) -> Void
    var onPanChanged: (CGPoint, CGSize) -> Void
    var onPanEnded: (CGPoint, CGSize) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            canBeginPan: canBeginPan,
            onSingleTap: onSingleTap,
            onDoubleTap: onDoubleTap,
            onPanBegan: onPanBegan,
            onPanChanged: onPanChanged,
            onPanEnded: onPanEnded
        )
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator

        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.canBeginPan = canBeginPan
        context.coordinator.onSingleTap = onSingleTap
        context.coordinator.onDoubleTap = onDoubleTap
        context.coordinator.onPanBegan = onPanBegan
        context.coordinator.onPanChanged = onPanChanged
        context.coordinator.onPanEnded = onPanEnded
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var canBeginPan: (CGPoint) -> Bool
        var onSingleTap: (CGPoint) -> Void
        var onDoubleTap: (CGPoint) -> Void
        var onPanBegan: (CGPoint) -> Void
        var onPanChanged: (CGPoint, CGSize) -> Void
        var onPanEnded: (CGPoint, CGSize) -> Void

        init(
            canBeginPan: @escaping (CGPoint) -> Bool,
            onSingleTap: @escaping (CGPoint) -> Void,
            onDoubleTap: @escaping (CGPoint) -> Void,
            onPanBegan: @escaping (CGPoint) -> Void,
            onPanChanged: @escaping (CGPoint, CGSize) -> Void,
            onPanEnded: @escaping (CGPoint, CGSize) -> Void
        ) {
            self.canBeginPan = canBeginPan
            self.onSingleTap = onSingleTap
            self.onDoubleTap = onDoubleTap
            self.onPanBegan = onPanBegan
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
        }

        @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else { return }
            onSingleTap(recognizer.location(in: view))
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else { return }
            onDoubleTap(recognizer.location(in: view))
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let point = recognizer.location(in: view)
            let translation = recognizer.translation(in: view)
            let translationSize = CGSize(width: translation.x, height: translation.y)

            switch recognizer.state {
            case .began:
                onPanBegan(point)
            case .changed:
                onPanChanged(point, translationSize)
            case .ended, .cancelled, .failed:
                onPanEnded(point, translationSize)
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer is UIPanGestureRecognizer,
                  let view = gestureRecognizer.view
            else {
                return true
            }

            return canBeginPan(gestureRecognizer.location(in: view))
        }
    }
}

private struct PrototypingElementView: View {
    let element: PrototypingCanvasElement
    let note: String

    var body: some View {
        GeometryReader { proxy in
            switch element.component {
            case .title:
                title(proxy.size)
            case .subtitle:
                subtitle(proxy.size)
            case .button:
                button(proxy.size)
            case .input:
                input(proxy.size)
            case .search:
                search(proxy.size)
            case .card:
                card(proxy.size)
            case .listRow:
                listRow(proxy.size)
            case .imagePlaceholder:
                imagePlaceholder(proxy.size)
            case .bottomNavigation:
                bottomNavigation(proxy.size)
            case .topNavigation:
                topNavigation(proxy.size)
            case .segmentedControl:
                segmentedControl(proxy.size)
            case .avatar:
                avatar(proxy.size)
            case .tag:
                tag(proxy.size)
            case .toggle:
                toggle(proxy.size)
            case .checkbox:
                checkbox(proxy.size)
            case .progress:
                progress(proxy.size)
            case .chart:
                chart(proxy.size)
            case .table:
                table(proxy.size)
            case .sidebar:
                sidebar(proxy.size)
            case .dialog:
                dialog(proxy.size)
            case .arrow:
                arrow(proxy.size)
            case .aiNote:
                noteView(proxy.size)
            }
        }
    }

    private func title(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: max(5, size.height * 0.18)) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black.opacity(0.72))
                .frame(width: size.width * 0.55, height: max(8, size.height * 0.34))
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.18))
                .frame(width: size.width * 0.82, height: max(5, size.height * 0.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func subtitle(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: max(4, size.height * 0.18)) {
            line(width: size.width * 0.92, height: max(6, size.height * 0.28), opacity: 0.14)
            line(width: size.width * 0.64, height: max(6, size.height * 0.26), opacity: 0.12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func button(_ size: CGSize) -> some View {
        let style = element.buttonStyle ?? .primary
        let cornerRadius = style == .pill ? size.height / 2 : min(12, size.height * 0.28)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return ZStack {
            shape.fill(buttonFillColor(for: style))

            if buttonStrokeWidth(for: style) > 0 {
                shape.stroke(buttonStrokeColor(for: style), lineWidth: buttonStrokeWidth(for: style))
            }

            if style == .ghost {
                RoundedRectangle(cornerRadius: 4)
                    .fill(buttonLineColor(for: style))
                    .frame(width: size.width * 0.58, height: max(4, size.height * 0.10))
                    .offset(y: size.height * 0.18)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(buttonLineColor(for: style))
                    .frame(width: size.width * (style == .pill ? 0.34 : 0.42), height: max(6, size.height * 0.16))
            }
        }
    }

    private func buttonFillColor(for style: PrototypingButtonStyle) -> Color {
        switch style {
        case .primary, .pill:
            return Color.blue.opacity(0.78)
        case .secondary:
            return Color.black.opacity(0.72)
        case .outline:
            return Color.white.opacity(0.48)
        case .soft:
            return Color.blue.opacity(0.14)
        case .ghost:
            return Color.clear
        }
    }

    private func buttonStrokeColor(for style: PrototypingButtonStyle) -> Color {
        switch style {
        case .outline:
            return Color.blue.opacity(0.70)
        case .ghost:
            return Color.black.opacity(0.08)
        default:
            return Color.clear
        }
    }

    private func buttonStrokeWidth(for style: PrototypingButtonStyle) -> CGFloat {
        switch style {
        case .outline:
            return 1.8
        case .ghost:
            return 1
        default:
            return 0
        }
    }

    private func buttonLineColor(for style: PrototypingButtonStyle) -> Color {
        switch style {
        case .primary, .secondary, .pill:
            return Color.white.opacity(0.82)
        case .outline, .soft, .ghost:
            return Color.blue.opacity(0.62)
        }
    }

    private func input(_ size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: min(10, size.height * 0.25))
            .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
            .background(Color.white.opacity(0.44))
    }

    private func search(_ size: CGSize) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: min(16, size.height * 0.42), weight: .semibold))
                .foregroundColor(.gray)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.16))
                .frame(width: size.width * 0.45, height: max(6, size.height * 0.16))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, min(14, size.width * 0.08))
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: min(14, size.height * 0.34)))
    }

    private func card(_ size: CGSize) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .frame(width: min(72, size.width * 0.25), height: size.height * 0.62)
            VStack(alignment: .leading, spacing: max(7, size.height * 0.1)) {
                line(width: size.width * 0.44, height: max(7, size.height * 0.11), opacity: 0.28)
                line(width: size.width * 0.62, height: max(6, size.height * 0.09), opacity: 0.14)
                line(width: size.width * 0.42, height: max(6, size.height * 0.09), opacity: 0.14)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.14), lineWidth: 1.5))
    }

    private func listRow(_ size: CGSize) -> some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                .frame(width: min(34, size.height * 0.62), height: min(34, size.height * 0.62))
            VStack(alignment: .leading, spacing: 8) {
                line(width: size.width * 0.52, height: 8, opacity: 0.24)
                line(width: size.width * 0.38, height: 7, opacity: 0.14)
            }
            Spacer(minLength: 0)
        }
    }

    private func imagePlaceholder(_ size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.black.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: min(34, size.height * 0.24)))
                    .foregroundColor(.gray)
            )
    }

    private func bottomNavigation(_ size: CGSize) -> some View {
        HStack {
            ForEach(0..<4, id: \.self) { index in
                VStack(spacing: 6) {
                    Circle()
                        .fill(index == 0 ? Color.blue.opacity(0.65) : Color.black.opacity(0.24))
                        .frame(width: min(18, size.height * 0.25), height: min(18, size.height * 0.25))
                    line(width: min(34, size.width * 0.12), height: 6, opacity: 0.18)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    private func topNavigation(_ size: CGSize) -> some View {
        HStack(spacing: 12) {
            line(width: min(88, size.width * 0.28), height: max(8, size.height * 0.18), opacity: 0.28)
            Spacer(minLength: 0)
            ForEach(0..<3, id: \.self) { index in
                line(width: min(52, size.width * 0.16), height: max(7, size.height * 0.14), opacity: index == 0 ? 0.22 : 0.12)
            }
        }
        .padding(.horizontal, 14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.12), lineWidth: 1.2))
    }

    private func segmentedControl(_ size: CGSize) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 9)
                    .fill(index == 0 ? Color.blue.opacity(0.22) : Color.gray.opacity(0.10))
                    .overlay(line(width: size.width * 0.16, height: 6, opacity: index == 0 ? 0.28 : 0.12))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.12), lineWidth: 1.2))
    }

    private func avatar(_ size: CGSize) -> some View {
        Circle()
            .stroke(Color.black.opacity(0.18), lineWidth: 2)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: min(size.width, size.height) * 0.42))
                    .foregroundColor(.gray.opacity(0.72))
            )
    }

    private func tag(_ size: CGSize) -> some View {
        Capsule()
            .fill(Color.blue.opacity(0.14))
            .overlay(line(width: size.width * 0.48, height: max(5, size.height * 0.18), opacity: 0.24))
    }

    private func toggle(_ size: CGSize) -> some View {
        Capsule()
            .fill(Color.blue.opacity(0.20))
            .overlay(
                Circle()
                    .fill(Color.blue.opacity(0.72))
                    .frame(width: min(size.height * 0.74, size.width * 0.44), height: min(size.height * 0.74, size.width * 0.44))
                    .padding(.trailing, 4),
                alignment: .trailing
            )
    }

    private func checkbox(_ size: CGSize) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.blue.opacity(0.68), lineWidth: 2)
                .frame(width: min(24, size.height * 0.72), height: min(24, size.height * 0.72))
                .overlay(Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.blue))
            line(width: size.width * 0.52, height: 7, opacity: 0.18)
            Spacer(minLength: 0)
        }
    }

    private func progress(_ size: CGSize) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.gray.opacity(0.14))
                .overlay(
                    Capsule()
                        .fill(Color.blue.opacity(0.62))
                        .frame(width: proxy.size.width * 0.56),
                    alignment: .leading
                )
        }
    }

    private func chart(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            line(width: size.width * 0.38, height: 9, opacity: 0.24)
            HStack(alignment: .bottom, spacing: max(8, size.width * 0.04)) {
                ForEach([0.42, 0.72, 0.50, 0.86, 0.62], id: \.self) { value in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.blue.opacity(0.18 + value * 0.18))
                        .frame(height: max(20, size.height * value * 0.58))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.13), lineWidth: 1.4))
    }

    private func table(_ size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    line(width: size.width * 0.22, height: 7, opacity: rowIndex == 0 ? 0.24 : 0.14)
                    line(width: size.width * 0.18, height: 7, opacity: rowIndex == 0 ? 0.24 : 0.12)
                    line(width: size.width * 0.24, height: 7, opacity: rowIndex == 0 ? 0.24 : 0.12)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(maxHeight: .infinity)
                .background(rowIndex == 0 ? Color.gray.opacity(0.10) : Color.clear)
                if rowIndex < 4 {
                    Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.12), lineWidth: 1.2))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sidebar(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            line(width: size.width * 0.62, height: 9, opacity: 0.24)
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 7)
                    .fill(index == 0 ? Color.blue.opacity(0.18) : Color.black.opacity(0.08))
                    .frame(height: max(20, min(30, size.height * 0.065)))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dialog(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            line(width: size.width * 0.48, height: 8, opacity: 0.28)
            line(width: size.width * 0.72, height: 7, opacity: 0.14)
            line(width: size.width * 0.62, height: 7, opacity: 0.14)
        }
        .padding(14)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func arrow(_ size: CGSize) -> some View {
        Path { path in
            let midY = size.height / 2
            path.move(to: CGPoint(x: 8, y: midY))
            path.addLine(to: CGPoint(x: size.width - 18, y: midY))
            path.move(to: CGPoint(x: size.width - 34, y: midY - 13))
            path.addLine(to: CGPoint(x: size.width - 16, y: midY))
            path.addLine(to: CGPoint(x: size.width - 34, y: midY + 13))
        }
        .stroke(Color.blue.opacity(0.78), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func noteView(_ size: CGSize) -> some View {
        let text = annotationText(for: element, fallback: note)

        return Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.black.opacity(0.82))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.yellow.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.35), lineWidth: 1))
    }

    private func line(width: CGFloat, height: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.black.opacity(opacity))
            .frame(width: max(8, width), height: height)
    }
}

private struct GridBackground: View {
    let spacing: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let resolvedSpacing = max(8, spacing)

            ZStack {
                Path { path in
                    var x: CGFloat = 0
                    while x <= proxy.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                        x += resolvedSpacing
                    }

                    var y: CGFloat = 0
                    while y <= proxy.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                        y += resolvedSpacing
                    }
                }
                .stroke(Color.gray.opacity(0.13), lineWidth: 0.8)

                Path { path in
                    var x: CGFloat = 0
                    var xIndex = 0
                    while x <= proxy.size.width {
                        if xIndex % 4 == 0 {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                        }
                        x += resolvedSpacing
                        xIndex += 1
                    }

                    var y: CGFloat = 0
                    var yIndex = 0
                    while y <= proxy.size.height {
                        if yIndex % 4 == 0 {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                        }
                        y += resolvedSpacing
                        yIndex += 1
                    }
                }
                .stroke(Color.gray.opacity(0.24), lineWidth: 1)
            }
        }
    }
}

private struct PhoneWireframe: View {
    let document: PrototypingDraftDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if document.enabledComponents.contains(.title) {
                header
            }

            switch document.template {
            case .login:
                login
            case .form:
                form
            case .chat:
                chat
            case .detail:
                detail
            case .list,
                 .blank,
                 .blankPhone,
                 .blankTablet,
                 .onboarding,
                 .profile,
                 .settings,
                 .checkout,
                 .tabletDashboard,
                 .calendar,
                 .kanban,
                 .mediaFeed,
                 .finance,
                 .habitTracker,
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
                list
            }

            Spacer(minLength: 8)

            if document.enabledComponents.contains(.bottomNavigation) {
                bottomNavigation
            }
        }
        .padding(24)
        .overlay(
            Group {
                if document.enabledComponents.contains(.aiNote) {
                    note
                        .padding(.top, 84)
                        .padding(.trailing, 18)
                }
            },
            alignment: .topTrailing
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.72))
                .frame(width: 132, height: 16)

            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black.opacity(0.2))
                .frame(width: 210, height: 10)
        }
        .padding(.top, 12)
    }

    private var list: some View {
        VStack(spacing: 14) {
            if document.enabledComponents.contains(.search) {
                searchBar
            }
            if document.enabledComponents.contains(.card) {
                wireCard(height: 92)
                wireCard(height: 92)
            }
            if document.enabledComponents.contains(.listRow) {
                row
                row
            }
        }
    }

    private var login: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 84)
            Circle()
                .stroke(Color.black.opacity(0.22), lineWidth: 2)
                .frame(width: 72, height: 72)
            inputLine(width: 260)
            inputLine(width: 260)
            button(width: 220)
        }
        .frame(maxWidth: .infinity)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            inputLine(width: 280)
            inputLine(width: 280)
            inputLine(width: 220)
            wireCard(height: 120)
            button(width: 160)
        }
    }

    private var chat: some View {
        VStack(spacing: 14) {
            message(width: 210, alignment: .leading)
            message(width: 250, alignment: .trailing)
            message(width: 180, alignment: .leading)
            Spacer().frame(height: 120)
            searchBar
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 16) {
            if document.enabledComponents.contains(.imagePlaceholder) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .frame(height: 180)
                    .overlay(Image(systemName: "photo").font(.system(size: 32)).foregroundColor(.gray))
            }
            wireCard(height: 70)
            row
            row
            if document.enabledComponents.contains(.button) {
                button(width: 160)
            }
        }
    }

    private var bottomNavigation: some View {
        HStack {
            ForEach(0..<4, id: \.self) { index in
                VStack(spacing: 6) {
                    Circle()
                        .fill(index == 0 ? Color.blue.opacity(0.65) : Color.black.opacity(0.24))
                        .frame(width: 18, height: 18)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.18))
                        .frame(width: 34, height: 6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.16))
                .frame(width: 140, height: 8)
            Spacer()
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func wireCard(height: CGFloat) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .frame(width: 72, height: 58)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 150, height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.14))
                    .frame(width: 210, height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.14))
                    .frame(width: 130, height: 8)
            }
            Spacer()
        }
        .padding(16)
        .frame(height: height)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.14), lineWidth: 1.5))
    }

    private var row: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                .frame(width: 32, height: 32)
            inputLine(width: 220)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func inputLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
            .frame(width: width, height: 42)
    }

    private func button(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blue.opacity(0.78))
            .frame(width: width, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: width * 0.42, height: 8)
            )
    }

    private func message(width: CGFloat, alignment: HorizontalAlignment) -> some View {
        HStack {
            if alignment == .trailing { Spacer() }
            RoundedRectangle(cornerRadius: 16)
                .fill(alignment == .trailing ? Color.blue.opacity(0.16) : Color.gray.opacity(0.14))
                .frame(width: width, height: 54)
            if alignment == .leading { Spacer() }
        }
    }

    private var note: some View {
        Text(PrototypingDraftDocument.annotationTextOrDefault(document.note))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.black.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.35), lineWidth: 1))
    }
}

private struct WebWireframe: View {
    let document: PrototypingDraftDocument

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 120, height: 14)
                Spacer()
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.16))
                        .frame(width: 70, height: 9)
                }
            }
            .padding(22)
            .overlay(Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1), alignment: .bottom)

            if document.template == .dashboard {
                dashboard
            } else {
                webHome
            }
        }
        .overlay(
            Group {
                if document.enabledComponents.contains(.aiNote) {
                    Text(PrototypingDraftDocument.annotationTextOrDefault(document.note))
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 78)
                        .padding(.trailing, 24)
                }
            },
            alignment: .topTrailing
        )
    }

    private var webHome: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 14) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.32)).frame(width: 250, height: 18)
                    RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.14)).frame(width: 340, height: 10)
                    RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.14)).frame(width: 300, height: 10)
                    RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.72)).frame(width: 140, height: 42)
                }
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.16), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .frame(height: 190)
            }

            HStack(spacing: 18) {
                webCard
                webCard
                webCard
            }
            Spacer()
        }
        .padding(28)
    }

    private var dashboard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(index == 0 ? Color.blue.opacity(0.22) : Color.black.opacity(0.12))
                        .frame(height: 24)
                }
                Spacer()
            }
            .frame(width: 150)
            .padding(20)
            .background(Color.gray.opacity(0.08))

            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    webCard
                    webCard
                    webCard
                }
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                    .frame(height: 210)
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack {
                            Circle().fill(Color.black.opacity(0.14)).frame(width: 24, height: 24)
                            RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.16)).frame(width: 180, height: 10)
                            Spacer()
                            RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.12)).frame(width: 72, height: 10)
                        }
                    }
                }
                .padding(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.12), lineWidth: 1.2))
            }
            .padding(24)
        }
    }

    private var webCard: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color.black.opacity(0.14), lineWidth: 1.5)
            .frame(height: 110)
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.22)).frame(width: 96, height: 11)
                    RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.12)).frame(width: 138, height: 9)
                }
                .padding(18),
                alignment: .leading
            )
    }
}
