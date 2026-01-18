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

// MARK: - 策略管理视图

struct StrategiesView: View {
    let userId: UUID
    @State private var strategies: [Strategy] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var filter: StrategyFilter = .all

    enum StrategyFilter: String, CaseIterable {
        case all = "全部"
        case active = "激活"
        case inactive = "停用"
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && strategies.isEmpty {
                    ProgressView("加载中...")
                } else if filteredStrategies.isEmpty {
                    emptyStateView
                } else {
                    strategiesListView
                }
            }
            .navigationTitle("策略")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("", selection: $filter) {
                        ForEach(StrategyFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CreateStrategyView(userId: userId) { strategy in
                    Task {
                        await addStrategy(strategy)
                    }
                }
            }
            .task {
                await loadStrategies()
            }
        }
    }

    private var filteredStrategies: [Strategy] {
        switch filter {
        case .all:
            return strategies
        case .active:
            return strategies.filter { $0.isActive }
        case .inactive:
            return strategies.filter { !$0.isActive }
        }
    }

    private var strategiesListView: some View {
        List {
            ForEach(filteredStrategies) { strategy in
                NavigationLink(destination: StrategyDetailView(userId: userId, strategy: strategy)) {
                    StrategyRow(strategy: strategy)
                }
            }
            .onDelete(perform: deleteStrategies)
        }
        .refreshable {
            await loadStrategies()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无策略")
                .font(.headline)

            Text("创建策略以自动监控市场")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func loadStrategies() async {
        isLoading = true
        defer { isLoading = false }

        do {
            strategies = try await APIService.shared.getStrategies(userId: userId)
        } catch {
            print("Failed to load strategies: \(error)")
        }
    }

    private func addStrategy(_ strategy: Strategy) async {
        do {
            let newStrategy = try await APIService.shared.createStrategy(
                userId: userId,
                symbol: strategy.symbol,
                name: strategy.name,
                conditionType: strategy.conditionType,
                conditions: strategy.conditions,
                action: strategy.action,
                priority: strategy.priority
            )
            strategies.append(newStrategy)
        } catch {
            print("Failed to add strategy: \(error)")
        }
    }

    private func deleteStrategies(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let strategy = filteredStrategies[index]
                do {
                    try await APIService.shared.deleteStrategy(id: strategy.id)
                    strategies.removeAll { $0.id == strategy.id }
                } catch {
                    print("Failed to delete strategy: \(error)")
                }
            }
        }
    }
}

// MARK: - 策略行视图

