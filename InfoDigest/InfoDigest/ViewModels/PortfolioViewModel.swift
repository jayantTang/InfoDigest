import Foundation
import Combine

@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var portfolioItems: [PortfolioItem] = []
    @Published var totalValue: Double = 0
    @Published var totalProfitLoss: Double = 0
    @Published var totalProfitLossPercent: Double = 0
    @Published var showAddSheet = false
    @Published var selectedItem: PortfolioItem?
    @Published var isRefreshing = false
    @Published var isEmpty = true

    private let apiService = APIService.shared
    private var userId: UUID?

    func setUserId(_ userId: UUID) {
        self.userId = userId
        // 后台静默加载数据
        Task {
            await loadPortfolio()
        }
    }

    func loadPortfolio() async {
        guard let userId = userId else {
            return
        }

        isRefreshing = true
        errorMessage = nil

        do {
            let items = try await apiService.getPortfolio(userId: userId)
            portfolioItems = items
            isEmpty = items.isEmpty
            calculateTotals()
        } catch {
            // 静默失败，不显示错误
            print("加载投资组合失败: \(error)")
            isEmpty = true
        }

        isRefreshing = false
    }

    func addPortfolioItem(symbol: String, shares: Double, averageCost: Double, assetType: String) async {
        guard let userId = userId else { return }

        isRefreshing = true

        do {
            let newItem = try await apiService.addPortfolioItem(
                userId: userId,
                symbol: symbol,
                shares: shares,
                averageCost: averageCost,
                assetType: assetType
            )

            portfolioItems.append(newItem)
            isEmpty = false
            calculateTotals()
            showAddSheet = false
        } catch {
            errorMessage = "添加持仓失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func deletePortfolioItem(_ item: PortfolioItem) async {
        isRefreshing = true

        do {
            try await apiService.deletePortfolioItem(id: item.id)
            portfolioItems.removeAll { $0.id == item.id }
            isEmpty = portfolioItems.isEmpty
            calculateTotals()
        } catch {
            errorMessage = "删除持仓失败: \(error.localizedDescription)"
        }

        isRefreshing = false
    }

    private func calculateTotals() {
        totalValue = portfolioItems.compactMap { $0.currentValue }.reduce(0, +)
        totalProfitLoss = portfolioItems.compactMap { $0.profitLoss }.reduce(0, +)

        let totalCost = portfolioItems.map { $0.totalCost }.reduce(0, +)
        totalProfitLossPercent = totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0
    }

    func refreshData() {
        Task {
            await loadPortfolio()
        }
    }
}
