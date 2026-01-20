import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var userId: UUID = UUID()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无关注列表")
                            .foregroundColor(.secondary)
                        Text("点击右上角 + 添加关注")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(viewModel.watchlistItems) { item in
                        WatchlistItemRow(item: item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteWatchlistItem(item)
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
            .navigationTitle("关注列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWatchlistItemSheet(viewModel: viewModel)
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
                await viewModel.loadWatchlist()
            }
        }
    }
}

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

            if let price = item.currentPrice {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyString(price))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let change = item.changePercent {
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text("\(String(format: "%.2f", change))%")
                                .font(.caption)
                        }
                        .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            } else {
                Text("价格加载中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct AddWatchlistItemSheet: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @Environment(\.dismiss) var dismiss

    @State private var symbol = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("股票信息")) {
                    TextField("股票代码", text: $symbol)
                        .textInputAutocapitalization(.characters)
                }

                Section(header: Text("备注（可选）")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("添加关注")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        Task {
                            await viewModel.addWatchlistItem(
                                symbol: symbol,
                                notes: notes.isEmpty ? nil : notes
                            )
                            dismiss()
                        }
                    }
                    .disabled(symbol.isEmpty)
                }
            }
        }
    }
}

#Preview {
    WatchlistView()
}
