import SwiftUI

struct StrategiesView: View {
    @StateObject private var viewModel = StrategiesViewModel()
    @State private var userId: UUID = UUID()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "gearshape.2")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无策略")
                            .foregroundColor(.secondary)
                        Text("点击右上角 + 创建策略")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(viewModel.strategies) { strategy in
                        StrategyRow(strategy: strategy)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedStrategy = strategy
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteStrategy(strategy)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                if strategy.status == .active {
                                    Button {
                                        Task {
                                            await viewModel.updateStrategyStatus(strategy, status: .paused)
                                        }
                                    } label: {
                                        Label("暂停", systemImage: "pause.circle")
                                    }
                                    .tint(.orange)
                                } else {
                                    Button {
                                        Task {
                                            await viewModel.updateStrategyStatus(strategy, status: .active)
                                        }
                                    } label: {
                                        Label("激活", systemImage: "play.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .navigationTitle("策略管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateStrategySheet(viewModel: viewModel)
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
                await viewModel.loadStrategies()
            }
        }
    }
}

struct StrategyRow: View {
    let strategy: Strategy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(strategy.symbol)
                    .font(.headline)

                Text("·")
                    .foregroundColor(.secondary)

                Text(strategy.name)
                    .font(.subheadline)

                Spacer()

                statusBadge(strategy.status)
            }

            HStack {
                conditionTypeLabel(strategy.conditionType)

                Spacer()

                Text("优先级: \(strategy.priority)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if strategy.triggerCount > 0 {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text("已触发 \(strategy.triggerCount) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: Strategy.StrategyStatus) -> some View {
        Text(statusText(status))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.2))
            .foregroundColor(statusColor(status))
            .cornerRadius(8)
    }

    private func statusText(_ status: Strategy.StrategyStatus) -> String {
        switch status {
        case .active: return "活跃"
        case .paused: return "暂停"
        case .disabled: return "禁用"
        }
    }

    private func statusColor(_ status: Strategy.StrategyStatus) -> Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .disabled: return .gray
        }
    }

    private func conditionTypeLabel(_ type: Strategy.StrategyConditionType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: conditionIcon(type))
                .font(.caption)
            Text(conditionText(type))
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }

    private func conditionIcon(_ type: Strategy.StrategyConditionType) -> String {
        switch type {
        case .price: return "dollarsign.circle"
        case .technical: return "chart.line.uptrend.xyaxis"
        case .news: return "newspaper"
        case .time: return "clock"
        }
    }

    private func conditionText(_ type: Strategy.StrategyConditionType) -> String {
        switch type {
        case .price: return "价格条件"
        case .technical: return "技术指标"
        case .news: return "新闻事件"
        case .time: return "时间条件"
        }
    }
}

struct CreateStrategySheet: View {
    @ObservedObject var viewModel: StrategiesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var symbol = ""
    @State private var name = ""
    @State private var conditionType = "price"
    @State private var priceAbove = ""
    @State private var priceBelow = ""
    @State private var priority = 50

    let conditionTypes = ["price", "technical", "news", "time"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("股票代码", text: $symbol)
                        .textInputAutocapitalization(.characters)

                    TextField("策略名称", text: $name)

                    Picker("条件类型", selection: $conditionType) {
                        ForEach(conditionTypes, id: \.self) { type in
                            Text(conditionTypeDisplay(type)).tag(type)
                        }
                    }
                }

                if conditionType == "price" {
                    Section(header: Text("价格条件")) {
                        HStack {
                            Text("价格高于")
                            Spacer()
                            TextField("可选", text: $priceAbove)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("价格低于")
                            Spacer()
                            TextField("可选", text: $priceBelow)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section(header: Text("优先级")) {
                    VStack {
                        HStack {
                            Text("优先级")
                            Spacer()
                            Text("\(priority)")
                                .foregroundColor(.blue)
                        }
                        Slider(value: Binding(
                            get: { Double(priority) },
                            set: { priority = Int($0) }
                        ), in: 0...100, step: 10)
                        Text("数值越大，优先级越高")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("创建策略")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        var conditions: [String: Any] = [:]

                        if !priceAbove.isEmpty {
                            conditions["priceAbove"] = Double(priceAbove)
                        }
                        if !priceBelow.isEmpty {
                            conditions["priceBelow"] = Double(priceBelow)
                        }

                        Task {
                            await viewModel.createStrategy(
                                symbol: symbol,
                                name: name,
                                conditionType: conditionType,
                                conditions: conditions,
                                priority: priority
                            )
                            dismiss()
                        }
                    }
                    .disabled(symbol.isEmpty || name.isEmpty)
                }
            }
        }
    }

    private func conditionTypeDisplay(_ type: String) -> String {
        switch type {
        case "price": return "价格"
        case "technical": return "技术指标"
        case "news": return "新闻事件"
        case "time": return "时间"
        default: return type
        }
    }
}

#Preview {
    StrategiesView()
}
