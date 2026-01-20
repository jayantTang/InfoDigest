import Foundation
import Combine

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var watchlistItems: [WatchlistItem] = []
    @Published var showAddSheet = false
    @Published var isRefreshing = false
    @Published var isEmpty = true

    private let apiService = APIService.shared
    private var userId: UUID?

    func setUserId(_ userId: UUID) {
        self.userId = userId
        // 后台静默加载数据
        Task {
            await loadWatchlist()
        }
    }

    func loadWatchlist() async {
        guard let userId = userId else {
            return
        }

        isRefreshing = true
        errorMessage = nil

        do {
            let items = try await apiService.getWatchlist(userId: userId)
            watchlistItems = items
            isEmpty = items.isEmpty
        } catch {
            // 静默失败
            print("加载关注列表失败: \(error)")
            isEmpty = true
        }

        isRefreshing = false
    }

    func addWatchlistItem(symbol: String, notes: String?) async {
        guard let userId = userId else { return }

        isRefreshing = true

        do {
            let newItem = try await apiService.addWatchlistItem(
                userId: userId,
                symbol: symbol,
                notes: notes
            )

            watchlistItems.append(newItem)
            isEmpty = false
            showAddSheet = false
        } catch {
            errorMessage = "添加关注失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func deleteWatchlistItem(_ item: WatchlistItem) async {
        isRefreshing = true

        do {
            try await apiService.deleteWatchlistItem(id: item.id)
            watchlistItems.removeAll { $0.id == item.id }
            isEmpty = watchlistItems.isEmpty
        } catch {
            errorMessage = "删除关注失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func refreshData() {
        Task {
            await loadWatchlist()
        }
    }
}
