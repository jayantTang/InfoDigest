import Foundation

/// API服务单例
class APIService {
    static let shared = APIService()

    // 根据运行环境自动选择服务器地址
    #if targetEnvironment(simulator)
    // 模拟器使用 localhost
    private let baseURL = "http://localhost:3000/api"
    #else
    // 真机使用局域网 IP（请根据实际情况修改）
    private let baseURL = "http://192.168.1.91:3000/api"
    #endif

    private let session = URLSession.shared

    private init() {}

    /// 注册设备token
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

        // 使用自定义日期解码器
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // 尝试 ISO8601 格式
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // 尝试其他格式
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }

            throw APIError.decodingError
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
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)

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
        }
    }
}

// MARK: - Response Models
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
