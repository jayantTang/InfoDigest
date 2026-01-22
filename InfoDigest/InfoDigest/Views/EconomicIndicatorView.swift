import SwiftUI

struct EconomicIndicatorView: View {
    @StateObject private var viewModel = EconomicIndicatorViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasConnectionError {
                    errorView
                } else if viewModel.hasData {
                    contentView
                } else {
                    emptyView
                }
            }
            .navigationTitle("经济形势")
            .refreshable {
                viewModel.refreshData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Update time banner
                updateTimeBanner

                // A股指数
                if !viewModel.aStockIndices.isEmpty {
                    aStockIndicesSection
                }

                // 美股ETF
                if !viewModel.usEtfIndices.isEmpty {
                    usEtfIndicesSection
                }

                // 商品价格
                if !viewModel.commodities.isEmpty {
                    commoditiesSection
                }

                // 美元指数
                if !viewModel.forex.isEmpty {
                    forexSection
                }

                // 宏观数据
                if !viewModel.macroData.isEmpty {
                    macroDataSection
                }
            }
            .padding()
        }
    }

    // MARK: - Update Time Banner

    private var updateTimeBanner: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            Text("更新于 \(viewModel.formattedLastUpdateTime)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if !viewModel.nextRefreshCountdown.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text(viewModel.nextRefreshCountdown)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - A股指数 Section

    private var aStockIndicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.red)
                Text("A股指数")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(viewModel.aStockIndices) { index in
                    IndexCard(index: index)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 美股ETF Section

    private var usEtfIndicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("美股指数")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(viewModel.usEtfIndices) { index in
                    IndexCard(index: index)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 商品价格 Section

    private var commoditiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.orange)
                Text("商品价格")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(viewModel.commodities) { index in
                    IndexCard(index: index)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 美元指数 Section

    private var forexSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                Text("美元指数")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(viewModel.forex) { index in
                    IndexCard(index: index)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 宏观数据 Section

    private var macroDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundColor(.purple)
                Text("宏观经济")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(Array(viewModel.macroData.keys.sorted()), id: \.self) { key in
                    if let macro = viewModel.macroData[key] {
                        MacroDataCard(macro: macro, indicatorId: key)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载经济指标...")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button("重新加载") {
                viewModel.refreshData()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无经济指标数据")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("请稍后再试或点击刷新按钮")
                .foregroundColor(.secondary)
                .padding()

            Button("刷新") {
                viewModel.refreshData()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Index Card Component

struct IndexCard: View {
    let index: IndexData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(index.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(index.symbol)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 显示估算标记
                    if index.isEstimated {
                        Text("估算")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(3)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(index.formattedPrice)
                    .font(.headline)
                    .fontWeight(.bold)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(index.formattedTime)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)

        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(index.isStale ? Color.orange : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Macro Data Card Component

struct MacroDataCard: View {
    let macro: MacroData
    let indicatorId: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(macro.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(macro.formattedPeriod)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(macro.frequencyDisplay)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(macro.formattedValue)
                    .font(.headline)
                    .fontWeight(.bold)

                if macro.unit != "Index" {
                    Text(macro.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Price Change Label Component

struct PriceChangeLabel: View {
    let period: String      // "1天", "1周", etc.
    let value: String?      // "+2.5" or "-0.8" or nil
    let available: Bool     // Whether data is available

    var body: some View {
        HStack(spacing: 2) {
            Text(period)
                .font(.caption2)
                .foregroundColor(.secondary)

            if available, let value = value {
                Text(value + "%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForValue(value))
            } else {
                Text("N/A")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
        .opacity(available ? 1.0 : 0.6)
    }

    private func colorForValue(_ value: String) -> Color {
        if value.hasPrefix("+") {
            return .red  // 涨
        } else if value.hasPrefix("-") {
            return .green  // 跌
        } else {
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    EconomicIndicatorView()
}
