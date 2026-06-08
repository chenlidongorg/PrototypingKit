import SwiftUI
import UIKit

struct PrototypingExportCanvas: View {
    let document: PrototypingDraftDocument

    var body: some View {
        PrototypingDraftCanvas(document: document)
            .padding(18)
            .background(Color.white)
    }
}

struct PrototypingDraftCanvas: View {
    let document: PrototypingDraftDocument

    var body: some View {
        canvasShell(cornerRadius: document.kind == .webPage ? 12 : 30) {
            if document.elements.isEmpty {
                if document.kind == .webPage {
                    WebWireframe(document: document)
                } else {
                    PhoneWireframe(document: document)
                }
            } else {
                PrototypingCanvasElementsLayer(
                    document: document,
                    selectedElementID: nil
                )
            }
        }
    }
}

struct PrototypingEditableDraftCanvas: View {
    let document: PrototypingDraftDocument
    let selectedElementID: String?
    let onSelect: (String) -> Void
    let onDeselect: () -> Void
    let onMove: (String, PrototypingElementFrame, Bool) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        canvasShell(cornerRadius: document.kind == .webPage ? 12 : 30) {
            PrototypingCanvasElementsLayer(
                document: document,
                selectedElementID: selectedElementID
            )
            PrototypingCanvasInteractionOverlay(
                document: document,
                onSelect: onSelect,
                onDeselect: onDeselect,
                onMove: onMove,
                onDelete: onDelete
            )
        }
    }
}

private func canvasShell<Content: View>(
    cornerRadius: CGFloat,
    @ViewBuilder content: () -> Content
) -> some View {
    ZStack {
        Color.white
        GridBackground()
        content()
    }
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.black.opacity(0.16), lineWidth: 2)
    )
}

private struct PrototypingCanvasElementsLayer: View {
    let document: PrototypingDraftDocument
    let selectedElementID: String?

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                ForEach(document.elements) { element in
                    PrototypingElementContainer(
                        element: element,
                        canvasSize: document.canvasSize.cgSize,
                        note: document.note,
                        isSelected: element.id == selectedElementID
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

    var body: some View {
        let rect = element.frame.cgRect

        PrototypingElementView(element: element, note: note)
            .frame(width: rect.width, height: rect.height)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.82) : Color.clear, lineWidth: 2)
            )
            .position(x: rect.midX, y: rect.midY)
    }
}

private struct PrototypingCanvasInteractionOverlay: View {
    let document: PrototypingDraftDocument
    let onSelect: (String) -> Void
    let onDeselect: () -> Void
    let onMove: (String, PrototypingElementFrame, Bool) -> Void
    let onDelete: (String) -> Void

    @State private var draggingElementID: String?
    @State private var draggingStartFrame: PrototypingElementFrame?

    var body: some View {
        PrototypingCanvasGestureView(
            canBeginPan: { point in
                hitElement(at: point) != nil
            },
            onSingleTap: { point in
                guard let element = hitElement(at: point) else {
                    onDeselect()
                    return
                }
                onSelect(element.id)
            },
            onDoubleTap: { point in
                guard let element = hitElement(at: point) else { return }
                onDelete(element.id)
            },
            onPanBegan: { point in
                guard let element = hitElement(at: point) else {
                    draggingElementID = nil
                    draggingStartFrame = nil
                    return
                }
                draggingElementID = element.id
                draggingStartFrame = element.frame
                onSelect(element.id)
            },
            onPanChanged: { _, translation in
                guard let draggingElementID, let draggingStartFrame else { return }
                let frame = draggingStartFrame.moved(by: translation, inside: document.canvasSize.cgSize)
                onMove(draggingElementID, frame, false)
            },
            onPanEnded: { _, translation in
                guard let draggingElementID, let draggingStartFrame else { return }
                let frame = draggingStartFrame.moved(by: translation, inside: document.canvasSize.cgSize)
                onMove(draggingElementID, frame, true)
                self.draggingElementID = nil
                self.draggingStartFrame = nil
            }
        )
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
            case .dialog:
                dialog(proxy.size)
            case .arrow:
                arrow(proxy.size)
            case .aiNote:
                noteView
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

    private func button(_ size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: min(12, size.height * 0.28))
            .fill(Color.blue.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.82))
                    .frame(width: size.width * 0.42, height: max(6, size.height * 0.16))
            )
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

    private var noteView: some View {
        Text(note.isEmpty ? "核心功能" : note)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.black.opacity(0.82))
            .lineLimit(2)
            .minimumScaleFactor(0.76)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let spacing: CGFloat = 24
                var x: CGFloat = 0
                while x <= proxy.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    x += spacing
                }

                var y: CGFloat = 0
                while y <= proxy.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    y += spacing
                }
            }
            .stroke(Color.gray.opacity(0.16), lineWidth: 1)
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
            case .list, .blankPhone, .webHome, .dashboard:
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
        Text(document.note.isEmpty ? "核心功能" : document.note)
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
                    Text(document.note.isEmpty ? "核心功能" : document.note)
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
