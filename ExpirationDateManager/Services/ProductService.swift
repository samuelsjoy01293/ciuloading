import Foundation
import SwiftData
import SwiftUI

@Observable
class ProductService {
    var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func addProduct(_ product: Product) {
        modelContext?.insert(product)
        // Schedule notification if needed
    }
    
    func deleteProduct(_ product: Product) {
        modelContext?.delete(product)
        // Remove notification
    }
    
    func updateProduct() {
        // SwiftData autosaves, but explicit save can be called if needed
        try? modelContext?.save()
    }
    
    func products(for date: Date) -> [Product] {
        // This would typically be a fetch descriptor, but for a helper:
        // Implementation depends on having access to data. 
        // In SwiftUI views, we use @Query. This service might be better as a logic helper.
        return [] 
    }
}