struct StrategyRow: View {
    let strategy: Strategy

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.name)
                    .font(.headline)

                Text(strategy.symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(conditionTypeText)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(conditionTypeColor.opacity(0.2))
                    .foregroundColor(conditionTypeColor)
                    .cornerRadius(4)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(strategy.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text("优先级 \(strategy.priority)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var conditionTypeText: String {
        switch strategy.conditionType {
        case .price: return "价格"
        case .technical: return "技术"
        case .news: return "新闻"
        case .time: return "时间"
        }
    }

    private var conditionTypeColor: Color {
        switch strategy.conditionType {
        case .price: return .blue
        case .technical: return .purple
        case .news: return .orange
        case .time: return .green
        }
    }
}

// MARK: - 策略详情视图

struct StrategyDetailView: View {
    let userId: UUID
    let strategy: Strategy
    @State private var triggerHistory: [StrategyTrigger] = []
    @State private var analysis: StrategyAnalysis?
    @State private var isLoadingAnalysis = false

    var body: some View {
        List {
            Section("策略信息") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(strategy.name)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("股票代码")
                    Spacer()
                    Text(strategy.symbol)
                }

                HStack {
                    Text("状态")
                    Spacer()
                    Text(strategy.isActive ? "激活" : "停用")
                        .foregroundColor(strategy.isActive ? .green : .gray)
                }

                HStack {
                    Text("优先级")
                    Spacer()
                    Text("\(strategy.priority)")
                }
            }

            Section("触发条件") {
                conditionDescriptionView
            }

            Section("执行动作") {
                Text(actionDescription)
                    .foregroundColor(.secondary)
            }

            Section("触发历史") {
                if triggerHistory.isEmpty {
                    Text("暂无触发记录")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(triggerHistory.prefix(10), id: \.id) { trigger in
                        TriggerHistoryRow(trigger: trigger)
                    }
                }
            }

            if let analysis = analysis {
                Section("AI分析") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(analysis.title)
                            .font(.headline)

                        if let triggerReason = analysis.triggerReason {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("触发原因")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(triggerReason)
                                    .font(.caption)
                            }
                        }

                        if let marketContext = analysis.marketContext {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("市场背景")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(marketContext)
                                    .font(.caption)
                            }
                        }

                        if let actionSuggestion = analysis.actionSuggestion {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("行动建议")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(actionSuggestion)
                                    .font(.caption)
                            }
                        }

                        HStack {
                            Text("置信度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(analysis.confidence)%")
                                .font(.caption)
                                .foregroundColor(confidenceColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("操作") {
                Button(action: {
                    Task {
                        await toggleStrategy()
                    }
                }) {
                    HStack {
                        Image(systemName: strategy.isActive ? "pause.fill" : "play.fill")
                        Text(strategy.isActive ? "停用策略" : "启用策略")
                    }
                }

                Button(action: {
                    Task {
                        await loadAnalysis()
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("生成AI分析")
                    }
                }
                .disabled(isLoadingAnalysis)

                Button(role: .destructive, action: {
                    // TODO: 删除确认
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除策略")
                    }
                }
            }
        }
        .navigationTitle(strategy.name)
        .task {
            await loadTriggerHistory()
        }
    }

    private var conditionDescriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch strategy.conditionType {
            case .price:
                if let conditions = strategy.conditions as? [String: Any],
                   let priceAbove = conditions["priceAbove"] as? Double {
                    Text("价格高于 \(priceAbove, format: .currency(code: "USD"))")
                }
                if let conditions = strategy.conditions as? [String: Any],
                   let priceBelow = conditions["priceBelow"] as? Double {
                    Text("价格低于 \(priceBelow, format: .currency(code: "USD"))")
                }
                if let conditions = strategy.conditions as? [String: Any],
                   let percentChange = conditions["percentChange"] as? Double {
                    Text("涨跌幅超过 \(percentChange, specifier: "%.1f")%")
                }

            case .technical:
                if let conditions = strategy.conditions as? [String: Any],
                   let rsi = conditions["rsi"] as? [String: Any] {
                    if let above = rsi["above"] as? Double {
                        Text("RSI高于 \(above, specifier: "%.0f")")
                    }
                    if let below = rsi["below"] as? Double {
                        Text("RSI低于 \(below, specifier: "%.0f")")
                    }
                }

            case .news:
                if let conditions = strategy.conditions as? [String: Any],
                   let minImportance = conditions["minImportance"] as? Int {
                    Text("新闻重要性 ≥ \(minImportance)")
                }

            case .time:
                if let conditions = strategy.conditions as? [String: Any],
                   let timeRange = conditions["timeRange"] as? [String: String] {
                    Text("时间: \(timeRange["start"] ?? "") - \(timeRange["end"] ?? "")")
                }
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    private var actionDescription: String {
        switch strategy.action {
        case "notify": return "发送推送通知"
        case "alert": return "显示警告"
        default: return strategy.action
        }
    }

    private var confidenceColor: Color {
        if analysis?.confidence ?? 0 >= 80 {
            return .green
        } else if analysis?.confidence ?? 0 >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private func loadTriggerHistory() async {
        do {
            triggerHistory = try await APIService.shared.getStrategyTriggerHistory(id: strategy.id)
        } catch {
            print("Failed to load trigger history: \(error)")
        }
    }

    private func loadAnalysis() async {
        isLoadingAnalysis = true
        defer { isLoadingAnalysis = false }

        do {
            analysis = try await APIService.shared.getStrategyAnalysis(strategyId: strategy.id)
        } catch {
            print("Failed to load analysis: \(error)")
        }
    }

    private func toggleStrategy() async {
        do {
            let newStatus = !strategy.isActive
            try await APIService.shared.updateStrategyStatus(id: strategy.id, isActive: newStatus)
        } catch {
            print("Failed to toggle strategy: \(error)")
        }
    }
}

// MARK: - 触发历史行

struct TriggerHistoryRow: View {
    let trigger: StrategyTrigger

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trigger.triggerReason)
                .font(.caption)

            Text(formatDate(trigger.triggeredAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 创建策略视图

struct CreateStrategyView: View {
    let userId: UUID
    let onCreate: (Strategy) -> Void

    @State private var symbol = ""
    @State private var name = ""
    @State private var conditionType: StrategyConditionType = .price
    @State private var priceAbove = ""
    @State private var priceBelow = ""
    @State private var percentChange = ""
    @State private var rsiAbove = ""
    @State private var rsiBelow = ""
    @State private var minImportance = ""
    @State private var startTime = "09:30"
    @State private var endTime = "16:00"
    @State private var priority = 70
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("股票代码", text: $symbol)
                        .autocapitalization(.allCharacters)

                    TextField("策略名称", text: $name)
                }

                Section("条件类型") {
                    Picker("类型", selection: $conditionType) {
                        Text("价格条件").tag(StrategyConditionType.price)
                        Text("技术指标").tag(StrategyConditionType.technical)
                        Text("新闻事件").tag(StrategyConditionType.news)
                        Text("时间条件").tag(StrategyConditionType.time)
                    }
                    .pickerStyle(.segmented)
                }

                Section("触发条件") {
                    switch conditionType {
                    case .price:
                        TextField("价格高于 (可选)", text: $priceAbove)
                            .keyboardType(.decimalPad)

                        TextField("价格低于 (可选)", text: $priceBelow)
                            .keyboardType(.decimalPad)

                        TextField("涨跌幅 % (可选)", text: $percentChange)
                            .keyboardType(.decimalPad)

                    case .technical:
                        TextField("RSI高于 (可选)", text: $rsiAbove)
                            .keyboardType(.decimalPad)

                        TextField("RSI低于 (可选)", text: $rsiBelow)
                            .keyboardType(.decimalPad)

                    case .news:
                        TextField("最低重要性 (0-100)", text: $minImportance)
                            .keyboardType(.numberPad)

                    case .time:
                        DatePicker("开始时间", selection: Binding(
                            get: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                return formatter.date(from: startTime) ?? Date()
                            },
                            set: { date in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                startTime = formatter.string(from: date)
                            }
                        ), displayedComponents: .hourAndMinute)

                        DatePicker("结束时间", selection: Binding(
                            get: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                return formatter.date(from: endTime) ?? Date()
                            },
                            set: { date in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                endTime = formatter.string(from: date)
                            }
                        ), displayedComponents: .hourAndMinute)
                    }
                }

                Section("优先级") {
                    VStack {
                        Text("优先级: \(priority)")
                        Slider(value: Binding(
                            get: { Double(priority) },
                            set: { priority = Int($0) }
                        ), in: 0...100, step: 10)
                        Text(priorityDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("创建策略") {
                        createStrategy()
                    }
                    .disabled(symbol.isEmpty || name.isEmpty)
                }
            }
            .navigationTitle("创建策略")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var priorityDescription: String {
        switch priority {
        case 90...100: return "关键 - 最高优先级"
        case 70...89: return "高 - 重要事件"
        case 50...69: return "中 - 普通事件"
        case 30...49: return "低 - 次要事件"
        default: return "最小 - 最低优先级"
        }
    }

    private func createStrategy() {
        var conditions: [String: Any] = [:]

        switch conditionType {
        case .price:
            if !priceAbove.isEmpty, let value = Double(priceAbove) {
                conditions["priceAbove"] = value
            }
            if !priceBelow.isEmpty, let value = Double(priceBelow) {
                conditions["priceBelow"] = value
            }
            if !percentChange.isEmpty, let value = Double(percentChange) {
                conditions["percentChange"] = value
            }

        case .technical:
            var rsi: [String: Any] = [:]
            if !rsiAbove.isEmpty, let value = Double(rsiAbove) {
                rsi["above"] = value
            }
            if !rsiBelow.isEmpty, let value = Double(rsiBelow) {
                rsi["below"] = value
            }
            if !rsi.isEmpty {
                conditions["rsi"] = rsi
            }

        case .news:
            if !minImportance.isEmpty, let value = Int(minImportance) {
                conditions["minImportance"] = value
            }

        case .time:
            conditions["timeRange"] = [
                "start": startTime,
                "end": endTime
            ]
        }

        let strategy = Strategy(
            id: UUID(),
            userId: userId,
            symbol: symbol.uppercased(),
            name: name,
            conditionType: conditionType,
            conditions: conditions,
            action: "notify",
            priority: priority,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        onCreate(strategy)
        dismiss()
    }
}

struct TemporaryFocusView: View {
    let userId: UUID
    @State private var focusItems: [TemporaryFocus] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var filter: FocusFilter = .all

    enum FocusFilter: String, CaseIterable {
        case all = "全部"
        case active = "监控中"
        case completed = "已完成"
        case expired = "已过期"
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && focusItems.isEmpty {
                    ProgressView("加载中...")
                } else if filteredFocusItems.isEmpty {
                    emptyStateView
                } else {
                    focusListView
                }
            }
            .navigationTitle("临时关注")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("", selection: $filter) {
                        ForEach(FocusFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CreateTemporaryFocusView(userId: userId) { item in
                    Task {
                        await addItem(item)
                    }
                }
            }
            .task {
                await loadFocusItems()
            }
        }
    }

    private var filteredFocusItems: [TemporaryFocus] {
        switch filter {
        case .all:
            return focusItems
        case .active:
            return focusItems.filter { $0.status == .active }
        case .completed:
            return focusItems.filter { $0.status == .completed }
        case .expired:
            return focusItems.filter { $0.status == .expired }
        }
    }

    private var focusListView: some View {
        List {
            ForEach(filteredFocusItems) { item in
                NavigationLink(destination: TemporaryFocusDetailView(userId: userId, focusItem: item)) {
                    TemporaryFocusRow(item: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .refreshable {
            await loadFocusItems()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无临时关注")
                .font(.headline)

            Text("创建临时关注以短期监控股票")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func loadFocusItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            focusItems = try await APIService.shared.getTemporaryFocus(userId: userId)
        } catch {
            print("Failed to load focus items: \(error)")
        }
    }

    private func addItem(_ item: TemporaryFocus) async {
        do {
            let newItem = try await APIService.shared.createTemporaryFocus(
                userId: userId,
                title: item.title,
                description: item.description,
                targets: item.targets,
                focus: item.focus
            )
            focusItems.append(newItem)
        } catch {
            print("Failed to add item: \(error)")
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let item = filteredFocusItems[index]
                do {
                    try await APIService.shared.deleteTemporaryFocus(id: item.id)
                    focusItems.removeAll { $0.id == item.id }
                } catch {
                    print("Failed to delete item: \(error)")
                }
            }
        }
    }
}

// MARK: - 临时关注行视图

struct TemporaryFocusRow: View {
    let item: TemporaryFocus

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.targets.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)

                statusBadge
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(expiryText)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\(item.targets.count) 个目标")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    private var statusText: String {
        switch item.status {
        case .active: return "监控中"
        case .completed: return "已完成"
        case .expired: return "已过期"
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .active: return .green
        case .completed: return .blue
        case .expired: return .gray
        }
    }

    private var expiryText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: item.expiresAt)
    }
}

// MARK: - 临时关注详情视图

struct TemporaryFocusDetailView: View {
    let userId: UUID
    let focusItem: TemporaryFocus
    @State private var findings: [FocusFinding] = []
    @State private var analysis: FocusAnalysis?
    @State private var isLoadingAnalysis = false

    var body: some View {
        List {
            Section("基本信息") {
                HStack {
                    Text("标题")
                    Spacer()
                    Text(focusItem.title)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("描述")
                    Spacer()
                    Text(focusItem.description)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("状态")
                    Spacer()
                    Text(statusText)
                        .foregroundColor(statusColor)
                }

                HStack {
                    Text("过期时间")
                    Spacer()
                    Text(expiryDateText)
                        .foregroundColor(.secondary)
                }
            }

            Section("监控目标") {
                ForEach(focusItem.targets, id: \.self) { target in
                    Text(target)
                }
            }

            Section("监控类型") {
                if let focus = focusItem.focus {
                    if focus.priceReaction {
                        Label("价格反应", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    if focus.newsImpact {
                        Label("新闻影响", systemImage: "newspaper")
                    }
                    if focus.volumeSpike {
                        Label("成交量异常", systemImage: "chart.bar")
                    }
                    if focus.correlationAnalysis {
                        Label("相关性分析", systemImage: "link")
                    }
                }
            }

            if !findings.isEmpty {
                Section("监控发现 (\(findings.count))") {
                    ForEach(findings.prefix(10), id: \.id) { finding in
                        FindingRow(finding: finding)
                    }
                }
            }

            if let analysis = analysis {
                Section("AI分析报告") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(analysis.title)
                            .font(.headline)

                        Text(analysis.summary)
                            .font(.caption)

                        if let keyFindings = analysis.keyFindings, !keyFindings.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("关键发现")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(keyFindings, id: \.self) { finding in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(finding)
                                            .font(.caption)
                                    }
                                }
                            }
                        }

                        if let priceAnalysis = analysis.priceAnalysis {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("价格分析")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(priceAnalysis)
                                    .font(.caption)
                            }
                        }

                        if let actionSuggestions = analysis.actionSuggestions, !actionSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("行动建议")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(actionSuggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top) {
                                        Text("→")
                                            .foregroundColor(.blue)
                                        Text(suggestion)
                                            .font(.caption)
                                    }
                                }
                            }
                        }

                        HStack {
                            Text("风险等级")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(analysis.riskLevel ?? "未知")
                                .font(.caption)
                                .foregroundColor(riskColor)
                        }

                        HStack {
                            Text("置信度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(analysis.confidence)%")
                                .font(.caption)
                                .foregroundColor(confidenceColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("操作") {
                if focusItem.status == .active {
                    Button(action: {
                        Task {
                            await loadAnalysis()
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("生成AI分析")
                        }
                    }
                    .disabled(isLoadingAnalysis)

                    Button(action: {
                        Task {
                            await extendFocus()
                        }
                    }) {
                        HStack {
                            Image(systemName: "clock")
                            Text("延长监控期")
                        }
                    }
                }

                Button(role: .destructive, action: {
                    // TODO: 删除确认
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除关注")
                    }
                }
            }
        }
        .navigationTitle(focusItem.title)
        .task {
            await loadFindings()
        }
    }

    private var statusText: String {
        switch focusItem.status {
        case .active: return "监控中"
        case .completed: return "已完成"
        case .expired: return "已过期"
        }
    }

    private var statusColor: Color {
        switch focusItem.status {
        case .active: return .green
        case .completed: return .blue
        case .expired: return .gray
        }
    }

    private var expiryDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: focusItem.expiresAt)
    }

    private var riskColor: Color {
        guard let risk = analysis?.riskLevel else { return .gray }
        switch risk {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .gray
        }
    }

    private var confidenceColor: Color {
        if analysis?.confidence ?? 0 >= 80 {
            return .green
        } else if analysis?.confidence ?? 0 >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private func loadFindings() async {
        do {
            findings = try await APIService.shared.getTemporaryFocusFindings(id: focusItem.id)
        } catch {
            print("Failed to load findings: \(error)")
        }
    }

    private func loadAnalysis() async {
        isLoadingAnalysis = true
        defer { isLoadingAnalysis = false }

        do {
            analysis = try await APIService.shared.getFocusAnalysis(focusItemId: focusItem.id)
        } catch {
            print("Failed to load analysis: \(error)")
        }
    }

    private func extendFocus() async {
        do {
            let newDate = Calendar.current.date(byAdding: .day, value: 7, to: focusItem.expiresAt) ?? focusItem.expiresAt
            _ = try await APIService.shared.extendTemporaryFocus(id: focusItem.id, newExpiryDate: newDate)
        } catch {
            print("Failed to extend focus: \(error)")
        }
    }
}

