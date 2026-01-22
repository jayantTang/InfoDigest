import Foundation
import SwiftUI

// MARK: - Platform Enum
enum Platform: String {
    case ios = "ios"
    case android = "android"
}

// MARK: - Domain Models (defined first to avoid forward references)

struct User: Identifiable, Codable {
    let id: UUID
    var email: String?
    var username: String?
    var preferences: UserPreferences?
    var createdAt: Date
    var updatedAt: Date

    struct UserPreferences: Codable {
        var pushEnabled: Bool
        var timezone: String?
        var currency: String?
        var language: String?

        enum CodingKeys: String, CodingKey {
            case pushEnabled = "push_enabled"
            case timezone
            case currency
            case language
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PortfolioItem: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let symbol: String
    var shares: Double
    let averageCost: Double
    let assetType: AssetType
    var currentPrice: Double?
    var currentValue: Double?
    var profitLoss: Double?
    var profitLossPercent: Double?
    let createdAt: Date
    var updatedAt: Date

    enum AssetType: String, Codable {
        case stock = "stock"
        case etf = "etf"
        case crypto = "crypto"
        case bond = "bond"
        case other = "other"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbol
        case shares
        case averageCost = "average_cost"
        case assetType = "asset_type"
        case currentPrice = "current_price"
        case currentValue = "current_value"
        case profitLoss = "profit_loss"
        case profitLossPercent = "profit_loss_percent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var totalCost: Double {
        return shares * averageCost
    }

    var profitLossColor: Color {
        guard let pl = profitLossPercent else { return .gray }
        return pl >= 0 ? .green : .red
    }
}

struct WatchlistItem: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let symbol: String
    var notes: String?
    var currentPrice: Double?
    var changePercent: Double?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbol
        case notes
        case currentPrice = "current_price"
        case changePercent = "change_percent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var changeColor: Color {
        guard let change = changePercent else { return .gray }
        return change >= 0 ? .green : .red
    }
}

