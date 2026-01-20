import SwiftUI

struct OpportunitiesView: View {
    @StateObject private var viewModel = OpportunitiesViewModel()
    // 使用测试用户ID以便演示功能
    @State private var userId: UUID = UUID(uuidString: "3066d0a5-acc4-46ea-aed7-1c27723d2632")!
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                // Tab选择器
                Picker("", selection: $selectedTab) {
                    Text("市场事件").tag(0)
                    Text("策略分析").tag(1)
                    Text("关注报告").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // 内容区域
                if viewModel.hasConnectionError {
                    errorStateView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("投资机会")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refreshData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.setUserId(userId)
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("暂无投资机会")
                .font(.title3)
                .fontWeight(.semibold)

            Text("开始添加投资组合和策略，AI 将自动发现投资机会")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("添加投资组合")
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("创建监控策略")
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("等待市场机会")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var errorStateView: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("连接失败")
                .font(.title3)
                .fontWeight(.semibold)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                viewModel.refreshData()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重试")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if selectedTab == 0 {
                    marketEventsSection
                } else if selectedTab == 1 {
                    strategyAnalysesSection
                } else {
                    focusAnalysesSection
                }
            }
            .padding()
        }
    }

    // MARK: - 市场事件部分

    private var marketEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重要市场事件")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.marketEvents.isEmpty {
                Text("暂无事件")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.marketEvents) { event in
                    MarketEventCard(event: event)
                }
            }
        }
    }

    // MARK: - 策略分析部分

    private var strategyAnalysesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("策略触发分析")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.strategyAnalyses.isEmpty {
                Text("暂无分析")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.strategyAnalyses) { analysis in
                    StrategyAnalysisCard(analysis: analysis)
                }
            }
        }
    }

    // MARK: - 关注分析部分

    private var focusAnalysesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("临时关注报告")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.focusAnalyses.isEmpty {
                Text("暂无报告")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.focusAnalyses) { analysis in
                    FocusAnalysisCard(analysis: analysis)
                }
            }
        }
    }
}

// MARK: - 市场事件卡片

struct MarketEventCard: View {
    let event: OpportunitiesViewModel.MarketEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和重要性
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(categoryIcon(event.category))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ImportanceBadge(score: event.importanceScore)
            }

            // 描述
            Text(event.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // 相关股票
            if let symbols = event.symbols, !symbols.isEmpty {
                HStack {
                    Text("相关:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(symbols.prefix(5), id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }

            // 时间
            Text(timeAgo(event.publishedAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "earnings": return "💰 财报"
        case "merger": return "🤝 并购"
        case "product": return "📦 产品"
        case "regulation": return "⚖️ 监管"
        case "macro": return "🌍 宏观"
        default: return "📰 新闻"
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else {
            return "\(seconds / 86400)天前"
        }
    }
}

// MARK: - 策略分析卡片

struct StrategyAnalysisCard: View {
    let analysis: OpportunitiesViewModel.StrategyAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text(analysis.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                ConfidenceBadge(confidence: analysis.confidence)
            }

            // 触发原因
            VStack(alignment: .leading, spacing: 4) {
                Text("触发原因")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(analysis.triggerReason)
                    .font(.caption)
            }

            // 行动建议
            if !analysis.actionSuggestion.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("投资建议")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(analysis.actionSuggestion)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }

            // 时间
            Text(timeAgo(analysis.createdAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else {
            return "\(seconds / 86400)天前"
        }
    }
}

// MARK: - 关注分析卡片

struct FocusAnalysisCard: View {
    let analysis: OpportunitiesViewModel.FocusAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text(analysis.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                RiskBadge(level: analysis.riskLevel)
            }

            // 总结
            Text(analysis.summary)
                .font(.caption)
                .foregroundColor(.secondary)

            // 关键发现
            if !analysis.keyFindings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("关键发现")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(analysis.keyFindings.prefix(3), id: \.self) { finding in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption2)

                            Text(finding)
                                .font(.caption)
                        }
                    }
                }
            }

            // 行动建议
            if !analysis.actionSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("行动建议")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(analysis.actionSuggestions.prefix(2), id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption2)

                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
            }

            // 时间
            Text(timeAgo(analysis.createdAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else {
            return "\(seconds / 86400)天前"
        }
    }
}

// MARK: - 标签组件

struct ImportanceBadge: View {
    let score: Int

    var body: some View {
        Text(scoreText)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private var scoreText: String {
        "\(score)分"
    }

    private var color: Color {
        if score >= 80 {
            return .red
        } else if score >= 60 {
            return .orange
        } else {
            return .green
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Int

    var body: some View {
        Text("\(confidence)%")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private var color: Color {
        if confidence >= 80 {
            return .green
        } else if confidence >= 60 {
            return .blue
        } else {
            return .orange
        }
    }
}

struct RiskBadge: View {
    let level: String

    var body: some View {
        Text(levelText)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private var levelText: String {
        switch level {
        case "high": return "高风险"
        case "medium": return "中风险"
        case "low": return "低风险"
        default: return level
        }
    }

    private var color: Color {
        switch level {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
}

#Preview {
    OpportunitiesView()
}
