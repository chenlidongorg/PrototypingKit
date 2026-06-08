import SwiftUI

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
        ZStack {
            Color.white

            GridBackground()

            if document.kind == .webPage {
                WebWireframe(document: document)
            } else {
                PhoneWireframe(document: document)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: document.kind == .webPage ? 12 : 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: document.kind == .webPage ? 12 : 30, style: .continuous)
                .stroke(Color.black.opacity(0.16), lineWidth: 2)
        )
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
