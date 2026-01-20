import Foundation
import Combine

@MainActor
class TemporaryFocusViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var focusItems: [TemporaryFocus] = []
    @Published var showCreateSheet = false
    @Published var isRefreshing = false
    @Published var isEmpty = true

    private let apiService = APIService.shared
    private var userId: UUID?

    func setUserId(_ userId: UUID) {
        self.userId = userId
        // 后台静默加载数据
        Task {
            await loadFocusItems()
        }
    }

    func loadFocusItems() async {
        guard let userId = userId else {
            return
        }

        isRefreshing = true
        errorMessage = nil

        do {
            let items = try await apiService.getTemporaryFocus(userId: userId)
            focusItems = items
            isEmpty = items.isEmpty
        } catch {
            print("加载临时关注失败: \(error)")
            isEmpty = true
        }

        isRefreshing = false
    }

    func createFocusItem(
        title: String,
        description: String?,
        targets: [String],
        focus: [String: Bool],
        expiresAt: String
    ) async {
        guard let userId = userId else { return }

        isRefreshing = true

        do {
            let newItem = try await apiService.createTemporaryFocus(
                userId: userId,
                title: title,
                description: description,
                targets: targets,
                focus: focus,
                expiresAt: expiresAt
            )

            focusItems.append(newItem)
            isEmpty = false
            showCreateSheet = false
        } catch {
            errorMessage = "创建临时关注失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func deleteFocusItem(_ item: TemporaryFocus) async {
        isRefreshing = true

        do {
            try await apiService.deleteTemporaryFocus(id: item.id)
            focusItems.removeAll { $0.id == item.id }
            isEmpty = focusItems.isEmpty
        } catch {
            errorMessage = "删除临时关注失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func refreshData() {
        Task {
            await loadFocusItems()
        }
    }
}
