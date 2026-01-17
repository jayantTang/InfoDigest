import SwiftUI

struct MessageListView: View {
    @StateObject private var viewModel = MessageListViewModel()
    @State private var selectedMessage: Message?

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("重试") {
                            Task {
                                await viewModel.refreshMessages()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if viewModel.filteredMessages.isEmpty {
                    ContentUnavailableView {
                        Label("暂无消息", systemImage: "tray")
                    } description: {
                        Text("等待推送通知")
                    }
                } else {
                    messagesList
                }
            }
            .navigationTitle("消息列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全部") { withAnimation { viewModel.selectedFilter = nil } }
                        Divider()
                        ForEach(MessageType.allCases.filter({ $0 != .unknown }), id: \.self) { type in
                            Button(type.rawValue) {
                                withAnimation { viewModel.selectedFilter = type }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshMessages()
            }
            .task {
                if viewModel.messages.isEmpty {
                    await viewModel.loadMessages()
                }
            }
            .sheet(item: $selectedMessage) { message in
                MessageDetailView(message: message)
            }
        }
    }

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredMessages) { message in
                    MessageCard(message: message)
                        .onTapGesture {
                            viewModel.markAsRead(message)
                            selectedMessage = message
                        }
                }
            }
            .padding()
        }
    }
}

/// 消息卡片组件
struct MessageCard: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部：类型图标和标题
            HStack {
                Image(systemName: message.type.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(message.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(message.typeColor.opacity(0.2))
                            .foregroundColor(message.typeColor)
                            .cornerRadius(4)

                        Spacer()

                        Text(message.formattedTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 摘要
            Text(message.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // 底部：未读标记和图片预览
            HStack {
                if !message.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("未读")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                if let images = message.images, !images.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                        Text("\(images.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    private var typeColor: Color {
        switch message.type {
        case .news: return .blue
        case .stock: return .green
        case .digest: return .purple
        case .unknown: return .gray
        }
    }
}

#Preview {
    MessageListView()
}
