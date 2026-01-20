import SwiftUI

struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var userId: UUID = UUID()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            List {
                // 总览卡片
                Section {
                    portfolioSummaryCard
                }

                // 持仓列表
                Section(header: Text("持仓")) {
                    if viewModel.isEmpty {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "briefcase")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("暂无持仓")
                                .foregroundColor(.secondary)
                            Text("点击右上角 + 添加持仓")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(viewModel.portfolioItems) { item in
                            PortfolioItemRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedItem = item
                                }
                        }
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .navigationTitle("投资组合")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPortfolioItemSheet(viewModel: viewModel)
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            viewModel.setUserId(userId)
            Task {
                await viewModel.loadPortfolio()
            }
        }
    }

    private var portfolioSummaryCard: some View {
        VStack(spacing: 16) {
            // 总价值
            VStack(alignment: .leading, spacing: 4) {
                Text("总价值")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(currencyString(viewModel.totalValue))
                    .font(.title)
                    .fontWeight(.bold)
            }

            Divider()

            // 盈亏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总盈亏")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text(currencyString(viewModel.totalProfitLoss))
                        Text("(\(String(format: "%.2f", viewModel.totalProfitLossPercent))%)")
                            .font(.caption)
                    }
                    .foregroundColor(viewModel.totalProfitLoss >= 0 ? .green : .red)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("持仓数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.portfolioItems.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct PortfolioItemRow: View {
    let item: PortfolioItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.symbol)
                    .font(.headline)

                Text("\(item.shares, specifier: "%.2f") 股")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("成本: \(currencyString(item.averageCost))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let currentPrice = item.currentPrice {
                    Text(currencyString(currentPrice))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                if let currentValue = item.currentValue {
                    Text(currencyString(currentValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let plPercent = item.profitLossPercent {
                    HStack(spacing: 2) {
                        Image(systemName: plPercent >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text("\(String(format: "%.2f", plPercent))%")
                            .font(.caption)
                    }
                    .foregroundColor(plPercent >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct AddPortfolioItemSheet: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Environment(\.dismiss) var dismiss

    @State private var symbol = ""
    @State private var shares = ""
    @State private var averageCost = ""
    @State private var assetType = "stock"

    let assetTypes = ["stock", "etf", "crypto", "bond", "other"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("股票信息")) {
                    TextField("股票代码", text: $symbol)
                        .textInputAutocapitalization(.characters)

                    Picker("资产类型", selection: $assetType) {
                        ForEach(assetTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                }

                Section(header: Text("持仓信息")) {
                    HStack {
                        Text("股数")
                        Spacer()
                        TextField("0.00", text: $shares)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("平均成本")
                        Spacer()
                        TextField("0.00", text: $averageCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("添加持仓")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        Task {
                            await viewModel.addPortfolioItem(
                                symbol: symbol,
                                shares: Double(shares) ?? 0,
                                averageCost: Double(averageCost) ?? 0,
                                assetType: assetType
                            )
                            dismiss()
                        }
                    }
                    .disabled(symbol.isEmpty || shares.isEmpty || averageCost.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PortfolioView()
}
