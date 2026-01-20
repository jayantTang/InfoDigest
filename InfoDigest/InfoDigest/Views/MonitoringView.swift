import SwiftUI

struct MonitoringView: View {
    @StateObject private var viewModel = MonitoringViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.hasError && viewModel.monitoringStatus == nil {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("无法连接到服务器")
                                .foregroundColor(.secondary)
                            Text("请确保服务器正在运行")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    monitoringStatusCard
                    if let metrics = viewModel.monitoringMetrics {
                        strategiesMetricsCard(metrics)
                        focusMetricsCard(metrics)
                        eventsMetricsCard(metrics)
                    }
                }
                .padding()
            }
            .navigationTitle("监控状态")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refreshAll() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            // 后台静默加载
            Task {
                await viewModel.loadMonitoringStatus()
                await viewModel.loadMonitoringMetrics()
            }
        }
        .refreshable {
            viewModel.refreshAll()
        }
    }

    private var monitoringStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pulse.fill")
                    .foregroundColor(viewModel.monitoringStatus?.isRunning == true ? .green : .red)
                Text("监控引擎")
                    .font(.headline)
                Spacer()
                if viewModel.isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let status = viewModel.monitoringStatus {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("状态")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(status.isRunning ? "运行中" : "已停止")
                            .foregroundColor(status.isRunning ? .green : .red)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("检查间隔")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(status.checkInterval / 1000) 秒")
                    }

                    HStack {
                        Text("队列大小")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(status.queueSize)")
                    }

                    if let lastCheck = status.lastCheck {
                        HStack {
                            Text("上次检查")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(timeAgo(lastCheck))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func strategiesMetricsCard(_ metrics: MonitoringMetrics) -> some View {
        metricsCard(
            icon: "gearshape.2.fill",
            title: "策略统计",
            color: .purple,
            content: {
                VStack(spacing: 12) {
                    MetricRow(label: "总策略数", value: "\(metrics.strategies.totalStrategies)")
                    MetricRow(label: "活跃策略", value: "\(metrics.strategies.activeStrategies)")
                    MetricRow(label: "总触发次数", value: "\(metrics.strategies.totalTriggers)")
                    if metrics.strategies.totalStrategies > 0 {
                        MetricRow(
                            label: "平均触发",
                            value: String(format: "%.1f", Double(metrics.strategies.totalTriggers) / Double(metrics.strategies.totalStrategies))
                        )
                    }
                }
            }
        )
    }

    private func focusMetricsCard(_ metrics: MonitoringMetrics) -> some View {
        metricsCard(
            icon: "eye.fill",
            title: "临时关注",
            color: .orange,
            content: {
                VStack(spacing: 12) {
                    MetricRow(label: "总关注项", value: "\(metrics.focusItems.totalFocusItems)")
                    MetricRow(label: "活跃中", value: "\(metrics.focusItems.activeFocusItems)")
                    MetricRow(label: "已完成", value: "\(metrics.focusItems.totalFocusItems - metrics.focusItems.activeFocusItems)")
                }
            }
        )
    }

    private func eventsMetricsCard(_ metrics: MonitoringMetrics) -> some View {
        metricsCard(
            icon: "newspaper.fill",
            title: "事件统计",
            color: .blue,
            content: {
                VStack(spacing: 12) {
                    MetricRow(label: "总事件数", value: "\(metrics.events.totalEvents)")
                    MetricRow(label: "关键事件", value: "\(metrics.events.criticalEvents)")
                    MetricRow(label: "已处理", value: "\(metrics.events.processedEvents)")
                }
            }
        )
    }

    private func metricsCard<Content: View>(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    MonitoringView()
}
