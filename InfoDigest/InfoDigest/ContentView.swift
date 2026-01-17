import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MessageListView()
                .tabItem {
                    Label("消息", systemImage: "message.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
