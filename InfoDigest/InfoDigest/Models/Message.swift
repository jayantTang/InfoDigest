import Foundation
import SwiftUI

/// 消息类型枚举
enum MessageType: String, Codable, CaseIterable {
    case news = "新闻"
    case stock = "股票"
    case digest = "简报"
    case unknown = "其他"

    var icon: String {
        switch self {
        case .news: return "newspaper"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .digest: return "doc.text"
        case .unknown: return "doc"
        }
    }
}

/// 消息数据模型
struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let type: MessageType
    let title: String
    let contentRich: String      // Markdown格式的富文本
    let summary: String           // 推送预览文本
    let images: [String]?         // 图片URL数组
    let links: [Link]?            // 链接数组
    let createdAt: Date
    var isRead: Bool = false

    // 自定义 JSON 解码，处理服务器字段名和本地字段名的差异
    enum CodingKeys: String, CodingKey {
        case id
        case type = "messageType"  // 服务器返回 messageType，本地用 type
        case title
        case contentRich
        case summary
        case images
        case links
        case createdAt
        case isRead
    }

    /// 链接模型
    struct Link: Identifiable, Codable, Equatable {
        let id: UUID
        let title: String
        let url: String
    }

    /// 计算属性：格式化的时间字符串
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// 计算属性：类型对应的颜色
    var typeColor: Color {
        switch type {
        case .news: return .blue
        case .stock: return .green
        case .digest: return .purple
        case .unknown: return .gray
        }
    }
}

/// 示例数据（用于开发和预览）
extension Message {
    static let sampleMessages: [Message] = [
        Message(
            id: UUID(),
            type: .news,
            title: "OpenAI发布最新GPT-5预览版",
            contentRich: """
            ## OpenAI发布最新GPT-5预览版

            OpenAI今日正式发布了**GPT-5预览版**，在多项基准测试中表现优异：

            ### 主要改进
            - **推理能力**: 比GPT-4提升40%
            - **上下文窗口**: 支持最大200K tokens
            - **多模态**: 图片理解能力显著增强

            ### 市场反应
            发布后，科技股普遍上涨，[NVIDIA](https://finance.yahoo.com/quote/NVDA) 涨幅3.2%，[Microsoft](https://finance.yahoo.com/quote/MSFT) 涨幅2.1%。

            > "这是AI发展的里程碑时刻。" - OpenAI CEO Sam Altman
            """,
            summary: "OpenAI发布GPT-5预览版，多项能力显著提升，科技股普遍上涨...",
            images: ["https://picsum.photos/400/200"],
            links: [
                Link(id: UUID(), title: "OpenAI官方公告", url: "https://openai.com")
            ],
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Message(
            id: UUID(),
            type: .stock,
            title: "今日市场行情简报",
            contentRich: """
            ## 美股市场表现 📈

            ### 主要指数
            - **标普500**: 4,782.50 (+1.23%)
            - **纳斯达克**: 15,012.30 (+1.89%)
            - **道琼斯**: 37,652.40 (+0.85%)

            ### 热门个股
            | 股票代码 | 涨跌幅 | 成因分析 |
            |---------|--------|----------|
            | NVDA | +3.2% | AI芯片需求持续旺盛 |
            | TSLA | -1.5% | 四季度交付量不及预期 |
            | AAPL | +0.8% | 新年促销活动启动 |

            ### 明日关注
            - 美联储会议纪要发布
            - 十二月零售销售数据
            """,
            summary: "美股三大指数全线上涨，科技股领涨，NVDA涨幅超3%...",
            images: nil,
            links: nil,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Message(
            id: UUID(),
            type: .digest,
            title: "AI简报 - 第2024001期",
            contentRich: """
            # 今日AI要闻速览

            ## 1. 技术突破 ⚡️
            Google DeepMind发布新的蛋白质折叠预测模型，准确率提升至98%。

            ## 2. 行业动态 🏢
            - 微软宣布将AI Copilot集成至所有Office产品
            - 亚马逊AWS推出新的AI训练芯片Trainium3

            ## 3. 投资融资 💰
            - AI初创公司Anthropic完成20亿美元融资
            - 英特尔收购AI芯片设计公司Habana Labs

            ---
            *本简报由AI自动生成，内容来源于公开信息*
            """,
            summary: "今日AI要闻：Google蛋白预测突破，微软AI集成...",
            images: ["https://picsum.photos/400/200", "https://picsum.photos/400/201"],
            links: [
                Link(id: UUID(), title: "DeepMind公告", url: "https://deepmind.com"),
                Link(id: UUID(), title: "微软新闻", url: "https://microsoft.com")
            ],
            createdAt: Date().addingTimeInterval(-10800)
        )
    ]
}
