import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    var defaultExpirationDays: Int
    var isCustom: Bool
    var iconName: String
    
    init(name: String, defaultExpirationDays: Int = 365, isCustom: Bool = false, iconName: String = "tag") {
        self.name = name
        self.defaultExpirationDays = defaultExpirationDays
        self.isCustom = isCustom
        self.iconName = iconName
    }
    
    static let defaultCategories: [Category] = [
        Category(name: "Dairy", defaultExpirationDays: 14, iconName: "dairy"),
        Category(name: "Grains", defaultExpirationDays: 365, iconName: "grains"),
        Category(name: "Canned Goods", defaultExpirationDays: 730, iconName: "canned_food"),
        Category(name: "Cosmetics", defaultExpirationDays: 365, iconName: "cosmetics"),
        Category(name: "Medicines", defaultExpirationDays: 365, iconName: "medicines"),
        Category(name: "Household Chemicals", defaultExpirationDays: 730, iconName: "household"),
        Category(name: "Oils", defaultExpirationDays: 365, iconName: "oils"),
        Category(name: "Pet Food", defaultExpirationDays: 180, iconName: "pet_food"),
        Category(name: "Frozen Foods", defaultExpirationDays: 180, iconName: "frozen_food"),
        Category(name: "Beverages", defaultExpirationDays: 180, iconName: "beverages"),
        Category(name: "Snacks", defaultExpirationDays: 90, iconName: "snacks"),
        Category(name: "Spices", defaultExpirationDays: 730, iconName: "spices"),
        Category(name: "Sauces", defaultExpirationDays: 180, iconName: "sauces"),
        Category(name: "Meat", defaultExpirationDays: 3, iconName: "meat"),
        Category(name: "Fish", defaultExpirationDays: 2, iconName: "fish"),
        Category(name: "Vegetables", defaultExpirationDays: 7, iconName: "vegetables"),
        Category(name: "Fruits", defaultExpirationDays: 7, iconName: "fruits"),
        Category(name: "Bakery", defaultExpirationDays: 3, iconName: "bakery"),
        Category(name: "Sweets", defaultExpirationDays: 30, iconName: "sweets"),
        Category(name: "Baby Food", defaultExpirationDays: 30, iconName: "baby_food"),
        Category(name: "Cleaning Supplies", defaultExpirationDays: 730, iconName: "cleaning_supplies"),
        Category(name: "Personal Care", defaultExpirationDays: 365, iconName: "comb"),
        Category(name: "Batteries", defaultExpirationDays: 1825, iconName: "batteries"),
        Category(name: "Other", defaultExpirationDays: 365, iconName: "questionmark.circle")
    ]
}
