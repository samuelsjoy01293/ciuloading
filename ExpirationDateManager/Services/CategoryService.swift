import Foundation
import SwiftData

class CategoryService {
    static func initializeDefaults(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        
        do {
            let existingCategories = try modelContext.fetch(descriptor)
            
            if existingCategories.isEmpty {
                // Create all defaults
                for category in Category.defaultCategories {
                    modelContext.insert(category)
                }
            } else {
                // Update existing categories icons
                let defaultMap = Dictionary(uniqueKeysWithValues: Category.defaultCategories.map { ($0.name, $0.iconName) })
                
                for category in existingCategories {
                    // If it's a default category (found in map), update its icon
                    if let correctIconName = defaultMap[category.name] {
                        if category.iconName != correctIconName {
                            category.iconName = correctIconName
                        }
                    }
                    
                    // Remove "Vitamins" if present (as requested)
                    if category.name == "Vitamins" {
                        modelContext.delete(category)
                    }
                }
            }
            
            try? modelContext.save()
            
        } catch {
            print("Failed to initialize categories: \(error)")
        }
    }
}
