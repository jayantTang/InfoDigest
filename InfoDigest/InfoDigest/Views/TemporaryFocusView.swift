import SwiftUI

struct TemporaryFocusView: View {
    @StateObject private var viewModel = TemporaryFocusViewModel()
    @State private var userId: UUID = UUID()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "eye")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无临时关注")
                            .foregroundColor(.secondary)
                        Text("点击右上角 + 创建临时关注")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(viewModel.focusItems) { item in
                        TemporaryFocusRow(item: item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteFocusItem(item)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .navigationTitle("临时关注")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateTemporaryFocusSheet(viewModel: viewModel)
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
                await viewModel.loadFocusItems()
            }
        }
    }
}

struct TemporaryFocusRow: View {
    let item: TemporaryFocus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)

                Spacer()

                statusBadge(item.status)
            }

            if let description = item.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Label("\(item.targets.count)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(expiresText(item.expiresAt))
                    .font(.caption)
                    .foregroundColor(expiredColor(item.expiresAt, item.status))
            }

            // 关注配置
            FocusConfigSummary(focus: item.focus)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: TemporaryFocus.FocusStatus) -> some View {
        Text(statusText(status))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.2))
            .foregroundColor(statusColor(status))
            .cornerRadius(8)
    }

    private func statusText(_ status: TemporaryFocus.FocusStatus) -> String {
        switch status {
        case .monitoring: return "监控中"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .extended: return "已延长"
        }
    }

    private func statusColor(_ status: TemporaryFocus.FocusStatus) -> Color {
        switch status {
        case .monitoring: return .green
        case .completed: return .blue
        case .cancelled: return .gray
        case .extended: return .orange
        }
    }

    private func expiresText(_ date: Date) -> String {
        let isExpired = date < Date()
        if isExpired {
            return "已过期"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "过期: " + formatter.localizedString(for: date, relativeTo: Date())
        }
    }

    private func expiredColor(_ date: Date, _ status: TemporaryFocus.FocusStatus) -> Color {
        if date < Date() || status == .completed || status == .cancelled {
            return .red
        } else {
            return .secondary
        }
    }
}

struct FocusConfigSummary: View {
    let focus: TemporaryFocus.FocusConfiguration

    var body: some View {
        HStack(spacing: 12) {
            if focus.newsImpact {
                ConfigIcon(icon: "newspaper.fill", color: .blue, label: "新闻")
            }
            if focus.priceReaction {
                ConfigIcon(icon: "chart.line.fill", color: .green, label: "价格")
            }
            if focus.correlation {
                ConfigIcon(icon: "link", color: .purple, label: "相关")
            }
            if focus.sectorEffect {
                ConfigIcon(icon: "square.grid.3x3.fill", color: .orange, label: "板块")
            }
        }
        .font(.caption)
    }

    struct ConfigIcon: View {
        let icon: String
        let color: Color
        let label: String

        var body: some View {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CreateTemporaryFocusSheet: View {
    @ObservedObject var viewModel: TemporaryFocusViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var targetsString = ""
    @State private var hoursDuration = 24

    @State private var newsImpact = true
    @State private var priceReaction = true
    @State private var correlation = false
    @State private var sectorEffect = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)

                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(header: Text("监控标的")) {
                    TextEditor(text: $targetsString)
                        .frame(minHeight: 80)
                    Text("每行一个股票代码，例如：AAPL、NVDA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("监控配置")) {
                    Toggle("新闻影响", isOn: $newsImpact)
                    Toggle("价格反应", isOn: $priceReaction)
                    Toggle("相关性分析", isOn: $correlation)
                    Toggle("板块效应", isOn: $sectorEffect)
                }

                Section(header: Text("监控时长")) {
                    VStack {
                        HStack {
                            Text("时长")
                            Spacer()
                            Text("\(hoursDuration) 小时")
                                .foregroundColor(.blue)
                        }
                        Slider(value: Binding(
                            get: { Double(hoursDuration) },
                            set: { hoursDuration = Int($0) }
                        ), in: 1...168, step: 1)
                    }
                }
            }
            .navigationTitle("创建临时关注")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        let targets = targetsString.components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                            .filter { !$0.isEmpty }

                        let expiresAt = ISO8601DateFormatter().string(
                            from: Date().addingTimeInterval(Double(hoursDuration) * 3600)
                        )

                        let focus: [String: Bool] = [
                            "newsImpact": newsImpact,
                            "priceReaction": priceReaction,
                            "correlation": correlation,
                            "sectorEffect": sectorEffect
                        ]

                        Task {
                            await viewModel.createFocusItem(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                targets: targets,
                                focus: focus,
                                expiresAt: expiresAt
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || targetsString.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TemporaryFocusView()
}
