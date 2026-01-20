import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var portfolioSummary: PortfolioSummary?
    @Published var watchlistSummary: WatchlistSummary?
    @Published var activeStrategiesCount = 0
    @Published var activeFocusItemsCount = 0
    @Published var todayTriggers = 0
    @Published var recentActivity: [ActivityItem] = []
    @Published var isRefreshing = false

    private let apiService = APIService.shared
    private var userId: UUID?
    private var cancellables = Set<AnyCancellable>()

    struct PortfolioSummary {
        let totalValue: Double
        let todayChange: Double
        let todayChangePercent: Double
        let topPerformer: PortfolioItem?
        let worstPerformer: PortfolioItem?
        let itemCount: Int
    }

    struct WatchlistSummary {
        let itemCount: Int
        let upCount: Int
        let downCount: Int
    }

    struct ActivityItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let timestamp: Date
        let type: ActivityType
        let symbol: String?

        enum ActivityType {
            case strategyTrigger
            case priceAlert
            case newsEvent
            case focusUpdate
        }
    }

    func setUserId(_ userId: UUID) {
        self.userId = userId
        // 立即加载空状态数据
        loadEmptyState()
        // 后台静默加载数据
        Task {
            await loadDashboardData()
        }
    }

    private func loadEmptyState() {
        // 显示友好的空状态，不显示 loading
        portfolioSummary = nil
        watchlistSummary = nil
        activeStrategiesCount = 0
        activeFocusItemsCount = 0
        todayTriggers = 0
        recentActivity = []
    }

    func loadDashboardData() async {
        guard let userId = userId else {
            return
        }

        isRefreshing = true
        errorMessage = nil

        // 并行加载所有数据，超时 5 秒
        async let portfolio = loadPortfolioSummary(userId: userId)
        async let watchlist = loadWatchlistSummary(userId: userId)
        async let strategies = loadActiveStrategiesCount(userId: userId)
        async let focusItems = loadActiveFocusItemsCount(userId: userId)

        // 等待所有数据加载完成
        let (portfolioResult, watchlistResult, strategiesResult, focusResult) = await (portfolio, watchlist, strategies, focusItems)

        portfolioSummary = portfolioResult
        watchlistSummary = watchlistResult
        activeStrategiesCount = strategiesResult
        activeFocusItemsCount = focusResult

        // 加载最近活动
        await loadRecentActivity(userId: userId)

        isRefreshing = false
    }

    private func loadPortfolioSummary(userId: UUID) async -> PortfolioSummary? {
        do {
            let items = try await apiService.getPortfolio(userId: userId)

            guard !items.isEmpty else {
                return PortfolioSummary(
                    totalValue: 0,
                    todayChange: 0,
                    todayChangePercent: 0,
                    topPerformer: nil,
                    worstPerformer: nil,
                    itemCount: 0
                )
            }

            let totalValue = items.compactMap { $0.currentValue }.reduce(0, +)
            let totalProfitLoss = items.compactMap { $0.profitLoss }.reduce(0, +)

            let sortedByPL = items.filter { $0.profitLossPercent != nil }
                .sorted { ($0.profitLossPercent ?? 0) > ($1.profitLossPercent ?? 0) }

            return PortfolioSummary(
                totalValue: totalValue,
                todayChange: totalProfitLoss,
                todayChangePercent: totalValue > 0 ? (totalProfitLoss / totalValue) * 100 : 0,
                topPerformer: sortedByPL.first,
                worstPerformer: sortedByPL.last,
                itemCount: items.count
            )
        } catch {
            print("加载投资组合失败: \(error)")
            return nil
        }
    }

    private func loadWatchlistSummary(userId: UUID) async -> WatchlistSummary? {
        do {
            let items = try await apiService.getWatchlist(userId: userId)

            let upCount = items.filter { ($0.changePercent ?? 0) > 0 }.count
            let downCount = items.filter { ($0.changePercent ?? 0) < 0 }.count

            return WatchlistSummary(
                itemCount: items.count,
                upCount: upCount,
                downCount: downCount
            )
        } catch {
            print("加载关注列表失败: \(error)")
            return nil
        }
    }

    private func loadActiveStrategiesCount(userId: UUID) async -> Int {
        do {
            let strategies = try await apiService.getStrategies(userId: userId)
            return strategies.filter { $0.status == .active }.count
        } catch {
            print("加载策略失败: \(error)")
            return 0
        }
    }

    private func loadActiveFocusItemsCount(userId: UUID) async -> Int {
        do {
            let focusItems = try await apiService.getTemporaryFocus(userId: userId)
            return focusItems.filter { $0.status == .monitoring }.count
        } catch {
            print("加载临时关注失败: \(error)")
            return 0
        }
    }

    private func loadRecentActivity(userId: UUID) async {
        // 模拟最近活动数据
        recentActivity = [
            ActivityItem(
                title: "欢迎使用 InfoDigest",
                description: "开始添加您的投资组合和关注列表",
                timestamp: Date(),
                type: .newsEvent,
                symbol: nil
            )
        ]
    }

    func refreshData() {
        Task {
            await loadDashboardData()
        }
    }
}
