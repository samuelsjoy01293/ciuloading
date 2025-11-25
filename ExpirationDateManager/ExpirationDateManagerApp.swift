//
//  ExpirationDateManagerApp.swift
//  ExpirationDateManager
//
//  Created by cybercrot on 21.11.2025.
//

import SwiftUI
import SwiftData

@main
struct ExpirationDateManagerApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Product.self,
                Category.self,
                AppSettings.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Initialize defaults
            CategoryService.initializeDefaults(modelContext: container.mainContext)
            
            // Setup notification delegate for foreground notifications
            UNUserNotificationCenter.current().delegate = NotificationService.shared
            
            // UI Appearance
            // Search bar styling - transparent background, white text field
            // Note: In SwiftUI, searchable creates its own search bar, so we need to style it properly
            UISearchBar.appearance().barTintColor = .clear
            UISearchBar.appearance().backgroundColor = .clear
            UISearchBar.appearance().backgroundImage = UIImage()
            UISearchBar.appearance().searchBarStyle = .minimal
            // Make the search text field container white (only the input field)
            UISearchTextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = .white
            
            // Navigation bar title color - use label color which adapts to theme
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
