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
            document.template = template
            document.kind = template.kind
            document.canvasSize = template.kind == .webPage ? .web : .phone
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
            document.kind = kind
            document.template = template
            document.canvasSize = kind == .webPage ? .web : .phone
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
                    frame: frame
                )
            )
            if !document.enabledComponents.contains(component) {
                document.enabledComponents.append(component)
            }
        }
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
