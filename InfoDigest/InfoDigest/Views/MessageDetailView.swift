import SwiftUI

struct MessageDetailView: View {
    let message: Message
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部信息
                    headerSection

                    // 富文本内容（Markdown）
                    richTextContent

                    // 图片展示
                    if let images = message.images, !images.isEmpty {
                        imagesSection(images)
                    }

                    // 链接列表
                    if let links = message.links, !links.isEmpty {
                        linksSection(links)
                    }
                }
                .padding()
            }
            .navigationTitle("消息详情")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareMessage) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 类型标签
            HStack {
                Image(systemName: message.type.icon)
                    .foregroundColor(.blue)

                Text(message.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(message.typeColor.opacity(0.15))
                    .foregroundColor(message.typeColor)
                    .cornerRadius(6)

                Spacer()

                Text(message.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 标题
            Text(message.title)
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    private var richTextContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("内容")
                .font(.headline)
                .foregroundColor(.secondary)

            // 使用Text的Markdown支持
            Text(parseMarkdown(message.contentRich))
                .font(.body)
                .textSelection(.enabled)
        }
    }

    private func imagesSection(_ images: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图片 (\(images.count))")
                .font(.headline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 280, height: 200)
                                    .overlay {
                                        ProgressView()
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 280, height: 200)
                                    .cornerRadius(12)
                                    .shadow(radius: 3)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 280, height: 200)
                                    .overlay {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
    }

    private func linksSection(_ links: [Message.Link]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关链接")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(links) { link in
                Button(action: {
                    if let url = URL(string: link.url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(link.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Text(link.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var typeColor: Color {
        switch message.type {
        case .news: return .blue
        case .stock: return .green
        case .digest: return .purple
        case .unknown: return .gray
        }
    }

    // 简单的Markdown解析
    private func parseMarkdown(_ markdown: String) -> AttributedString {
        var attributedString = AttributedString(markdown)

        // 自定义样式
        attributedString.font = .body

        return attributedString
    }

    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [message.title, message.summary],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

#Preview {
    MessageDetailView(message: Message.sampleMessages[0])
}
