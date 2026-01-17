import Foundation
import Combine

/// 消息列表ViewModel
@MainActor
class MessageListViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: MessageType?
    @Published var useSampleData = false  // 开关：使用示例数据还是真实API

    private let apiService = APIService.shared

    /// 加载消息
    func loadMessages() async {
        isLoading = true
        errorMessage = nil

        do {
            if useSampleData {
                // 使用示例数据（离线模式）
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                messages = Message.sampleMessages
            } else {
                // 从服务器获取真实数据
                messages = try await apiService.fetchMessages()
            }
        } catch {
            errorMessage = error.localizedDescription
            print("加载消息失败: \(error)")
            // 如果加载失败，切换到示例数据
            if !useSampleData {
                useSampleData = true
                messages = Message.sampleMessages
                errorMessage = "无法连接服务器，已切换到示例数据"
            }
        }

        isLoading = false
    }

    /// 刷新消息
    func refreshMessages() async {
        await loadMessages()
    }

    /// 过滤消息
    var filteredMessages: [Message] {
        guard let filter = selectedFilter else {
            return messages
        }
        return messages.filter { $0.type == filter }
    }

    /// 标记消息为已读
    func markAsRead(_ message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].isRead = true
        }

        // 异步发送到服务器
        Task {
            try? await apiService.markAsRead(messageId: message.id)
        }
    }
}
