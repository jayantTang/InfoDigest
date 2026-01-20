import Foundation
import Combine

@MainActor
class StrategiesViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var strategies: [Strategy] = []
    @Published var showCreateSheet = false
    @Published var selectedStrategy: Strategy?
    @Published var isRefreshing = false
    @Published var isEmpty = true

    private let apiService = APIService.shared
    private var userId: UUID?

    func setUserId(_ userId: UUID) {
        self.userId = userId
        // 后台静默加载数据
        Task {
            await loadStrategies()
        }
    }

    func loadStrategies() async {
        guard let userId = userId else {
            return
        }

        isRefreshing = true
        errorMessage = nil

        do {
            let items = try await apiService.getStrategies(userId: userId)
            strategies = items
            isEmpty = items.isEmpty
        } catch {
            print("加载策略失败: \(error)")
            isEmpty = true
        }

        isRefreshing = false
    }

    func createStrategy(
        symbol: String,
        name: String,
        conditionType: String,
        conditions: [String: Any],
        priority: Int
    ) async {
        guard let userId = userId else { return }

        isRefreshing = true

        do {
            let newStrategy = try await apiService.createStrategy(
                userId: userId,
                symbol: symbol,
                name: name,
                conditionType: conditionType,
                conditions: conditions,
                priority: priority
            )

            strategies.append(newStrategy)
            isEmpty = false
            showCreateSheet = false
        } catch {
            errorMessage = "创建策略失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func updateStrategyStatus(_ strategy: Strategy, status: Strategy.StrategyStatus) async {
        isRefreshing = true

        do {
            try await apiService.updateStrategyStatus(id: strategy.id, status: status.rawValue)
            if let index = strategies.firstIndex(where: { $0.id == strategy.id }) {
                strategies[index].status = status
            }
        } catch {
            errorMessage = "更新策略状态失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func deleteStrategy(_ strategy: Strategy) async {
        isRefreshing = true

        do {
            try await apiService.deleteStrategy(id: strategy.id)
            strategies.removeAll { $0.id == strategy.id }
            isEmpty = strategies.isEmpty
        } catch {
            errorMessage = "删除策略失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func refreshData() {
        Task {
            await loadStrategies()
        }
    }
}
