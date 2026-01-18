import SwiftUI

/// InfoDigest v2.0 主界面
struct ContentView: View {
    @State private var selectedTab: TabSelection = .dashboard
    @State private var userId: UUID = UUID() // TODO: 从UserDefaults或Keychain加载

    var body: some View {
        TabView(selection: $selectedTab) {
            // 仪表板（v1.0的消息列表）
            DashboardView()
                .tabItem {
                    Label("仪表板", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(TabSelection.dashboard)

            // 投资组合
            PortfolioView(userId: userId)
                .tabItem {
                    Label("投资组合", systemImage: "briefcase")
                }
                .tag(TabSelection.portfolio)

            // 关注列表
            WatchlistView(userId: userId)
                .tabItem {
                    Label("关注列表", systemImage: "star")
                }
                .tag(TabSelection.watchlist)

            // 策略管理
            StrategiesView(userId: userId)
                .tabItem {
                    Label("策略", systemImage: "gearshape.2")
                }
                .tag(TabSelection.strategies)

            // 临时关注
            TemporaryFocusView(userId: userId)
                .tabItem {
                    Label("临时关注", systemImage: "eye")
                }
                .tag(TabSelection.temporaryFocus)

            // 监控状态
            MonitoringView()
                .tabItem {
                    Label("监控", systemImage: "waveform.path")
                }
                .tag(TabSelection.monitoring)
        }
        .accentColor(.blue)
    }
}

enum TabSelection: String {
    case dashboard = "dashboard"
    case portfolio = "portfolio"
    case watchlist = "watchlist"
    case strategies = "strategies"
    case temporaryFocus = "temporaryFocus"
    case monitoring = "monitoring"
}

// MARK: - 仪表板视图（保留v1.0的消息功能）

struct DashboardView: View {
    @StateObject private var viewModel = MessageListViewModel()

    var body: some View {
        NavigationView {
            MessageListView()
                .navigationTitle("仪表板")
        }
    }
}

// MARK: - 投资组合视图

struct PortfolioView: View {
    let userId: UUID
    @State private var portfolioItems: [PortfolioItem] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && portfolioItems.isEmpty {
                    ProgressView("加载中...")
                } else if portfolioItems.isEmpty {
                    emptyStateView
                } else {
                    portfolioListView
                }
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
                AddPortfolioItemView(userId: userId) { item in
                    Task {
                        await addItem(item)
                    }
                }
            }
            .task {
                await loadPortfolio()
            }
        }
    }

    private var portfolioListView: some View {
        List {
            ForEach(portfolioItems) { item in
                NavigationLink(destination: PortfolioDetailView(item: item)) {
                    PortfolioItemRow(item: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .refreshable {
            await loadPortfolio()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无投资组合")
                .font(.headline)

            Text("添加您的持仓以开始追踪")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func loadPortfolio() async {
        isLoading = true
        defer { isLoading = false }

        do {
            portfolioItems = try await APIService.shared.getPortfolio(userId: userId)
        } catch {
            print("Failed to load portfolio: \(error)")
        }
    }

    private func addItem(_ item: PortfolioItem) async {
        do {
            let newItem = try await APIService.shared.addPortfolioItem(
                userId: userId,
                symbol: item.symbol,
                shares: item.shares,
                averageCost: item.averageCost
            )
            portfolioItems.append(newItem)
        } catch {
            print("Failed to add item: \(error)")
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        // TODO: Implement delete
    }
}

// MARK: - 投资组合行视图

struct PortfolioItemRow: View {
    let item: PortfolioItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.symbol)
                    .font(.headline)

                Text("\(item.shares, specifier: "%.0f") 股")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let currentPrice = item.currentPrice {
                    Text(currentPrice, format: .currency(code: "USD"))
                        .font(.subheadline)

                    if let change = item.profitLossPercent {
                        Text("\(change > 0 ? "+" : "")\(String(format: "%.2f", change))%")
                            .font(.caption)
                            .foregroundColor(item.profitLossColor)
                    }
                } else {
                    Text("--")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 投资组合详情视图

struct PortfolioDetailView: View {
    let item: PortfolioItem

    var body: some View {
        Form {
            Section("持仓信息") {
                HStack {
                    Text("股票代码")
                    Spacer()
                    Text(item.symbol)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("持有数量")
                    Spacer()
                    Text("\(item.shares, specifier: "%.0f") 股")
                }

                HStack {
                    Text("平均成本")
                    Spacer()
                    Text(item.averageCost, format: .currency(code: "USD"))
                }

                HStack {
                    Text("总成本")
                    Spacer()
                    Text(item.totalCost, format: .currency(code: "USD"))
                }
            }

            Section("当前价值") {
                if let currentValue = item.currentValue {
                    HStack {
                        Text("当前市值")
                        Spacer()
                        Text(currentValue, format: .currency(code: "USD"))
                    }

                    if let pl = item.profitLoss {
                        HStack {
                            Text("盈亏")
                            Spacer()
                            Text(pl, format: .currency(code: "USD"))
                                .foregroundColor(pl >= 0 ? .green : .red)
                        }
                    }
                }
            }

            Section("操作") {
                Button(action: {
                    // TODO: 编辑持仓
                }) {
                    Text("编辑持仓")
                }

                Button(role: .destructive, action: {
                    // TODO: 删除持仓
                }) {
                    Text("删除持仓")
                }
            }
        }
        .navigationTitle(item.symbol)
    }
}

// MARK: - 添加持仓表单

struct AddPortfolioItemView: View {
    let userId: UUID
    let onAdd: (PortfolioItem) -> Void

    @State private var symbol = ""
    @State private var shares = ""
    @State private var averageCost = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("股票信息") {
                    TextField("股票代码 (如: NVDA)", text: $symbol)

                    TextField("持有数量", text: $shares)

                    TextField("平均成本", text: $averageCost)
                }

                Section {
                    Button("添加") {
                        if let sharesValue = Double(shares),
                           let costValue = Double(averageCost),
                           !symbol.isEmpty {
                            let item = PortfolioItem(
                                id: UUID(),
                                userId: userId,
                                symbol: symbol.uppercased(),
                                shares: sharesValue,
                                averageCost: costValue,
                                assetType: .stock,
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                            onAdd(item)
                            dismiss()
                        }
                    }
                    .disabled(symbol.isEmpty || shares.isEmpty || averageCost.isEmpty)
                }
            }
            .navigationTitle("添加持仓")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 关注列表视图

struct WatchlistView: View {
    let userId: UUID
    @State private var watchlistItems: [WatchlistItem] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && watchlistItems.isEmpty {
                    ProgressView("加载中...")
                } else if watchlistItems.isEmpty {
                    emptyStateView
                } else {
                    watchlistListView
                }
            }
            .navigationTitle("关注列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWatchlistItemView(userId: userId) { symbol in
                    Task {
                        await addItem(symbol)
                    }
                }
            }
            .task {
                await loadWatchlist()
            }
        }
    }

    private var watchlistListView: some View {
        List {
            ForEach(watchlistItems) { item in
                WatchlistItemRow(item: item)
            }
            .onDelete(perform: deleteItems)
        }
        .refreshable {
            await loadWatchlist()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无关注股票")
                .font(.headline)

            Text("添加您感兴趣的股票")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func loadWatchlist() async {
        isLoading = true
        defer { isLoading = false }

        do {
            watchlistItems = try await APIService.shared.getWatchlist(userId: userId)
        } catch {
            print("Failed to load watchlist: \(error)")
        }
    }

    private func addItem(_ symbol: String) async {
        do {
            let newItem = try await APIService.shared.addWatchlistItem(
                userId: userId,
                symbol: symbol
            )
            watchlistItems.append(newItem)
        } catch {
            print("Failed to add item: \(error)")
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        // TODO: Implement delete
    }
}

// MARK: - 关注列表行视图

struct WatchlistItemRow: View {
    let item: WatchlistItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.symbol)
                    .font(.headline)

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let price = item.currentPrice {
                    Text(price, format: .currency(code: "USD"))
                        .font(.subheadline)
                }

                if let change = item.changePercent {
                    Text("\(change > 0 ? "+" : "")\(String(format: "%.2f", change))%")
                        .font(.caption)
                        .foregroundColor(item.changeColor)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 添加关注表单

struct AddWatchlistItemView: View {
    let userId: UUID
    let onAdd: (String) -> Void

    @State private var symbol = ""
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("股票信息") {
                    TextField("股票代码 (如: TSLA)", text: $symbol)

                    TextField("备注（可选）", text: $notes)
                }

                Section {
                    Button("添加") {
                        if !symbol.isEmpty {
                            onAdd(symbol)
                            dismiss()
                        }
                    }
                    .disabled(symbol.isEmpty)
                }
            }
            .navigationTitle("添加关注")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 占位符视图（其他Tab）

struct StrategiesView: View {
    let userId: UUID

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("策略管理")
                    .font(.headline)

                Text("即将推出")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("策略")
        }
    }
}

struct TemporaryFocusView: View {
    let userId: UUID

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "eye")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("临时关注")
                    .font(.headline)

                Text("即将推出")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("临时关注")
        }
    }
}

struct MonitoringView: View {
    @State private var monitoringStatus: MonitoringStatus?
    @State private var metrics: MonitoringMetrics?

    var body: some View {
        NavigationView {
            List {
                Section("监控状态") {
                    if let status = monitoringStatus {
                        HStack {
                            Text("运行状态")
                            Spacer()
                            Text(status.isRunning ? "运行中" : "已停止")
                                .foregroundColor(status.isRunning ? .green : .red)
                        }

                        HStack {
                            Text("检查间隔")
                            Spacer()
                            Text("\(status.checkInterval / 60) 分钟")
                        }

                        HStack {
                            Text("队列通知")
                            Spacer()
                            Text("\(status.queueSize) 条")
                        }
                    }
                }

                Section("统计指标") {
                    if let metrics = metrics {
                        HStack {
                            Text("总策略数")
                            Spacer()
                            Text("\(metrics.strategies.totalStrategies)")
                        }

                        HStack {
                            Text("激活策略")
                            Spacer()
                            Text("\(metrics.strategies.activeStrategies)")
                        }

                        HStack {
                            Text("总触发次数")
                            Spacer()
                            Text("\(metrics.strategies.totalTriggers)")
                        }
                    }
                }

                Section("操作") {
                    Button(action: {
                        // TODO: 启动/停止监控
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("手动检查")
                        }
                    }
                }
            }
            .navigationTitle("监控")
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        do {
            monitoringStatus = try await APIService.shared.getMonitoringStatus()
            metrics = try await APIService.shared.getMonitoringMetrics()
        } catch {
            print("Failed to load monitoring data: \(error)")
        }
    }
}

// MARK: - 预览

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
