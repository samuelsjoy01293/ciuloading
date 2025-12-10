import Foundation
import SwiftData

@Model
final class Product {
    var id: UUID
    var name: String
    var expirationDate: Date
    var category: String // storing category name for simplicity, or could be a relationship
    var storageLocation: String
    var quantity: String
    var photoPath: String? // Filename in documents directory
    var notes: String
    var createdAt: Date
    var isConsumed: Bool // To keep history if needed, or just delete
    
    init(name: String, expirationDate: Date, category: String, storageLocation: String, quantity: String = "1", photoPath: String? = nil, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.expirationDate = expirationDate
        self.category = category
        self.storageLocation = storageLocation
        self.quantity = quantity
        self.photoPath = photoPath
        self.notes = notes
        self.createdAt = Date()
        self.isConsumed = false
    }
}