// MARK: - 监控发现行视图

struct FindingRow: View {
    let finding: FocusFinding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(finding.title)
                .font(.caption)

            Text(finding.description)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text(formatDate(finding.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(finding.importanceScore)分")
                    .font(.caption2)
                    .foregroundColor(importanceColor)
            }
        }
    }

    private var importanceColor: Color {
        if finding.importanceScore >= 80 {
            return .red
        } else if finding.importanceScore >= 60 {
            return .orange
        } else {
            return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 创建临时关注视图

struct CreateTemporaryFocusView: View {
    let userId: UUID
    let onCreate: (TemporaryFocus) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var targets = ""
    @State private var selectedDuration: Duration = .oneDay
    @State private var priceReaction = true
    @State private var newsImpact = true
    @State private var volumeSpike = false
    @State private var correlationAnalysis = false
    @Environment(\.dismiss) private var dismiss

    enum Duration: String, CaseIterable {
        case oneDay = "1天"
        case threeDays = "3天"
        case oneWeek = "1周"
        case twoWeeks = "2周"

        var timeInterval: TimeInterval {
            switch self {
            case .oneDay: return 86400
            case .threeDays: return 259200
            case .oneWeek: return 604800
            case .twoWeeks: return 1209600
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)

                    TextField("描述（可选）", text: $description)
                }

                Section("监控目标") {
                    TextEditor(text: $targets)
                        .frame(height: 100)
                    Text("输入股票代码，用逗号分隔（如：NVDA, AAPL, MSFT）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("监控时长") {
                    Picker("时长", selection: $selectedDuration) {
                        ForEach(Duration.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("监控类型") {
                    Toggle("价格反应", isOn: $priceReaction)
                    Toggle("新闻影响", isOn: $newsImpact)
                    Toggle("成交量异常", isOn: $volumeSpike)
                    Toggle("相关性分析", isOn: $correlationAnalysis)
                }

                Section {
                    Button("创建监控") {
                        createFocus()
                    }
                    .disabled(title.isEmpty || targets.isEmpty)
                }
            }
            .navigationTitle("创建临时关注")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func createFocus() {
        let targetSymbols = targets.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }

        let expiresAt = Date(timeIntervalSinceNow: selectedDuration.timeInterval)

        let focus = FocusConfiguration(
            priceReaction: priceReaction,
            newsImpact: newsImpact,
            volumeSpike: volumeSpike,
            correlationAnalysis: correlationAnalysis
        )

        let item = TemporaryFocus(
            id: UUID(),
            userId: userId,
            title: title,
            description: description,
            targets: targetSymbols,
            focus: focus,
            status: .active,
            createdAt: Date(),
            expiresAt: expiresAt
        )

        onCreate(item)
        dismiss()
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

// MARK: - 设置视图

struct SettingsView: View {
    let userId: UUID
    @State private var user: User?
    @State private var isLoading = false
    @State private var pushEnabled = true
    @State private var timezone = "Asia/Shanghai"
    @State private var currency = "USD"
    @State private var language = "zh-CN"

    var body: some View {
        NavigationView {
            List {
                Section("用户信息") {
                    if let user = user {
                        HStack {
                            Text("用户ID")
                            Spacer()
                            Text(user.id.uuidString.prefix(8) + "...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }

                        HStack {
                            Text("注册时间")
                            Spacer()
                            Text(formatDate(user.createdAt))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("通知设置") {
                    Toggle("启用推送通知", isOn: $pushEnabled)
                        .onChange(of: pushEnabled) { newValue in
                            Task {
                                await updatePreferences()
                            }
                        }
                }

                Section("地区设置") {
                    Picker("时区", selection: $timezone) {
                        Text("中国标准时间").tag("Asia/Shanghai")
                        Text("美东时间").tag("America/New_York")
                        Text("美西时间").tag("America/Los_Angeles")
                        Text("UTC").tag("UTC")
                    }
                    .onChange(of: timezone) { _ in
                        Task {
                            await updatePreferences()
                        }
                    }

                    Picker("货币", selection: $currency) {
                        Text("美元 (USD)").tag("USD")
                        Text("人民币 (CNY)").tag("CNY")
                        Text("欧元 (EUR)").tag("EUR")
                    }
                    .onChange(of: currency) { _ in
                        Task {
                            await updatePreferences()
                        }
                    }

                    Picker("语言", selection: $language) {
                        Text("简体中文").tag("zh-CN")
                        Text("English").tag("en-US")
                    }
                    .onChange(of: language) { _ in
                        Task {
                            await updatePreferences()
                        }
                    }
                }

                Section("系统信息") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("v2.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: AnalysisHistoryView(userId: userId)) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("AI分析历史")
                        }
                    }

                    NavigationLink(destination: EventAnalysisListView()) {
                        HStack {
                            Image(systemName: "newspaper")
                            Text("市场事件分析")
                        }
                    }
                }

                Section {
                    Button(action: {
                        // TODO: 退出登录
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("退出登录")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("设置")
            .task {
                await loadUserData()
            }
        }
    }

    private func loadUserData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await APIService.shared.getUser(id: userId)
            if let preferences = user?.preferences {
                pushEnabled = preferences.pushEnabled ?? true
                timezone = preferences.timezone ?? "Asia/Shanghai"
                currency = preferences.currency ?? "USD"
                language = preferences.language ?? "zh-CN"
            }
        } catch {
            print("Failed to load user: \(error)")
        }
    }

    private func updatePreferences() async {
        do {
            let preferences = UserPreferences(
                pushEnabled: pushEnabled,
                timezone: timezone,
                currency: currency,
                language: language
            )
            _ = try await APIService.shared.updateUserPreferences(
                id: userId,
                preferences: preferences
            )
        } catch {
            print("Failed to update preferences: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - AI分析历史视图

struct AnalysisHistoryView: View {
    let userId: UUID
    @State private var strategyAnalyses: [StrategyAnalysis] = []
    @State private var focusAnalyses: [FocusAnalysis] = []
    @State private var selectedSegment: AnalysisSegment = .strategies
    @State private var isLoading = false

    enum AnalysisSegment: String, CaseIterable {
        case strategies = "策略分析"
        case focus = "关注分析"
    }

    var body: some View {
        List {
            Picker("", selection: $selectedSegment) {
                ForEach(AnalysisSegment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)

            switch selectedSegment {
            case .strategies:
                strategyAnalysesContent
            case .focus:
                focusAnalysesContent
            }
        }
        .navigationTitle("AI分析历史")
        .task {
            await loadAnalyses()
        }
    }

    private var strategyAnalysesContent: some View {
        Group {
            if isLoading && strategyAnalyses.isEmpty {
                ProgressView()
            } else if strategyAnalyses.isEmpty {
                Text("暂无策略分析")
                    .foregroundColor(.secondary)
            } else {
                ForEach(strategyAnalyses) { analysis in
                    NavigationLink(destination: StrategyAnalysisDetailView(analysis: analysis)) {
                        StrategyAnalysisRow(analysis: analysis)
                    }
                }
            }
        }
    }

    private var focusAnalysesContent: some View {
        Group {
            if isLoading && focusAnalyses.isEmpty {
                ProgressView()
            } else if focusAnalyses.isEmpty {
                Text("暂无关注分析")
                    .foregroundColor(.secondary)
            } else {
                ForEach(focusAnalyses) { analysis in
                    NavigationLink(destination: FocusAnalysisDetailView(analysis: analysis)) {
                        FocusAnalysisRow(analysis: analysis)
                    }
                }
            }
        }
    }

    private func loadAnalyses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            strategyAnalyses = try await APIService.shared.getUserStrategyAnalyses(userId: userId)
            focusAnalyses = try await APIService.shared.getUserFocusAnalyses(userId: userId)
        } catch {
            print("Failed to load analyses: \(error)")
        }
    }
}

// MARK: - 策略分析行

struct StrategyAnalysisRow: View {
    let analysis: StrategyAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(analysis.title)
                .font(.headline)

            if let triggerReason = analysis.triggerReason {
                Text(triggerReason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(formatDate(analysis.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("置信度 \(analysis.confidence)%")
                    .font(.caption2)
                    .foregroundColor(confidenceColor)
            }
        }
        .padding(.vertical, 4)
    }

    private var confidenceColor: Color {
        if analysis.confidence >= 80 {
            return .green
        } else if analysis.confidence >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 关注分析行

struct FocusAnalysisRow: View {
    let analysis: FocusAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(analysis.title)
                .font(.headline)

            Text(analysis.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text(formatDate(analysis.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if let risk = analysis.riskLevel {
                    Text(riskText(risk))
                        .font(.caption2)
                        .foregroundColor(riskColor(risk))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func riskText(_ risk: String) -> String {
        switch risk {
        case "low": return "低风险"
        case "medium": return "中风险"
        case "high": return "高风险"
        default: return risk
        }
    }

    private func riskColor(_ risk: String) -> Color {
        switch risk {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 策略分析详情

struct StrategyAnalysisDetailView: View {
    let analysis: StrategyAnalysis

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和置信度
                VStack(alignment: .leading, spacing: 8) {
                    Text(analysis.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Text("置信度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: Double(analysis.confidence) / 100.0)
                        Text("\(analysis.confidence)%")
                            .font(.caption)
                            .foregroundColor(confidenceColor)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)

                // 触发原因
                if let triggerReason = analysis.triggerReason {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("触发原因", systemImage: "bolt.fill")
                            .font(.headline)
                        Text(triggerReason)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }

                // 市场背景
                if let marketContext = analysis.marketContext {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("市场背景", systemImage: "chart.bar")
                            .font(.headline)
                        Text(marketContext)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }

                // 技术分析
                if let technicalAnalysis = analysis.technicalAnalysis {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("技术分析", systemImage: "waveform.path")
                            .font(.headline)
                        Text(technicalAnalysis)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                // 风险评估
                if let riskAssessment = analysis.riskAssessment {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("风险评估", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Text(riskAssessment)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }

                // 行动建议
                if let actionSuggestion = analysis.actionSuggestion {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("行动建议", systemImage: "lightbulb.fill")
                            .font(.headline)
                        Text(actionSuggestion)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }

                // 元数据
                VStack(alignment: .leading, spacing: 8) {
                    Text("分析时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(analysis.createdAt))
                        .font(.caption)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("分析详情")
    }

    private var confidenceColor: Color {
        if analysis.confidence >= 80 {
            return .green
        } else if analysis.confidence >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 关注分析详情

struct FocusAnalysisDetailView: View {
    let analysis: FocusAnalysis

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和风险等级
                VStack(alignment: .leading, spacing: 8) {
                    Text(analysis.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        if let risk = analysis.riskLevel {
                            Text(riskText(risk))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(riskColor(risk))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Spacer()

                        Text("置信度 \(analysis.confidence)%")
                            .font(.caption)
                            .foregroundColor(confidenceColor)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)

                // 总结
                VStack(alignment: .leading, spacing: 8) {
                    Label("总结", systemImage: "doc.text")
                        .font(.headline)
                    Text(analysis.summary)
                        .font(.body)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // 关键发现
                if let keyFindings = analysis.keyFindings, !keyFindings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("关键发现", systemImage: "star.fill")
                            .font(.headline)
                        ForEach(Array(keyFindings.enumerated()), id: \.offset) { _, finding in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(.blue)
                                Text(finding)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                }

                // 价格分析
                if let priceAnalysis = analysis.priceAnalysis {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("价格分析", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                        Text(priceAnalysis)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }

                // 相关性分析
                if let correlationAnalysis = analysis.correlationAnalysis {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("相关性分析", systemImage: "link")
                            .font(.headline)
                        Text(correlationAnalysis)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }

                // 行动建议
                if let actionSuggestions = analysis.actionSuggestions, !actionSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("行动建议", systemImage: "lightbulb.fill")
                            .font(.headline)
                        ForEach(Array(actionSuggestions.enumerated()), id: \.offset) { _, suggestion in
                            HStack(alignment: .top) {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.blue)
                                Text(suggestion)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                // 元数据
                VStack(alignment: .leading, spacing: 8) {
                    Text("分析时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(analysis.createdAt))
                        .font(.caption)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("分析报告")
    }

    private func riskText(_ risk: String) -> String {
        switch risk {
        case "low": return "低风险"
        case "medium": return "中风险"
        case "high": return "高风险"
        default: return risk
        }
    }

    private func riskColor(_ risk: String) -> Color {
        switch risk {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .gray
        }
    }

    private var confidenceColor: Color {
        if analysis.confidence >= 80 {
            return .green
        } else if analysis.confidence >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 市场事件分析列表

struct EventAnalysisListView: View {
    @State private var eventAnalyses: [EventAnalysis] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading && eventAnalyses.isEmpty {
                ProgressView("加载中...")
            } else if eventAnalyses.isEmpty {
                Text("暂无事件分析")
                    .foregroundColor(.secondary)
            } else {
                ForEach(eventAnalyses) { analysis in
                    EventAnalysisRow(analysis: analysis)
                }
            }
        }
        .navigationTitle("市场事件分析")
        .task {
            await loadEventAnalyses()
        }
    }

    private func loadEventAnalyses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            eventAnalyses = try await APIService.shared.getEventAnalyses()
        } catch {
            print("Failed to load event analyses: \(error)")
        }
    }
}

// MARK: - 事件分析行

struct EventAnalysisRow: View {
    let analysis: EventAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(analysis.title)
                .font(.headline)

            if let eventSummary = analysis.eventSummary {
                Text(eventSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(formatDate(analysis.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if let severity = analysis.severity {
                    Text(severityText(severity))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(severityColor(severity).opacity(0.2))
                        .foregroundColor(severityColor(severity))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func severityText(_ severity: String) -> String {
        switch severity {
        case "critical": return "严重"
        case "high": return "高"
        case "medium": return "中"
        case "low": return "低"
        default: return severity
        }
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .green
        default: return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 预览

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
