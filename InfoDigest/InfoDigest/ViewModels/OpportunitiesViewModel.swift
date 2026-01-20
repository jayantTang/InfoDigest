import Foundation
import Combine

@MainActor
class OpportunitiesViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var marketEvents: [MarketEvent] = []
    @Published var strategyAnalyses: [StrategyAnalysis] = []
    @Published var focusAnalyses: [FocusAnalysis] = []
    @Published var isRefreshing = false
    @Published var isEmpty = true
    @Published var hasConnectionError = false
    @Published var analysisStats: AnalysisStats?

    private let apiService = APIService.shared
    private var userId: UUID?

    struct MarketEvent: Identifiable, Codable {
        let id: UUID
        let title: String
        let description: String
        let source: String?
        let category: String
        let importanceScore: Int
        let publishedAt: Date
        let fetchedAt: Date?
        let symbols: [String]?
        let sectors: [String]?
        let isProcessed: Bool?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case description
            case source
            case category
            case importanceScore = "importance_score"
            case publishedAt = "published_at"
            case fetchedAt = "fetched_at"
            case symbols
            case sectors
            case isProcessed = "is_processed"
        }
    }

    struct StrategyAnalysis: Identifiable, Codable {
        let id: UUID
        let strategyId: UUID
        let userId: UUID
        let title: String
        let triggerReason: String
        let marketContext: String
        let technicalAnalysis: String
        let riskAssessment: String
        let actionSuggestion: String
        let confidence: Int
        let createdAt: Date
    }

    struct FocusAnalysis: Identifiable, Codable {
        let id: UUID
        let focusItemId: UUID
        let userId: UUID
        let title: String
        let summary: String
        let keyFindings: [String]
        let actionSuggestions: [String]
        let riskLevel: String
        let confidence: Int
        let createdAt: Date
    }

    struct AnalysisStats: Codable {
        let totalAnalyses: Int
        let avgConfidence: Double
        let totalEvents: Int
    }

    func setUserId(_ userId: UUID) {
        self.userId = userId
        // 后台静默加载数据
        Task {
            await loadOpportunities()
        }
    }

    func loadOpportunities() async {
        guard let userId = userId else {
            return
        }

        isRefreshing = true
        errorMessage = nil
        hasConnectionError = false

        // 并行加载所有数据
        async let events = loadMarketEvents()
        async let analyses = loadStrategyAnalyses(userId: userId)
        async let focus = loadFocusAnalyses(userId: userId)
        async let stats = loadAnalysisStats()

        // 等待所有数据加载完成
        await _ = events
        await _ = analyses
        await _ = focus
        await _ = stats

        // 检查是否有任何数据
        let hasData = !marketEvents.isEmpty || !strategyAnalyses.isEmpty || !focusAnalyses.isEmpty
        isEmpty = !hasData && !hasConnectionError

        isRefreshing = false
    }

    private func loadMarketEvents() async {
        do {
            let urlString = "\(apiService.baseURL)/monitoring/events"
            print("📡 请求URL: \(urlString)")
            print("📱 目标服务器: \(apiService.baseURL)")

            guard let url = URL(string: urlString) else {
                await MainActor.run {
                    hasConnectionError = true
                    errorMessage = "无效的服务器地址"
                }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    if let httpResponse = response as? HTTPURLResponse {
                        errorMessage = "服务器错误: \(httpResponse.statusCode)"
                    } else {
                        errorMessage = "无法连接到服务器"
                    }
                    hasConnectionError = true
                }
                return
            }

            let decoder = apiService.decoder
            let result = try decoder.decode(MarketEventsResponse.self, from: data)
            print("✅ 成功解码 \(result.data.events.count) 个市场事件")

            // 只显示高分事件（>= 60分）
            await MainActor.run {
                marketEvents = result.data.events.filter { $0.importanceScore >= 60 }
                print("✅ 过滤后显示 \(marketEvents.count) 个高分事件")
            }
        } catch {
            await MainActor.run {
                print("❌ 加载市场事件失败: \(error)")
                print("错误类型: \(type(of: error))")

                if let decodingError = error as? DecodingError {
                    print("🔍 JSON解码错误详情:")
                    print(decodingError)
                } else if let urlError = error as? URLError {
                    print("🌐 网络错误详情:")
                    print("  - 错误代码: \(urlError.code.rawValue)")
                    print("  - 错误描述: \(urlError.localizedDescription)")
                }

                hasConnectionError = true
                errorMessage = "无法加载市场事件: \(error.localizedDescription)"
            }
        }
    }

    private func loadStrategyAnalyses(userId: UUID) async {
        do {
            let urlString = "\(apiService.baseURL)/analysis/user/\(userId.uuidString)/strategies"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }

            let decoder = apiService.decoder
            let result = try decoder.decode(StrategyAnalysesResponse.self, from: data)
            await MainActor.run {
                strategyAnalyses = result.data
            }
        } catch {
            print("加载策略分析失败: \(error)")
        }
    }

    private func loadFocusAnalyses(userId: UUID) async {
        do {
            let urlString = "\(apiService.baseURL)/analysis/user/\(userId.uuidString)/focus"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }

            let decoder = apiService.decoder
            let result = try decoder.decode(FocusAnalysesResponse.self, from: data)
            await MainActor.run {
                focusAnalyses = result.data
            }
        } catch {
            print("加载关注分析失败: \(error)")
        }
    }

    private func loadAnalysisStats() async {
        do {
            let urlString = "\(apiService.baseURL)/analysis/stats"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }

            let decoder = apiService.decoder
            let result = try decoder.decode(AnalysisStatsResponse.self, from: data)
            await MainActor.run {
                analysisStats = result.data
            }
        } catch {
            print("加载分析统计失败: \(error)")
        }
    }

    func refreshData() {
        Task {
            await loadOpportunities()
        }
    }
}

// MARK: - Response Models

struct MarketEventsResponse: Codable {
    let success: Bool
    let data: MarketEventsData
}

struct MarketEventsData: Codable {
    let events: [OpportunitiesViewModel.MarketEvent]
    let count: Int
}

struct StrategyAnalysesResponse: Codable {
    let success: Bool
    let data: [OpportunitiesViewModel.StrategyAnalysis]
}

struct FocusAnalysesResponse: Codable {
    let success: Bool
    let data: [OpportunitiesViewModel.FocusAnalysis]
}

struct AnalysisStatsResponse: Codable {
    let success: Bool
    let data: OpportunitiesViewModel.AnalysisStats
}
