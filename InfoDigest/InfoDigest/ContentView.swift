import SwiftUI

/// InfoDigest v2.0 主界面 - 投资机会为主页
struct ContentView: View {
    @State private var selectedTab: TabSelection = .opportunities
    @State private var userId: UUID = UUID()

    enum TabSelection {
        case opportunities  // 主页
        case economic      // 经济形势
        case more          // 更多功能
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 投资机会 - 主页
            OpportunitiesView()
                .tabItem {
                    Label("投资机会", systemImage: "lightbulb.fill")
                }
                .tag(TabSelection.opportunities)

            // 经济形势
            EconomicIndicatorView()
                .tabItem {
                    Label("经济形势", systemImage: "chart.bar.fill")
                }
                .tag(TabSelection.economic)

            // 更多功能
            MoreFeaturesView()
                .tabItem {
                    Label("更多", systemImage: "ellipsis.circle")
                }
                .tag(TabSelection.more)
        }
        .accentColor(.orange)
    }
}

// MARK: - 更多功能页面

struct MoreFeaturesView: View {
    @State private var userId: UUID = UUID()

    var body: some View {
        NavigationView {
            List {
                // 核心功能
                Section(header: Text("核心功能")) {
                    NavigationLink(destination: DashboardView().navigationTitle("仪表板")) {
                        Label("仪表板", systemImage: "chart.bar.doc.horizontal")
                    }

                    NavigationLink(destination: EconomicIndicatorView().navigationTitle("经济形势")) {
                        Label("经济形势", systemImage: "chart.bar.fill")
                    }

                    NavigationLink(destination: OpportunitiesView().navigationTitle("投资机会")) {
                        Label("投资机会分析", systemImage: "lightbulb.fill")
                            .foregroundColor(.orange)
                    }
                }

                // 投资管理
                Section(header: Text("投资管理")) {
                    NavigationLink(destination: PortfolioView().navigationTitle("投资组合")) {
                        Label("投资组合", systemImage: "briefcase")
                    }

                    NavigationLink(destination: WatchlistView().navigationTitle("关注列表")) {
                        Label("关注列表", systemImage: "star")
                    }
                }

                // 策略和监控
                Section(header: Text("策略和监控")) {
                    NavigationLink(destination: StrategiesView().navigationTitle("策略管理")) {
                        Label("策略管理", systemImage: "gearshape.2")
                    }

                    NavigationLink(destination: TemporaryFocusView().navigationTitle("临时关注")) {
                        Label("临时关注", systemImage: "eye")
                    }

                    NavigationLink(destination: MonitoringView().navigationTitle("监控状态")) {
                        Label("监控状态", systemImage: "waveform.path")
                    }
                }
            }
            .navigationTitle("更多功能")
        }
    }
}

#Preview {
    ContentView()
}
