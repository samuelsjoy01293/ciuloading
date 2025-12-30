import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var themeUpdateTrigger = UUID()
    
    var body: some View {
        ZStack {
            // Background that covers entire screen including safe areas
            Theme.Colors.secondaryBackground
                .ignoresSafeArea(.all)
            
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Overview", systemImage: "house")
                    }
                    .tag(0)
                
                ProductListView()
                    .tabItem {
                        Label("Items", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                CategoriesView()
                    .tabItem {
                        Label("Categories", systemImage: "square.grid.2x2")
                    }
                    .tag(2)
                
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(3)
            }
            .tint(Theme.Colors.accent)
            .preferredColorScheme(isDarkMode ? .dark : nil) // Global theme application
            .animation(.easeInOut(duration: 0.3), value: isDarkMode) // Smooth tab bar animation
            .background(Theme.Colors.secondaryBackground)
            .toolbarBackground(Theme.Colors.secondaryBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
        .onAppear {
            // Ensure notification permissions are requested on first launch if default is true
            if UserDefaults.standard.object(forKey: "notificationsEnabled") == nil {
                UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                NotificationService.shared.requestPermissions()
            }
            
            // Update notification with current products count when app launches
            if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                // We need to get products from environment, but we can't use @Query here
                // So we'll update it from DashboardView which has @Query
            }
        }
        .onChange(of: isDarkMode) { oldValue, newValue in
            // Force view update when theme changes
            themeUpdateTrigger = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ThemeChanged"))) { _ in
            // Force view update when theme changes from SettingsView
            themeUpdateTrigger = UUID()
        }
        .id(themeUpdateTrigger)
    }
}

#Preview {
    MainTabView()
}
