import SwiftUI

struct MarketEventDetailView: View {
    let event: OpportunitiesViewModel.MarketEvent
    @Environment(\.dismiss) var dismiss
    @State private var analysis: EventAnalysis?
    @State private var isLoadingAnalysis = false
    @State private var analysisError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和分数
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        ImportanceBadge(score: event.importanceScore)
                        Text(categoryIcon(event.category))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // 描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("事件详情")
                        .font(.headline)
                    Text(event.description)
                        .font(.body)
                }

                // 相关股票
                if let symbols = event.symbols, !symbols.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("相关股票")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(symbols, id: \.self) { symbol in
                                Text(symbol)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // 板块
                if let sectors = event.sectors, !sectors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("相关板块")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(sectors, id: \.self) { sector in
                                Text(sector)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // 元数据
                VStack(alignment: .leading, spacing: 8) {
                    Text("详细信息")
                        .font(.headline)

                    HStack {
                        Text("发布时间:")
                            .foregroundColor(.secondary)
                        Text(event.publishedAt, style: .date)
                        Text(event.publishedAt, style: .time)
                    }
                    .font(.caption)

                    if let fetchedAt = event.fetchedAt {
                        HStack {
                            Text("抓取时间:")
                                .foregroundColor(.secondary)
                            Text(fetchedAt, style: .date)
                            Text(fetchedAt, style: .time)
                        }
                        .font(.caption)
                    }

                    HStack {
                        Text("重要性:")
                            .foregroundColor(.secondary)
                        Text("\(event.importanceScore)/100")
                    }
                    .font(.caption)

                    if let isProcessed = event.isProcessed {
                        HStack {
                            Text("处理状态:")
                                .foregroundColor(.secondary)
                            Text(isProcessed ? "已处理" : "未处理")
                                .foregroundColor(isProcessed ? .green : .orange)
                        }
                        .font(.caption)
                    }
                }

                // 原始信息源链接
                if !event.allURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原始信息源")
                            .font(.headline)

                        ForEach(event.allURLs.indices, id: \.self) { index in
                            let urlString = event.allURLs[index]
                            if let url = URL(string: urlString) {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "link")
                                            .foregroundColor(.blue)
                                        Text(urlString)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                Divider()

                // LLM分析部分
                if isLoadingAnalysis {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("正在生成AI分析...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if let analysis = analysis {
                    // 经济影响评估
                    if let impact = analysis.impactAnalysis, !impact.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .foregroundColor(.blue)
                                Text("经济影响评估")
                                    .font(.headline)
                            }

                            Text(impact)
                                .font(.body)
                        }
                    }

                    // 市场反应
                    if let reaction = analysis.marketReaction, !reaction.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.green)
                                Text("市场反应")
                                    .font(.headline)
                            }

                            Text(reaction)
                                .font(.body)
                        }
                    }

                    // 未来展望
                    if let outlook = analysis.futureOutlook, !outlook.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("未来展望")
                                    .font(.headline)
                            }

                            Text(outlook)
                                .font(.body)
                        }
                    }

                    // 关键要点
                    if let takeaways = analysis.keyTakeaways, !takeaways.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text("关键要点")
                                    .font(.headline)
                            }

                            ForEach(takeaways.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.orange)
                                        .font(.headline)

                                    Text(takeaways[index])
                                        .font(.body)
                                }
                            }
                        }
                    }

                    // 分析元数据
                    HStack {
                        if let confidence = analysis.confidence {
                            Text("置信度:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(confidence)%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(confidenceColor(confidence))
                        }

                        Spacer()

                        if let severity = analysis.severity {
                            Text("严重程度:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(severityText(severity))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(severityColor(severity))
                        }
                    }
                    .padding(.top, 8)
                } else if let error = analysisError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("分析加载失败: \(error)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("市场事件")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadAnalysis()
        }
    }

    private func loadAnalysis() {
        Task {
            do {
                let urlString = "\(APIService.shared.baseURL)/monitoring/events/\(event.id.uuidString)/analysis"

                guard let url = URL(string: urlString) else {
                    await MainActor.run {
                        analysisError = "无效的URL"
                        isLoadingAnalysis = false
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
                        analysisError = "服务器错误"
                        isLoadingAnalysis = false
                    }
                    return
                }

                let decoder = APIService.shared.decoder
                let result = try decoder.decode(EventAnalysisResponse.self, from: data)

                await MainActor.run {
                    analysis = result.data
                    isLoadingAnalysis = false
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    isLoadingAnalysis = false
                }
            }
        }
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

    private func confidenceColor(_ confidence: Int) -> Color {
        if confidence >= 80 {
            return .green
        } else if confidence >= 60 {
            return .blue
        } else {
            return .orange
        }
    }

    private func severityText(_ severity: String) -> String {
        switch severity {
        case "high": return "高"
        case "medium": return "中"
        case "low": return "低"
        default: return severity
        }
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
}

// 简单的流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > width && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: width, height: currentY + lineHeight)
            self.positions = positions
        }
    }
}
