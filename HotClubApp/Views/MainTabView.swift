import SwiftUI

struct MainTabView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        TabView {
            RecordsListView()
                .tabItem { Label("Records", systemImage: "opticaldisc") }
            CreateRecordView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(theme.accent)
    }
}
