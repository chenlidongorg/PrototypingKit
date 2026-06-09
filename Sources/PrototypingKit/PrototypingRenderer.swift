import SwiftUI
import UIKit

@MainActor
public enum PrototypingRenderer {
    public static func renderImage(document: PrototypingDraftDocument, hostCanvasSize: CGSize? = nil) -> UIImage {
        if let hostCanvasSize = normalizedHostCanvasSize(hostCanvasSize) {
            return render(
                view: PrototypingHostCanvasExportCanvas(
                    document: document,
                    hostCanvasSize: hostCanvasSize
                ),
                size: hostCanvasSize
            )
        }

        return render(
            view: PrototypingExportCanvas(document: document),
            size: PrototypingExportCanvas.outputSize(for: document)
        )
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
        let defaultSize = exportDocuments
            .first
            .map(PrototypingExportCanvas.outputSize(for:))
            ?? PrototypingExportCanvas.outputSize(for: PrototypingDraftDocument())
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: defaultSize))
        try renderer.writePDF(to: destinationURL) { context in
            for document in exportDocuments {
                let size = PrototypingExportCanvas.outputSize(for: document)
                let image = renderImage(document: document)
                context.beginPage(withBounds: CGRect(origin: .zero, size: size), pageInfo: [:])
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        return destinationURL
    }

    private static func normalizedHostCanvasSize(_ size: CGSize?) -> CGSize? {
        guard let size,
              size.width.isFinite,
              size.height.isFinite,
              size.width > 1,
              size.height > 1
        else {
            return nil
        }

        return CGSize(
            width: size.width.rounded(.toNearestOrAwayFromZero),
            height: size.height.rounded(.toNearestOrAwayFromZero)
        )
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
