import SwiftUI
import UIKit

@MainActor
public enum PrototypingRenderer {
    public static func renderImage(document: PrototypingDraftDocument) -> UIImage {
        render(view: PrototypingExportCanvas(document: document), size: document.canvasSize.cgSize)
    }

    public static func renderThumbnail(document: PrototypingDraftDocument) -> UIImage {
        render(
            view: PrototypingExportCanvas(document: document)
                .scaleEffect(0.25),
            size: CGSize(width: 156, height: 180)
        )
    }

    public static func renderPDF(documents: [PrototypingDraftDocument], destinationURL: URL) throws -> URL {
        let exportDocuments = documents.isEmpty ? [PrototypingDraftDocument()] : documents
        let defaultSize = exportDocuments.first?.canvasSize.cgSize ?? PrototypingCanvasSize.phone.cgSize
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: defaultSize))
        try renderer.writePDF(to: destinationURL) { context in
            for document in exportDocuments {
                let size = document.canvasSize.cgSize
                let image = renderImage(document: document)
                context.beginPage(withBounds: CGRect(origin: .zero, size: size), pageInfo: [:])
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        return destinationURL
    }

    private static func render<Content: View>(view: Content, size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .white

        let window = UIWindow(frame: controller.view.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
