import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                FlowsView()
            }
            .tabItem {
                Label("流程", systemImage: "arrow.triangle.branch")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("历史", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
        }
    }
}
