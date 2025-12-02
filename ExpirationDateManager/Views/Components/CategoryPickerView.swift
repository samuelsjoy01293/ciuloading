import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Query(sort: \Category.name, order: .forward) private var categories: [Category]
    @Environment(\.dismiss) private var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @Binding var selectedCategory: Category?
    @Binding var expirationDate: Date
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(categories) { category in
                        Button(action: {
                            selectedCategory = category
                            // Auto-set date based on category default
                            expirationDate = Date().addingTimeInterval(TimeInterval(category.defaultExpirationDays * 86400))
                            HapticsManager.shared.selection()
                            dismiss()
                        }) {
                            CategoryPickerCard(category: category, isSelected: selectedCategory?.id == category.id)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Category")
            .background(Theme.Colors.secondaryBackground)
        }
    }
}

struct CategoryPickerCard: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if let _ = UIImage(named: category.iconName) {
                Image(category.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textPrimary)
                    .frame(width: 50, height: 50)
            }
            
            Text(category.name)
                .font(Theme.Fonts.title(14))
                .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(isSelected ? Theme.Colors.accent.opacity(0.1) : Theme.Colors.background)
        .cornerRadius(Theme.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

