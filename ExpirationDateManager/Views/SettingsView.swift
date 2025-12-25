import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var products: [Product]
    @Environment(\.modelContext) private var modelContext
    
    // AppStorage for simple settings, or could use AppSettings model. 
    // Using AppStorage for simplicity in this view logic as it updates UI automatically.
    // If using AppSettings SwiftData model, we would query it. 
    // Let's use AppStorage for local prefs like theme/notifications to avoid complex SwiftData fetch/init logic for singletons.
    // But plan said SwiftData. I'll stick to AppStorage for standard prefs and SwiftData for domain data.
    // Actually, I created AppSettings model. Let's use it if possible, or fallback to AppStorage. 
    // For MVP speed and reliability, AppStorage is standard for "Settings" screen.
    @AppStorage("warningDays") private var warningDays = 7
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("isDarkMode") private var isDarkMode = false // Simplified theme (System/Dark/Light usually needs 3 states)
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationService.shared.requestPermissions()
                                NotificationService.shared.scheduleDailyNotification(at: 9, minute: 0, products: products)
                            } else {
                                NotificationService.shared.cancelNotifications()
                            }
                        }
                    
                    Picker("Warning Days Before", selection: $warningDays) {
                        Text("1 Day").tag(1)
                        Text("3 Days").tag(3)
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                    }
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _, _ in
                            // Notify MainTabView to update theme
                            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
                        }
                }
                
                Section("Data Management") {
                    Button(action: {
                        if let url = ExportService.createPDF(from: products) {
                            exportURL = url
                            showExportSheet = true
                        }
                    }) {
                        Label("Export as PDF", systemImage: "doc.text")
                    }
                    
                    Button(action: {
                        if let url = ExportService.createCSV(from: products) {
                            exportURL = url
                            showExportSheet = true
                        }
                    }) {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Clear All Data")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("Expiration Date Manager v1.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar(.hidden, for: .tabBar)
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Are you sure?", isPresented: $showDeleteAlert) {
                Button("Delete All", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            .preferredColorScheme(isDarkMode ? .dark : nil)
            .animation(.easeInOut(duration: 0.2), value: isDarkMode)
            .id(isDarkMode) // Force view update when theme changes
            .onChange(of: products.count) { _, _ in
                // Update notification when products change
                if notificationsEnabled {
                    NotificationService.shared.updateDailyNotification(products: products)
                }
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: Product.self)
            // Keeping categories
            HapticsManager.shared.notification(type: .success)
        } catch {
            print("Failed to delete data")
        }
    }
}

#Preview {
    SettingsView()
}

