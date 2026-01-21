import Foundation
import SwiftUI

// MARK: - Economic Indicators Response

/// 经济指标响应数据模型
struct EconomicIndicatorsResponse: Codable {
    let success: Bool
    let data: EconomicIndicators
    let cached: Bool?
}

// MARK: - Main Data Model

/// 所有经济指标数据
struct EconomicIndicators: Codable {
    let aStockIndices: [IndexData]
    let usEtfIndices: [IndexData]
    let commodities: [IndexData]
    let forex: [IndexData]
    let macroData: [String: MacroData]

    /// 计算属性：所有指数数据的合并数组
    var allIndices: [IndexData] {
        aStockIndices + usEtfIndices + commodities + forex
    }
}

// MARK: - Index Data

/// 指数数据模型（用于股市指数、商品、外汇）
struct IndexData: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let name: String
    let price: Double
    let timestamp: Date
    let isStale: Bool

    /// 自定义初始化器（用于创建示例数据）
    init(symbol: String, name: String, price: Double, timestamp: Date, isStale: Bool) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.price = price
        self.timestamp = timestamp
        self.isStale = isStale
    }

    /// 自定义解码器，处理服务器返回的字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 如果服务器提供了ID就使用，否则生成新的UUID
        if let id = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = id
        } else {
            self.id = UUID()
        }

        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)

        // 处理时间戳（可能是ISO8601字符串或Date对象）
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            let dateFormatter = ISO8601DateFormatter()
            self.timestamp = dateFormatter.date(from: timestampString) ?? Date()
        } else {
            self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        }

        self.isStale = try container.decodeIfPresent(Bool.self, forKey: .isStale) ?? false
    }

    /// 计算属性：格式化的价格字符串
    var formattedPrice: String {
        if symbol.contains("SS") || symbol.contains("SZ") {
            // A股指数：显示整数
            return String(format: "%.2f", price)
        } else if symbol.contains("GC=F") || symbol.contains("CL=F") {
            // 商品：显示2位小数
            return String(format: "%.2f", price)
        } else {
            // 美股ETF：显示2位小数
            return String(format: "%.2f", price)
        }
    }

    /// 计算属性：相对时间字符串
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// 计算属性：市场类型
    var marketType: String {
        if symbol.contains("SS") || symbol.contains("SZ") {
            return "A股"
        } else if symbol.contains("^") || ["SPY", "QQQ", "DIA"].contains(symbol) {
            return "美股"
        } else if symbol.contains("GC=F") || symbol.contains("CL=F") {
            return "商品"
        } else if symbol.contains("DX-Y.NYB") {
            return "外汇"
        }
        return "其他"
    }

    /// 计算属性：是否为A股指数
    var isAStock: Bool {
        symbol.contains("SS") || symbol.contains("SZ")
    }

    /// 计算属性：是否为美股指数
    var isUSEtf: Bool {
        ["SPY", "QQQ", "DIA"].contains(symbol)
    }

    /// 计算属性：是否为商品
    var isCommodity: Bool {
        symbol.contains("GC=F") || symbol.contains("CL=F")
    }

    /// 计算属性：是否为外汇
    var isForex: Bool {
        symbol.contains("DX-Y.NYB")
    }
}

// MARK: - Macro Data

/// 宏观经济数据模型
struct MacroData: Codable {
    let name: String
    let value: Double
    let unit: String
    let period: String
    let frequency: String
    let timestamp: Date

    /// 计算属性：格式化的值字符串
    var formattedValue: String {
        if unit == "%" || unit == "Percent" {
            return String(format: "%.2f%%", value)
        } else if unit == "Billion" || unit == "十亿美元" {
            return String(format: "%.2f", value)
        } else if unit == "Trillion" || unit == "万亿美元" {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }

    /// 计算属性：格式化的时期字符串
    var formattedPeriod: String {
        // 将 "2024-01-01" 转换为 "2024年1月"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: period) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年M月"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        return period
    }

    /// 计算属性：频率的中文显示
    var frequencyDisplay: String {
        switch frequency.lowercased() {
        case "monthly", "m":
            return "月度"
        case "quarterly", "q":
            return "季度"
        case "annual", "a", "yearly", "y":
            return "年度"
        case "weekly", "w":
            return "周度"
        case "daily", "d":
            return "日度"
        default:
            return frequency
        }
    }
}

// MARK: - Sample Data for Preview

extension EconomicIndicators {
    /// 预览用示例数据
    static let sampleData = EconomicIndicators(
        aStockIndices: [
            IndexData(symbol: "000001.SS", name: "上证指数", price: 3200.50, timestamp: Date().addingTimeInterval(-300), isStale: false),
            IndexData(symbol: "000300.SS", name: "沪深300", price: 3800.20, timestamp: Date().addingTimeInterval(-300), isStale: false),
            IndexData(symbol: "399006.SZ", name: "创业板指", price: 1950.80, timestamp: Date().addingTimeInterval(-300), isStale: false),
        ],
        usEtfIndices: [
            IndexData(symbol: "SPY", name: "标普500", price: 478.50, timestamp: Date().addingTimeInterval(-600), isStale: false),
            IndexData(symbol: "QQQ", name: "纳斯达克100", price: 412.30, timestamp: Date().addingTimeInterval(-600), isStale: false),
            IndexData(symbol: "DIA", name: "道琼斯", price: 378.20, timestamp: Date().addingTimeInterval(-600), isStale: false),
        ],
        commodities: [
            IndexData(symbol: "GC=F", name: "黄金", price: 2050.80, timestamp: Date().addingTimeInterval(-900), isStale: false),
            IndexData(symbol: "CL=F", name: "石油", price: 72.50, timestamp: Date().addingTimeInterval(-900), isStale: false),
        ],
        forex: [
            IndexData(symbol: "DX-Y.NYB", name: "美元指数", price: 103.20, timestamp: Date().addingTimeInterval(-900), isStale: false),
        ],
        macroData: [
            "CPIAUCSL": MacroData(
                name: "消费者物价指数",
                value: 310.5,
                unit: "Index",
                period: "2024-12-01",
                frequency: "Monthly",
                timestamp: Date().addingTimeInterval(-86400)
            ),
            "GDP": MacroData(
                name: "国内生产总值",
                value: 27.5,
                unit: "Trillion",
                period: "2024-09-30",
                frequency: "Quarterly",
                timestamp: Date().addingTimeInterval(-86400)
            ),
            "UNRATE": MacroData(
                name: "失业率",
                value: 3.7,
                unit: "Percent",
                period: "2024-12-01",
                frequency: "Monthly",
                timestamp: Date().addingTimeInterval(-86400)
            ),
        ]
    )
}
