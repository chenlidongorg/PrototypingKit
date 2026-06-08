import SwiftUI

@available(iOS 14.0, macCatalyst 14.0, *)
public struct PrototypingKitView: View {
    @ObservedObject private var store: PrototypingDraftStore
    private let onExport: (PrototypingExportResult) -> Void
    private let onClose: () -> Void

    @State private var alertMessage = ""
    @State private var showAlert = false

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
        .background(Color.white)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("原型设计测试版"), message: Text(alertMessage), dismissButton: .default(Text("好")))
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(PlainButtonStyle())

            TextField("标题", text: titleBinding)
                .font(.system(size: 20, weight: .semibold))
                .textFieldStyle(PlainTextFieldStyle())

            Button(action: store.createNewDraft) {
                Label("新建", systemImage: "plus")
            }

            Button(action: exportPDF) {
                Label("PDF", systemImage: "doc.richtext")
            }

            Button(action: exportForAI) {
                Label("导出给AI", systemImage: "sparkles")
            }

            Button(action: insertIntoHost) {
                Label("插入画布", systemImage: "square.and.arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var content: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                sidebar
                    .frame(width: min(max(proxy.size.width * 0.22, 210), 280))

                Divider()

                ScrollView([.vertical, .horizontal], showsIndicators: true) {
                    PrototypingDraftCanvas(document: store.currentDocument)
                        .frame(
                            width: store.currentDocument.canvasSize.cgSize.width,
                            height: store.currentDocument.canvasSize.cgSize.height
                        )
                        .padding(28)
                }
                .background(Color.gray.opacity(0.06))

                Divider()

                inspector
                    .frame(width: min(max(proxy.size.width * 0.25, 250), 330))
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近草稿")
                    .font(.headline)
                Spacer()
                Button(action: store.createNewDraft) {
                    Image(systemName: "plus.circle.fill")
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
                            store.openDraft(id: record.id)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                sectionTitle("草稿类型")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(PrototypingDraftKind.allCases) { kind in
                        ChoiceChip(title: kind.title, isSelected: store.currentDocument.kind == kind) {
                            store.update { document in
                                document.kind = kind
                                document.canvasSize = kind == .webPage ? .web : .phone
                                if document.template.kind != kind && kind == .webPage {
                                    document.template = .webHome
                                } else if kind == .appPage && document.template.kind != .appPage {
                                    document.template = .blankPhone
                                }
                            }
                        }
                    }
                }

                sectionTitle("模板")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                    ForEach(availableTemplates) { template in
                        TemplateCard(template: template, isSelected: store.currentDocument.template == template) {
                            store.update { document in
                                document.template = template
                                document.kind = template.kind
                                document.canvasSize = template.kind == .webPage ? .web : .phone
                            }
                        }
                    }
                }

                sectionTitle("常用组件")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(PrototypingComponent.allCases) { component in
                        ChoiceChip(
                            title: component.title,
                            isSelected: store.currentDocument.enabledComponents.contains(component)
                        ) {
                            store.update { document in
                                if document.enabledComponents.contains(component) {
                                    document.enabledComponents.removeAll { $0 == component }
                                } else {
                                    document.enabledComponents.append(component)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("AI标注")
                    TextField("例如：核心功能", text: noteBinding)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(16)
        }
    }

    private var availableTemplates: [PrototypingTemplate] {
        switch store.currentDocument.kind {
        case .webPage:
            return [.webHome, .dashboard]
        case .flowNote, .deviceShowcase, .appPage:
            return [.blankPhone, .login, .list, .detail, .form, .chat]
        }
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

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
    }

    private func insertIntoHost() {
        onExport(store.exportImage(recommendedIntent: .setAsBackground))
    }

    private func exportForAI() {
        onExport(store.exportImage(recommendedIntent: .sendToAI))
    }

    private func exportPDF() {
        do {
            let result = try store.exportPDF(recommendedIntent: .importAsNewPages)
            onExport(result)
        } catch {
            alertMessage = "PDF 导出失败：\(error.localizedDescription)"
            showAlert = true
        }
    }
}

private struct DraftRecordRow: View {
    let record: PrototypingDraftRecord
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.18) : Color.gray.opacity(0.12))
                .frame(width: 44, height: 52)
                .overlay(
                    Image(systemName: "rectangle.3.group")
                        .foregroundColor(isSelected ? .blue : .gray)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(formattedUpdatedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(isSelected ? Color.blue.opacity(0.08) : Color.clear)
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
                .foregroundColor(isSelected ? .blue : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? Color.blue.opacity(0.12) : Color.gray.opacity(0.08))
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
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.gray.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.55) : Color.black.opacity(0.08), lineWidth: 1)
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

            if template == .login {
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
