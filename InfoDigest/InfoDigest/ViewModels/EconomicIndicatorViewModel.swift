import Foundation
import Combine

@MainActor
class EconomicIndicatorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var aStockIndices: [IndexData] = []
    @Published var usEtfIndices: [IndexData] = []
    @Published var commodities: [IndexData] = []
    @Published var forex: [IndexData] = []
    @Published var macroData: [String: MacroData] = [:]
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    @Published var isLoading = true
    @Published var nextRefreshCountdown: String = ""

    // MARK: - Private Properties

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    private let refreshInterval: TimeInterval = 30 * 60 // 30 minutes in seconds

    // MARK: - Initialization

    init() {
        // 加载示例数据用于预览（如果需要）
        // loadSampleData()

        // 自动加载数据
        Task {
            await loadIndicators()
        }

        // 启动倒计时
        startCountdownTimer()
    }

    // MARK: - Deinitialization

    deinit {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Public Methods

    /// 加载所有经济指标数据
    func loadIndicators() async {
        isRefreshing = true
        errorMessage = nil
        isLoading = true

        do {
            let indicators = try await apiService.getEconomicIndicators()

            // 更新所有数据
            aStockIndices = indicators.aStockIndices
            usEtfIndices = indicators.usEtfIndices
            commodities = indicators.commodities
            forex = indicators.forex
            macroData = indicators.macroData

            lastUpdateTime = Date()

            print("✅ 经济指标加载成功")
            print("- A股指数: \(aStockIndices.count) 个")
            print("- 美股ETF: \(usEtfIndices.count) 个")
            print("- 商品: \(commodities.count) 个")
            print("- 外汇: \(forex.count) 个")
            print("- 宏观数据: \(macroData.count) 个")

        } catch {
            print("❌ 加载经济指标失败: \(error)")
            errorMessage = "加载失败: \(error.localizedDescription)"
        }

        isRefreshing = false
        isLoading = false
    }

    /// 刷新数据
    func refreshData() {
        Task {
            await loadIndicators()
        }
    }

    // MARK: - Computed Properties

    /// 格式化的最后更新时间字符串
    var formattedLastUpdateTime: String {
        guard let lastUpdate = lastUpdateTime else {
            return "未更新"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }

    /// 是否有任何数据
    var hasData: Bool {
        !aStockIndices.isEmpty ||
        !usEtfIndices.isEmpty ||
        !commodities.isEmpty ||
        !forex.isEmpty ||
        !macroData.isEmpty
    }

    /// 是否有连接错误
    var hasConnectionError: Bool {
        errorMessage != nil && !hasData
    }

    /// 所有指数数据的总数
    var totalIndicesCount: Int {
        aStockIndices.count + usEtfIndices.count + commodities.count + forex.count
    }

    // MARK: - Private Methods

    /// 启动倒计时定时器
    private func startCountdownTimer() {
        // 停止之前的timer
        countdownTimer?.invalidate()

        // 每秒更新一次倒计时
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }

        // 立即更新一次
        updateCountdown()
    }

    /// 更新倒计时显示
    private func updateCountdown() {
        guard let lastUpdate = lastUpdateTime else {
            nextRefreshCountdown = ""
            return
        }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdate)
        let remaining = refreshInterval - elapsed

        if remaining <= 0 {
            nextRefreshCountdown = "即将刷新"
        } else if remaining < 60 {
            nextRefreshCountdown = "\(Int(remaining))秒后刷新"
        } else if remaining < 3600 {
            let minutes = Int(remaining / 60)
            let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
            nextRefreshCountdown = "\(minutes)分\(seconds)秒后刷新"
        } else {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            nextRefreshCountdown = "\(hours)小时\(minutes)分后刷新"
        }
    }

    // MARK: - Sample Data (for preview)

    /// 加载示例数据（仅用于开发和预览）
    private func loadSampleData() {
        let sample = EconomicIndicators.sampleData

        aStockIndices = sample.aStockIndices
        usEtfIndices = sample.usEtfIndices
        commodities = sample.commodities
        forex = sample.forex
        macroData = sample.macroData

        lastUpdateTime = Date().addingTimeInterval(-300) // 5分钟前
        isLoading = false
    }
}

// MARK: - Preview Helper

extension EconomicIndicatorViewModel {
    /// 用于预览的静态ViewModel
    static var preview: EconomicIndicatorViewModel {
        let viewModel = EconomicIndicatorViewModel()
        viewModel.loadSampleData()
        return viewModel
    }
}
