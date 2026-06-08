import Foundation
import UIKit

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
        currentDocument.updatedAt = Date()
        currentDocument.revisionID = UUID().uuidString
        saveCurrentDocument()
    }

    public func applyTemplate(_ template: PrototypingTemplate) {
        update { document in
            let device = template.preferredDevice ?? (document.kind == .webPage ? .phone : document.device)
            document.template = template
            document.kind = template.kind
            document.device = device
            document.canvasSize = template.kind == .webPage ? .web : device.canvasSize
            document.elements = PrototypingDraftDocument.defaultElements(
                for: template,
                canvasSize: document.canvasSize
            )
            document.enabledComponents = uniqueComponents(in: document.elements)
        }
    }

    public func applyKind(_ kind: PrototypingDraftKind) {
        update { document in
            let template: PrototypingTemplate = kind == .webPage ? .webHome : .blankPhone
            let device: PrototypingDeviceKind = kind == .webPage ? document.device : (document.kind == .webPage ? .phone : document.device)
            document.kind = kind
            document.template = template
            document.device = device
            document.canvasSize = kind == .webPage ? .web : device.canvasSize
            document.elements = PrototypingDraftDocument.defaultElements(
                for: template,
                canvasSize: document.canvasSize
            )
            
            if kind == .flowNote {
                document.elements.append(
                    PrototypingCanvasElement(
                        component: .arrow,
                        title: PrototypingComponent.arrow.title,
                        frame: PrototypingElementFrame(x: 120, y: 610, width: 150, height: 42)
                    )
                )
            } else if kind == .deviceShowcase {
                document.elements.append(
                    PrototypingCanvasElement(
                        component: .imagePlaceholder,
                        title: PrototypingComponent.imagePlaceholder.title,
                        frame: PrototypingElementFrame(x: 74, y: 588, width: 242, height: 140)
                    )
                )
            }
            
            document.enabledComponents = uniqueComponents(in: document.elements)
        }
    }

    public func applyDevice(_ device: PrototypingDeviceKind) {
        guard currentDocument.kind != .webPage else { return }
        update { document in
            let oldSize = document.canvasSize.cgSize
            let newSize = device.canvasSize.cgSize
            document.device = device
            document.canvasSize = device.canvasSize
            document.elements = document.elements.map { element in
                var copy = element
                copy.frame = snappedFrame(
                    scaledFrame(copy.frame, from: oldSize, to: newSize),
                    canvasSize: newSize,
                    gridSize: CGFloat(document.gridSize)
                )
                return copy
            }
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
                    gridSize: CGFloat(nextGridSize)
                )
                return copy
            }
        }
    }

    public func addComponent(_ component: PrototypingComponent) {
        update { document in
            let frame = PrototypingDraftDocument.defaultFrame(
                for: component,
                canvasSize: document.canvasSize
            )
            document.elements.append(
                PrototypingCanvasElement(
                    component: component,
                    title: component.title,
                    frame: snappedFrame(
                        frame,
                        canvasSize: document.canvasSize.cgSize,
                        gridSize: CGFloat(document.gridSize)
                    )
                )
            )
            if !document.enabledComponents.contains(component) {
                document.enabledComponents.append(component)
            }
        }
    }

    public func bringElementToFront(id: String) {
        guard let index = currentDocument.elements.firstIndex(where: { $0.id == id }) else { return }
        var document = currentDocument
        let element = document.elements.remove(at: index)
        document.elements.append(element)
        currentDocument = document
    }

    public func snappedFrame(id _: String, proposedFrame: PrototypingElementFrame) -> PrototypingElementFrame {
        let canvasSize = currentDocument.canvasSize.cgSize
        return snappedFrame(
            proposedFrame,
            canvasSize: canvasSize,
            gridSize: CGFloat(currentDocument.gridSize)
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

    public func deleteElement(id: String) {
        update { document in
            document.elements.removeAll { $0.id == id }
            document.enabledComponents = uniqueComponents(in: document.elements)
        }
    }

    public func exportImage(recommendedIntent: PrototypingImportIntent = .setAsBackground) -> PrototypingExportResult {
        saveCurrentDocument()
        let image = PrototypingRenderer.renderImage(document: currentDocument)
        let metadata = metadata(recommendedIntent: recommendedIntent)
        return .image(image, metadata: metadata)
    }

    public func exportPDF(recommendedIntent: PrototypingImportIntent = .importAsNewPages) throws -> PrototypingExportResult {
        saveCurrentDocument()
        let url = try PrototypingRenderer.renderPDF(
            document: currentDocument,
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
        gridSize: CGFloat
    ) -> PrototypingElementFrame {
        let unit = max(4, gridSize)
        let width = min(canvasSize.width, max(unit * 2, snap(CGFloat(proposedFrame.width), unit: unit)))
        let height = min(canvasSize.height, max(unit * 2, snap(CGFloat(proposedFrame.height), unit: unit)))
        let x = min(max(0, snap(CGFloat(proposedFrame.x), unit: unit)), max(0, canvasSize.width - width))
        let y = min(max(0, snap(CGFloat(proposedFrame.y), unit: unit)), max(0, canvasSize.height - height))

        return PrototypingElementFrame(
            x: Double(x),
            y: Double(y),
            width: Double(width),
            height: Double(height)
        )
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
