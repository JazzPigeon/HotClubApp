import SwiftUI

private enum AppTab: Int {
    case records = 0
    case add = 1
    case settings = 2
}

struct MainTabView: View {
    @Environment(\.appTheme) private var theme
    @State private var selectedTab: AppTab = .records

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordsListView()
                .tabItem { Label("Records", systemImage: "opticaldisc") }
                .tag(AppTab.records)
            CreateRecordView {
                selectedTab = .records
            }
            .tabItem { Label("Add", systemImage: "plus.circle.fill") }
            .tag(AppTab.add)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(theme.accent)
    }
}