struct Strategy: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let symbol: String
    var name: String
    let conditionType: StrategyConditionType
    var conditions: StrategyConditions
    let action: StrategyAction
    var priority: Int
    var status: StrategyStatus
    var lastTriggeredAt: Date?
    var triggerCount: Int
    let createdAt: Date
    var updatedAt: Date

    enum StrategyConditionType: String, Codable {
        case price = "price"
        case technical = "technical"
        case news = "news"
        case time = "time"
    }

    enum StrategyAction: String, Codable {
        case notify = "notify"
        case alert = "alert"
        case autoTrade = "auto_trade"
    }

    enum StrategyStatus: String, Codable {
        case active = "active"
        case paused = "paused"
        case disabled = "disabled"
    }

    struct StrategyConditions: Codable {
        var priceAbove: Double?
        var priceBelow: Double?
        var percentChange: Double?
        var rsi: RSICondition?
        var macd: MACDCondition?
        var bollinger: BollingerCondition?
        var minImportance: Int?
        var categories: [String]?
        var timeRange: TimeRange?
        var dayOfWeek: Int?

        struct RSICondition: Codable {
            var above: Double?
            var below: Double?
        }

        struct MACDCondition: Codable {
            var crossoverAbove: Bool?
            var crossoverBelow: Bool?
        }

        struct BollingerCondition: Codable {
            var touchUpper: Bool?
            var touchLower: Bool?
        }

        struct TimeRange: Codable {
            let start: String
            let end: String
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbol
        case name
        case conditionType = "condition_type"
        case conditions
        case action
        case priority
        case status
        case lastTriggeredAt = "last_triggered_at"
        case triggerCount = "trigger_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TemporaryFocus: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let title: String
    var description: String?
    let targets: [String]
    let focus: FocusConfiguration
    let expiresAt: Date
    var status: FocusStatus
    var findings: [String]?
    var createdAt: Date
    var updatedAt: Date

    enum FocusStatus: String, Codable {
        case monitoring = "monitoring"
        case completed = "completed"
        case cancelled = "cancelled"
        case extended = "extended"
    }

    struct FocusConfiguration: Codable {
        var newsImpact: Bool
        var priceReaction: Bool
        var correlation: Bool
        var sectorEffect: Bool
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case targets
        case focus
        case expiresAt = "expires_at"
        case status
        case findings
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MonitoringStatus: Codable {
    let isRunning: Bool
    let checkInterval: Int
    let lastCheck: Date?
    let queueSize: Int

    enum CodingKeys: String, CodingKey {
        case isRunning = "isRunning"
        case checkInterval = "checkInterval"
        case lastCheck = "lastCheck"
        case queueSize = "queueSize"
    }
}

struct MonitoringMetrics: Codable {
    let strategies: StrategyMetrics
    let focusItems: FocusMetrics
    let events: EventMetrics
}

struct StrategyMetrics: Codable {
    let totalStrategies: Int
    let activeStrategies: Int
    let totalTriggers: Int
}

struct FocusMetrics: Codable {
    let totalFocusItems: Int
    let activeFocusItems: Int
}

struct EventMetrics: Codable {
    let totalEvents: Int
    let criticalEvents: Int
    let processedEvents: Int
}

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
    let message: String?
}

// MARK: - Response Data Types (can now reference domain models)
struct DeviceRegistrationResponse: Codable {
    let userId: UUID
    let deviceId: UUID
    let message: String
}

struct UserData: Codable {
    let user: User
}

struct PortfolioData: Codable {
    let items: [PortfolioItem]
}

struct PortfolioItemData: Codable {
    let item: PortfolioItem
}

struct WatchlistData: Codable {
    let items: [WatchlistItem]
}

struct WatchlistItemData: Codable {
    let item: WatchlistItem
}

struct StrategiesData: Codable {
    let strategies: [Strategy]
}

struct StrategyData: Codable {
    let strategy: Strategy
}

struct FocusData: Codable {
    let focusItems: [TemporaryFocus]
}

struct FocusItemData: Codable {
    let focusItem: TemporaryFocus
}

struct MonitoringData: Codable {
    let monitoring: MonitoringStatus
}

struct HistoricalChangesResponse: Codable {
    let success: Bool
    let data: PriceChangesData

    struct PriceChangesData: Codable {
        let oneDay: ChangeData?
        let oneWeek: ChangeData?
        let oneMonth: ChangeData?
        let threeMonths: ChangeData?
        let oneYear: ChangeData?
        let threeYears: ChangeData?

        struct ChangeData: Codable {
            let value: String?     // Optional: may be nil when available=false
            let available: Bool
        }

        private enum CodingKeys: String, CodingKey {
            case oneDay = "1d"
            case oneWeek = "1w"
            case oneMonth = "1m"
            case threeMonths = "3m"
            case oneYear = "1y"
            case threeYears = "3y"
        }
    }
}

// MARK: - Message Response Types (v1 compatibility)
private struct MessageResponse: Codable {
    let success: Bool
    let data: MessageData
}

private struct MessageData: Codable {
    let messages: [Message]
    let pagination: Pagination
}

private struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

// MARK: - API Service
class APIService {
    static let shared = APIService()

    // 根据运行环境自动选择服务器地址
    #if targetEnvironment(simulator)
    internal let baseURL = "http://localhost:3000/api"
    #else
    internal let baseURL = "http://192.168.1.93:3000/api"
    #endif

    private let session = URLSession.shared

    private init() {}

    internal var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }

            throw APIError.decodingError
        }
        return decoder
    }

    // MARK: - v1.0 API Methods

    /// 注册设备token (v1)
    func registerDevice(token: String) async throws {
        let url = URL(string: "\(baseURL)/devices/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "deviceToken": token,
            "platform": "ios"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 获取消息历史
    func fetchMessages(page: Int = 1, limit: Int = 20) async throws -> [Message] {
        var components = URLComponents(string: "\(baseURL)/messages")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let result = try decoder.decode(MessageResponse.self, from: data)
        return result.data.messages
    }

    /// 获取消息详情
    func fetchMessageDetail(id: UUID) async throws -> Message {
        let url = URL(string: "\(baseURL)/messages/\(id.uuidString)")!

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(Message.self, from: data)
    }

    /// 标记消息为已读
    func markAsRead(messageId: UUID) async throws {
        let url = URL(string: "\(baseURL)/messages/\(messageId.uuidString)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - v2.0 API Methods

    /// 注册设备token（v2版本，返回用户ID）
    func registerDeviceV2(token: String, platform: Platform = .ios, appVersion: String? = nil, osVersion: String? = nil) async throws -> DeviceRegistrationResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/devices/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "deviceToken": token,
            "platform": platform.rawValue
        ]

        if let appVersion = appVersion {
            body["appVersion"] = appVersion
        }
        if let osVersion = osVersion {
            body["osVersion"] = osVersion
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        return try decoder.decode(APIResponse<DeviceRegistrationResponse>.self, from: data).data!
    }

    /// 获取用户信息
    func getUser(id: UUID) async throws -> User {
        let (data, _) = try await fetchData(endpoint: "/users/\(id.uuidString)")
        let response = try decoder.decode(APIResponse<UserData>.self, from: data)
        return response.data!.user
    }

    /// 更新用户偏好
    func updateUserPreferences(id: UUID, preferences: User.UserPreferences) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/users/\(id.uuidString)/preferences")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "preferences": [
                "push_enabled": preferences.pushEnabled,
                "timezone": preferences.timezone ?? "",
                "currency": preferences.currency ?? "",
                "language": preferences.language ?? ""
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 获取投资组合
    func getPortfolio(userId: UUID) async throws -> [PortfolioItem] {
        let (data, _) = try await fetchData(endpoint: "/portfolios?user_id=\(userId.uuidString)")
        let response = try decoder.decode(APIResponse<PortfolioData>.self, from: data)
        return response.data!.items
    }

    /// 添加持仓
    func addPortfolioItem(userId: UUID, symbol: String, shares: Double, averageCost: Double, assetType: String = "stock") async throws -> PortfolioItem {
        var request = URLRequest(url: URL(string: "\(baseURL)/portfolios/items")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId.uuidString,
            "symbol": symbol.uppercased(),
            "shares": shares,
            "averageCost": averageCost,
            "assetType": assetType
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(APIResponse<PortfolioItemData>.self, from: data)
        return response.data!.item
    }

    /// 删除持仓
    func deletePortfolioItem(id: UUID) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/portfolios/items/\(id.uuidString)")!)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 获取关注列表
    func getWatchlist(userId: UUID) async throws -> [WatchlistItem] {
        let (data, _) = try await fetchData(endpoint: "/watchlists?user_id=\(userId.uuidString)")
        let response = try decoder.decode(APIResponse<WatchlistData>.self, from: data)
        return response.data!.items
    }

    /// 添加关注
    func addWatchlistItem(userId: UUID, symbol: String, notes: String? = nil) async throws -> WatchlistItem {
        var request = URLRequest(url: URL(string: "\(baseURL)/watchlists/items")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "userId": userId.uuidString,
            "symbol": symbol.uppercased()
        ]

        if let notes = notes {
            body["notes"] = notes
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(APIResponse<WatchlistItemData>.self, from: data)
        return response.data!.item
    }

    /// 删除关注
    func deleteWatchlistItem(id: UUID) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/watchlists/items/\(id.uuidString)")!)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 获取策略列表
    func getStrategies(userId: UUID? = nil) async throws -> [Strategy] {
        var endpoint = "/strategies"
        if let userId = userId {
            endpoint += "?user_id=\(userId.uuidString)"
        }

        let (data, _) = try await fetchData(endpoint: endpoint)
        let response = try decoder.decode(APIResponse<StrategiesData>.self, from: data)
        return response.data!.strategies
    }

    /// 创建策略
    func createStrategy(userId: UUID, symbol: String, name: String, conditionType: String, conditions: [String: Any], priority: Int = 50) async throws -> Strategy {
        var request = URLRequest(url: URL(string: "\(baseURL)/strategies")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId.uuidString,
            "symbol": symbol.uppercased(),
            "name": name,
            "conditionType": conditionType,
            "conditions": conditions,
            "action": "notify",
            "priority": priority
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(APIResponse<StrategyData>.self, from: data)
        return response.data!.strategy
    }

    /// 更新策略状态
    func updateStrategyStatus(id: UUID, status: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/strategies/\(id.uuidString)/status")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["status": status]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 删除策略
    func deleteStrategy(id: UUID) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/strategies/\(id.uuidString)")!)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 获取临时关注列表
    func getTemporaryFocus(userId: UUID) async throws -> [TemporaryFocus] {
        let (data, _) = try await fetchData(endpoint: "/temporary-focus?user_id=\(userId.uuidString)")
        let response = try decoder.decode(APIResponse<FocusData>.self, from: data)
        return response.data!.focusItems
    }

    /// 创建临时关注
    func createTemporaryFocus(userId: UUID, title: String, description: String?, targets: [String], focus: [String: Bool], expiresAt: String) async throws -> TemporaryFocus {
        var request = URLRequest(url: URL(string: "\(baseURL)/temporary-focus")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "userId": userId.uuidString,
            "title": title,
            "targets": targets.map { $0.uppercased() },
            "focus": focus,
            "expiresAt": expiresAt
        ]

        if let desc = description {
            body["description"] = desc
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(APIResponse<FocusItemData>.self, from: data)
        return response.data!.focusItem
    }

    /// 删除临时关注
    func deleteTemporaryFocus(id: UUID) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/temporary-focus/\(id.uuidString)")!)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    /// 获取监控状态
    func getMonitoringStatus() async throws -> MonitoringStatus {
        let (data, _) = try await fetchData(endpoint: "/monitoring/status")
        let response = try decoder.decode(APIResponse<MonitoringData>.self, from: data)
        return response.data!.monitoring
    }

    /// 获取监控指标
    func getMonitoringMetrics() async throws -> MonitoringMetrics {
        let (data, _) = try await fetchData(endpoint: "/monitoring/metrics")
        return try decoder.decode(APIResponse<MonitoringMetrics>.self, from: data).data!
    }

    /// 获取经济指标数据
    func getEconomicIndicators() async throws -> EconomicIndicators {
        let (data, _) = try await fetchData(endpoint: "/economic-indicators")
        return try decoder.decode(APIResponse<EconomicIndicators>.self, from: data).data!
    }

    /// 获取某个指数的历史涨跌幅
    func getHistoricalChanges(symbol: String) async throws -> HistoricalChangesResponse.PriceChangesData {
        let endpoint = "/api/historical-changes/\(symbol)"

        let response: HistoricalChangesResponse = try await performRequest(endpoint: endpoint)

        if !response.success {
            throw APIError.requestFailed("Failed to fetch historical changes")
        }

        return response.data
    }

    // MARK: - Helper Methods

    private func fetchData(endpoint: String) async throws -> (Data, URLResponse) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        return try await session.data(from: url)
    }

    private func performRequest<T: Codable>(endpoint: String) async throws -> T {
        let (data, response) = try await fetchData(endpoint: endpoint)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}

// MARK: - Analysis Types

struct StrategyTrigger: Identifiable, Codable {
    let id: UUID
    let strategyId: UUID
    let symbol: String
    let conditionType: Strategy.StrategyConditionType
    let triggerReason: String
    let marketData: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case strategyId = "strategy_id"
        case symbol
        case conditionType = "condition_type"
        case triggerReason = "trigger_reason"
        case marketData = "market_data"
        case createdAt = "created_at"
    }
}

struct StrategyAnalysis: Identifiable, Codable {
    let id: UUID
    let strategyId: UUID
    let userId: UUID
    let title: String
    let triggerReason: String?
    let marketContext: String?
    let technicalAnalysis: String?
    let riskAssessment: String?
    let actionSuggestion: String?
    let confidence: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case strategyId = "strategy_id"
        case userId = "user_id"
        case title
        case triggerReason = "trigger_reason"
        case marketContext = "market_context"
        case technicalAnalysis = "technical_analysis"
        case riskAssessment = "risk_assessment"
        case actionSuggestion = "action_suggestion"
        case confidence
        case createdAt = "created_at"
    }
}

struct FocusFinding: Identifiable, Codable {
    let id: UUID
    let focusItemId: UUID
    let title: String
    let description: String
    let importance: Int
    let category: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case focusItemId = "focus_item_id"
        case title
        case description
        case importance
        case category
        case createdAt = "created_at"
    }
}

struct FocusAnalysis: Identifiable, Codable {
    let id: UUID
    let focusItemId: UUID
    let userId: UUID
    let title: String
    let summary: String?
    let keyFindings: [String]?
    let priceAnalysis: String?
    let correlationAnalysis: String?
    let actionSuggestions: [String]?
    let riskLevel: String?
    let confidence: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case focusItemId = "focus_item_id"
        case userId = "user_id"
        case title
        case summary
        case keyFindings = "key_findings"
        case priceAnalysis = "price_analysis"
        case correlationAnalysis = "correlation_analysis"
        case actionSuggestions = "action_suggestions"
        case riskLevel = "risk_level"
        case confidence
        case createdAt = "created_at"
    }
}

struct EventAnalysis: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let title: String
    let eventSummary: String?
    let impactAnalysis: String?
    let affectedAssets: [String]?
    let marketReaction: String?
    let futureOutlook: String?
    let keyTakeaways: [String]?
    let severity: String?
    let confidence: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case title
        case eventSummary = "event_summary"
        case impactAnalysis = "impact_analysis"
        case affectedAssets = "affected_assets"
        case marketReaction = "market_reaction"
        case futureOutlook = "future_outlook"
        case keyTakeaways = "key_takeaways"
        case severity
        case confidence
        case createdAt = "created_at"
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "服务器响应错误"
        case .decodingError:
            return "数据解析错误"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .requestFailed(let message):
            return message
        }
    }
}
