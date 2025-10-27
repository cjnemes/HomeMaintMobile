import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            AssetListView()
                .tabItem {
                    Label("Assets", systemImage: "house.fill")
                }
                .tag(1)

            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Management") {
                    NavigationLink {
                        ServiceProviderListView()
                    } label: {
                        Label("Service Providers", systemImage: "person.2.fill")
                    }
                }

                Section("App") {
                    Text("Version 1.0.0")
                }

                Section("Data") {
                    Button("Backup Database") {
                        // TODO: Implement backup
                    }

                    Button("Export Data") {
                        // TODO: Implement export
                    }

                    Button(role: .destructive) {
                        // TODO: Implement reset
                    } label: {
                        Text("Reset All Data")
                    }
                }

                Section("About") {
                    Text("HomeMaint Mobile")
                    Text("Built with SwiftUI")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}
