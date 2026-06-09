import Foundation
import UIKit

public enum PrototypingDraftStoreError: LocalizedError {
    case emptyPDFExport

    public var errorDescription: String? {
        switch self {
        case .emptyPDFExport:
            return PrototypingL10n.text("error.empty_pdf_export")
        }
    }
}

@MainActor
public final class PrototypingDraftStore: ObservableObject {
    @Published public private(set) var records: [PrototypingDraftRecord] = []
    @Published public var currentDocument: PrototypingDraftDocument

    private let fileManager: FileManager
    private let rootURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.rootURL = rootURL ?? PrototypingDraftStore.defaultRootURL(fileManager: fileManager)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        self.currentDocument = PrototypingDraftDocument()

        ensureFolders()
        loadIndex()

        if let first = records.first, let document = loadDocument(id: first.id) {
            currentDocument = document
        } else {
            saveCurrentDocument()
        }
    }

    public static func defaultRootURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("PrototypingKitDocuments", isDirectory: true)
    }

    public func createNewDraft() {
        currentDocument = PrototypingDraftDocument()
        saveCurrentDocument()
    }

    public func openDraft(id: String) {
        guard let document = loadDocument(id: id) else { return }
        currentDocument = document
    }

    public func deleteDraft(id: String) {
        let folder = draftFolder(id: id)
        try? fileManager.removeItem(at: folder)
        records.removeAll { $0.id == id }
        saveIndex()

        if currentDocument.id == id {
            if let first = records.first, let document = loadDocument(id: first.id) {
                currentDocument = document
            } else {
                currentDocument = PrototypingDraftDocument()
                saveCurrentDocument()
            }
        }
    }

    public func update(_ transform: (inout PrototypingDraftDocument) -> Void) {
        transform(&currentDocument)
        currentDocument.syncActiveBoardFromCompatibilityFields()
        currentDocument.ensureStandardBoards()
        currentDocument.updatedAt = Date()
        currentDocument.revisionID = UUID().uuidString
        saveCurrentDocument()
    }

    public func renameDraft(id: String, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmedTitle.isEmpty ? PrototypingDraftDocument.defaultTitle() : trimmedTitle

        if currentDocument.id == id {
            update { document in
                document.title = resolvedTitle
            }
            return
        }

        guard var document = loadDocument(id: id) else { return }
        document.title = resolvedTitle
        document.updatedAt = Date()
        document.revisionID = UUID().uuidString
        saveDraftDocument(document)
    }

    public func applyTemplate(_ template: PrototypingTemplate) {
        update { document in
            let targetKind: PrototypingDraftKind = template.kind == .webPage ? .webPage : document.kind.normalized
            let targetDevice = template.preferredDevice ?? document.device
            let targetOrientation = document.orientation
            document.activateBoard(kind: targetKind, device: targetDevice, orientation: targetOrientation)
            document.template = template
            document.kind = targetKind
            document.device = targetDevice
            document.orientation = targetOrientation
            document.canvasSize = targetKind == .webPage ? .web : targetDevice.canvasSize(for: targetOrientation)
            document.elements = PrototypingDraftDocument.defaultElements(
                for: template,
                canvasSize: document.canvasSize
            )
            document.enabledComponents = uniqueComponents(in: document.elements)
        }
    }

    public func applyKind(_ kind: PrototypingDraftKind) {
        update { document in
            document.activateBoard(
                kind: kind.normalized,
                device: document.device,
                orientation: document.orientation
            )
        }
    }

    public func applyDevice(_ device: PrototypingDeviceKind) {
        guard currentDocument.kind != .webPage else { return }
        update { document in
            document.activateBoard(
                kind: .appPage,
                device: device,
                orientation: document.preferredOrientation(for: device)
            )
        }
    }

    public func applyOrientation(_ orientation: PrototypingDeviceOrientation) {
        guard currentDocument.kind != .webPage else { return }
        update { document in
            document.activateBoard(kind: .appPage, device: document.device, orientation: orientation)
        }
    }

    public func updateNote(_ note: String) {
        update { document in
            document.note = note
            document.resizeAnnotationElementsForCurrentNote()
        }
    }

    public func updateAnnotationText(id: String, text: String, persist: Bool) {
        guard let index = currentDocument.elements.firstIndex(where: { $0.id == id }),
              currentDocument.elements[index].component == .aiNote
        else { return }

        var document = currentDocument
        let resolvedText = PrototypingDraftDocument.annotationTextOrDefault(text)
        document.note = resolvedText
        document.elements[index].title = resolvedText
        document.elements[index].frame = PrototypingDraftDocument.annotationFrame(
            for: resolvedText,
            existingFrame: document.elements[index].frame,
            canvasSize: document.canvasSize.cgSize
        )

        if persist {
            document.updatedAt = Date()
            document.revisionID = UUID().uuidString
        }

        currentDocument = document
        if persist {
            saveCurrentDocument()
        }
    }

    public func updateGridSize(_ gridSize: Double) {
        update { document in
            let nextGridSize = max(8, min(32, gridSize))
            document.gridSize = nextGridSize
            document.elements = document.elements.map { element in
                var copy = element
                copy.frame = snappedFrame(
                    copy.frame,
                    canvasSize: document.canvasSize.cgSize,
                    gridSize: CGFloat(nextGridSize),
                    component: element.component
                )
                return copy
            }
        }
    }

    public func addComponent(_ component: PrototypingComponent, buttonStyle: PrototypingButtonStyle? = nil) {
        update { document in
            let baseFrame = PrototypingDraftDocument.defaultFrame(
                for: component,
                canvasSize: document.canvasSize
            )
            let annotationText = PrototypingDraftDocument.defaultAnnotationText
            let preferredFrame = component == .aiNote
                ? PrototypingDraftDocument.annotationFrame(
                    for: annotationText,
                    existingFrame: baseFrame,
                    canvasSize: document.canvasSize.cgSize
                )
                : baseFrame
            let frame = nextAvailableFrame(
                preferredFrame: preferredFrame,
                in: document,
                component: component
            )
            document.elements.append(
                PrototypingCanvasElement(
                    component: component,
                    title: component == .aiNote
                        ? annotationText
                        : component.title,
                    frame: frame,
                    buttonStyle: buttonStyle ?? .primary
                )
            )
            if !document.enabledComponents.contains(component) {
                document.enabledComponents.append(component)
            }
        }
    }

    public func updateButtonStyle(id: String, style: PrototypingButtonStyle, persist: Bool = true) {
        guard let index = currentDocument.elements.firstIndex(where: { $0.id == id }),
              currentDocument.elements[index].component == .button
        else { return }

        var document = currentDocument
        document.elements[index].buttonStyle = style

        if persist {
            document.updatedAt = Date()
            document.revisionID = UUID().uuidString
        }

        currentDocument = document
        if persist {
            saveCurrentDocument()
        }
    }

    public func bringElementToFront(id: String) {
        guard let index = currentDocument.elements.firstIndex(where: { $0.id == id }) else { return }
        var document = currentDocument
        let element = document.elements.remove(at: index)
        document.elements.append(element)
        currentDocument = document
    }

    public func snappedFrame(id: String, proposedFrame: PrototypingElementFrame) -> PrototypingElementFrame {
        let canvasSize = currentDocument.canvasSize.cgSize
        let component = currentDocument.elements.first { $0.id == id }?.component
        return snappedFrame(
            proposedFrame,
            canvasSize: canvasSize,
            gridSize: CGFloat(currentDocument.gridSize),
            component: component
        )
    }

    public func moveElement(id: String, to frame: PrototypingElementFrame, persist: Bool) {
        guard let index = currentDocument.elements.firstIndex(where: { $0.id == id }) else { return }
        var document = currentDocument
        document.elements[index].frame = frame
        if persist {
            document.updatedAt = Date()
            document.revisionID = UUID().uuidString
        }
        currentDocument = document
        if persist {
            saveCurrentDocument()
        }
    }

    public func moveElements(_ framesByID: [String: PrototypingElementFrame], persist: Bool) {
        guard !framesByID.isEmpty else { return }
        var document = currentDocument
        var didMove = false

        for index in document.elements.indices {
            guard let frame = framesByID[document.elements[index].id] else { continue }
            document.elements[index].frame = frame
            didMove = true
        }

        guard didMove else { return }

        if persist {
            document.updatedAt = Date()
            document.revisionID = UUID().uuidString
        }

        currentDocument = document
        if persist {
            saveCurrentDocument()
        }
    }

    public func updateAnnotationArrow(
        id: String,
        anchor: PrototypingAnnotationAnchor,
        target: CGPoint?,
        persist: Bool
    ) {
        guard let index = currentDocument.elements.firstIndex(where: { $0.id == id }),
              currentDocument.elements[index].component == .aiNote
        else { return }

        var document = currentDocument
        if let target {
            document.elements[index].annotationArrow = PrototypingAnnotationArrow(
                anchor: anchor,
                target: PrototypingCanvasPoint(target)
            )
        } else {
            document.elements[index].annotationArrow = nil
        }

        if persist {
            document.updatedAt = Date()
            document.revisionID = UUID().uuidString
        }

        currentDocument = document
        if persist {
            saveCurrentDocument()
        }
    }

    public func deleteElement(id: String) {
        update { document in
            document.elements.removeAll { $0.id == id }
            document.enabledComponents = uniqueComponents(in: document.elements)
        }
    }

    public func exportImage(
        recommendedIntent: PrototypingImportIntent = .setAsBackground,
        hostCanvasSize: CGSize? = nil
    ) -> PrototypingExportResult {
        saveCurrentDocument()
        let image = PrototypingRenderer.renderImage(
            document: currentDocument,
            hostCanvasSize: hostCanvasSize
        )
        let metadata = metadata(recommendedIntent: recommendedIntent)
        return .image(image, metadata: metadata)
    }

    public func exportPDF(
        recommendedIntent: PrototypingImportIntent = .importAsNewPages,
        boardIDs: [String]? = nil
    ) throws -> PrototypingExportResult {
        saveCurrentDocument()
        let exportDocuments = currentDocument.exportDocumentsForCurrentKind(boardIDs: boardIDs)
        guard !exportDocuments.isEmpty else {
            throw PrototypingDraftStoreError.emptyPDFExport
        }
        let url = try PrototypingRenderer.renderPDF(
            documents: exportDocuments,
            destinationURL: exportFolder(id: currentDocument.id)
                .appendingPathComponent("\(currentDocument.revisionID).pdf")
        )
        let metadata = metadata(recommendedIntent: recommendedIntent)
        return .pdf(url, metadata: metadata)
    }

    public func thumbnailURL(for record: PrototypingDraftRecord) -> URL? {
        guard let thumbnailFileName = record.thumbnailFileName else { return nil }
        return draftFolder(id: record.id).appendingPathComponent(thumbnailFileName)
    }

    private func metadata(recommendedIntent: PrototypingImportIntent) -> PrototypingExportMetadata {
        PrototypingExportMetadata(
            draftID: currentDocument.id,
            revisionID: currentDocument.revisionID,
            title: currentDocument.title,
            recommendedIntent: recommendedIntent
        )
    }

    private func ensureFolders() {
        try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: rootURL.appendingPathComponent("drafts", isDirectory: true), withIntermediateDirectories: true)
    }

    private func loadIndex() {
        let url = indexURL
        guard let data = try? Data(contentsOf: url),
              let records = try? decoder.decode([PrototypingDraftRecord].self, from: data)
        else {
            self.records = []
            return
        }
        self.records = records.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func saveIndex() {
        guard let data = try? encoder.encode(records.sorted(by: { $0.updatedAt > $1.updatedAt })) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    private func saveCurrentDocument() {
        ensureFolders()
        currentDocument.syncActiveBoardFromCompatibilityFields()
        currentDocument.ensureStandardBoards()
        let folder = draftFolder(id: currentDocument.id)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: exportFolder(id: currentDocument.id), withIntermediateDirectories: true)

        if let data = try? encoder.encode(currentDocument) {
            try? data.write(to: folder.appendingPathComponent("document.json"), options: .atomic)
        }

        writeThumbnail(for: currentDocument)
        upsertRecord(currentDocument.record)
        saveIndex()
    }

    private func loadDocument(id: String) -> PrototypingDraftDocument? {
        let url = draftFolder(id: id).appendingPathComponent("document.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(PrototypingDraftDocument.self, from: data)
    }

    private func saveDraftDocument(_ draftDocument: PrototypingDraftDocument) {
        ensureFolders()
        var document = draftDocument
        document.syncActiveBoardFromCompatibilityFields()
        document.ensureStandardBoards()

        let folder = draftFolder(id: document.id)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: exportFolder(id: document.id), withIntermediateDirectories: true)

        if let data = try? encoder.encode(document) {
            try? data.write(to: folder.appendingPathComponent("document.json"), options: .atomic)
        }

        writeThumbnail(for: document)
        upsertRecord(document.record)
        saveIndex()
    }

    private func upsertRecord(_ record: PrototypingDraftRecord) {
        records.removeAll { $0.id == record.id }
        records.insert(record, at: 0)
        records = records.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func uniqueComponents(in elements: [PrototypingCanvasElement]) -> [PrototypingComponent] {
        var result: [PrototypingComponent] = []
        for element in elements where !result.contains(element.component) {
            result.append(element.component)
        }
        return result
    }

    private func snappedFrame(
        _ proposedFrame: PrototypingElementFrame,
        canvasSize: CGSize,
        gridSize: CGFloat,
        component: PrototypingComponent? = nil
    ) -> PrototypingElementFrame {
        let unit = max(4, gridSize)
        let minimumSize = component.map(PrototypingDraftDocument.minimumSize(for:))
            ?? CGSize(width: unit * 2, height: unit * 2)
        let maximumSize = component.map {
            PrototypingDraftDocument.maximumSize(for: $0, canvasSize: canvasSize)
        } ?? canvasSize
        let constrained = proposedFrame.constrained(
            inside: canvasSize,
            minimumSize: minimumSize,
            maximumSize: maximumSize
        )
        let width = min(
            maximumSize.width,
            max(minimumSize.width, snap(CGFloat(constrained.width), unit: unit))
        )
        let height = min(
            maximumSize.height,
            max(minimumSize.height, snap(CGFloat(constrained.height), unit: unit))
        )
        let x = min(max(0, snap(CGFloat(constrained.x), unit: unit)), max(0, canvasSize.width - width))
        let y = min(max(0, snap(CGFloat(constrained.y), unit: unit)), max(0, canvasSize.height - height))

        return PrototypingElementFrame(
            x: Double(x),
            y: Double(y),
            width: Double(width),
            height: Double(height)
        )
    }

    private func nextAvailableFrame(
        preferredFrame: PrototypingElementFrame,
        in document: PrototypingDraftDocument,
        component: PrototypingComponent
    ) -> PrototypingElementFrame {
        let canvasSize = document.canvasSize.cgSize
        let unit = max(4, CGFloat(document.gridSize))
        let preferred = snappedFrame(
            preferredFrame,
            canvasSize: canvasSize,
            gridSize: unit,
            component: component
        )

        if hasRoom(for: preferred, in: document, padding: unit) {
            return preferred
        }

        let width = CGFloat(preferred.width)
        let height = CGFloat(preferred.height)
        let maxX = max(0, canvasSize.width - width)
        let maxY = max(0, canvasSize.height - height)
        let xPositions = gridPositions(maxValue: maxX, unit: unit)
        let yPositions = gridPositions(maxValue: maxY, unit: unit)

        let candidates = xPositions.flatMap { x in
            yPositions.map { y in
                PrototypingElementFrame(
                    x: Double(x),
                    y: Double(y),
                    width: preferred.width,
                    height: preferred.height
                )
            }
        }
        .sorted { lhs, rhs in
            distance(from: lhs, to: preferred) < distance(from: rhs, to: preferred)
        }

        return candidates.first { hasRoom(for: $0, in: document, padding: unit) } ?? preferred
    }

    private func hasRoom(
        for frame: PrototypingElementFrame,
        in document: PrototypingDraftDocument,
        padding: CGFloat
    ) -> Bool {
        let rect = frame.cgRect
        let canvasRect = CGRect(origin: .zero, size: document.canvasSize.cgSize)

        guard canvasRect.contains(rect) else { return false }

        return document.elements.allSatisfy { element in
            !rect.intersects(element.frame.cgRect.insetBy(dx: -padding, dy: -padding))
        }
    }

    private func gridPositions(maxValue: CGFloat, unit: CGFloat) -> [CGFloat] {
        guard maxValue > 0 else { return [0] }

        var values: [CGFloat] = []
        var value: CGFloat = 0

        while value <= maxValue {
            values.append(value)
            value += unit
        }

        if values.last != maxValue {
            values.append(maxValue)
        }

        return values
    }

    private func distance(
        from lhs: PrototypingElementFrame,
        to rhs: PrototypingElementFrame
    ) -> Double {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y)
    }

    private func scaledFrame(
        _ frame: PrototypingElementFrame,
        from oldSize: CGSize,
        to newSize: CGSize
    ) -> PrototypingElementFrame {
        guard oldSize.width > 0, oldSize.height > 0 else { return frame }
        let scaleX = newSize.width / oldSize.width
        let scaleY = newSize.height / oldSize.height
        return PrototypingElementFrame(
            x: frame.x * Double(scaleX),
            y: frame.y * Double(scaleY),
            width: frame.width * Double(scaleX),
            height: frame.height * Double(scaleY)
        )
    }

    private func snap(_ value: CGFloat, unit: CGFloat) -> CGFloat {
        guard unit > 0 else { return value }
        return (value / unit).rounded() * unit
    }

    private func writeThumbnail(for document: PrototypingDraftDocument) {
        let image = PrototypingRenderer.renderThumbnail(document: document)
        guard let data = image.pngData() else { return }
        try? data.write(to: draftFolder(id: document.id).appendingPathComponent("thumbnail.png"), options: .atomic)
    }

    private var indexURL: URL {
        rootURL.appendingPathComponent("index.json")
    }

    private func draftFolder(id: String) -> URL {
        rootURL
            .appendingPathComponent("drafts", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
    }

    private func exportFolder(id: String) -> URL {
        draftFolder(id: id).appendingPathComponent("exports", isDirectory: true)
    }
}
