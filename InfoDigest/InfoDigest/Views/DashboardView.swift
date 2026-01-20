import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var userId: UUID = UUID()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }

                    portfolioSummaryCard
                    watchlistSummaryCard
                    strategiesSummaryCard
                    focusSummaryCard
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("仪表板")
            .refreshable {
                viewModel.refreshData()
            }
        }
        .onAppear {
            viewModel.setUserId(userId)
        }
    }

    private var portfolioSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
                Text("投资组合")
                    .font(.headline)
                Spacer()
                if let summary = viewModel.portfolioSummary {
                    Text("\(summary.itemCount) 项")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let summary = viewModel.portfolioSummary {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("总价值")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currencyString(summary.totalValue))
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("今日盈亏")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(summary.todayChange >= 0 ? "+" : "")\(currencyString(summary.todayChange))")
                            .foregroundColor(summary.todayChange >= 0 ? .green : .red)
                        Text("(\(String(format: "%.2f", summary.todayChangePercent))%)")
                            .foregroundColor(summary.todayChange >= 0 ? .green : .red)
                            .font(.caption)
                    }

                    if let top = summary.topPerformer {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(top.symbol): \(String(format: "%.2f", top.profitLossPercent ?? 0))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var watchlistSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("关注列表")
                    .font(.headline)
                Spacer()
                if let summary = viewModel.watchlistSummary {
                    Text("\(summary.itemCount) 项")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let summary = viewModel.watchlistSummary, summary.itemCount > 0 {
                HStack {
                    VStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.green)
                        Text("\(summary.upCount)")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("上涨")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.red)
                        Text("\(summary.downCount)")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("下跌")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var strategiesSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .foregroundColor(.purple)
                Text("活跃策略")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.activeStrategiesCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }

            if viewModel.activeStrategiesCount > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日触发")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.todayTriggers)")
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("临时关注")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.activeFocusItemsCount)")
                            .font(.headline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var focusSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.orange)
                Text("临时关注")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.activeFocusItemsCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.gray)
                Text("最近活动")
                    .font(.headline)
            }

            if viewModel.recentActivity.isEmpty {
                Text("暂无最近活动")
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentActivity) { activity in
                        activityRow(activity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func activityRow(_ activity: DashboardViewModel.ActivityItem) -> some View {
        HStack {
            activityIcon(activity.type)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let symbol = activity.symbol {
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                Text(timeAgo(activity.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func activityIcon(_ type: DashboardViewModel.ActivityItem.ActivityType) -> some View {
        ZStack {
            Circle()
                .fill(iconColor(type).opacity(0.2))

            Image(systemName: iconName(type))
                .foregroundColor(iconColor(type))
        }
    }

    private func iconName(_ type: DashboardViewModel.ActivityItem.ActivityType) -> String {
        switch type {
        case .strategyTrigger: return "bell.fill"
        case .priceAlert: return "dollarsign.circle.fill"
        case .newsEvent: return "newspaper.fill"
        case .focusUpdate: return "eye.fill"
        }
    }

    private func iconColor(_ type: DashboardViewModel.ActivityItem.ActivityType) -> Color {
        switch type {
        case .strategyTrigger: return .purple
        case .priceAlert: return .green
        case .newsEvent: return .blue
        case .focusUpdate: return .orange
        }
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "刚刚"
        } else if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else {
            return "\(seconds / 86400)天前"
        }
    }
}

#Preview {
    DashboardView()
}
