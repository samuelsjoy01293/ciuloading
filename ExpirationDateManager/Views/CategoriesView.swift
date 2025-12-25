import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: \Category.name, order: .forward) private var categories: [Category]
    @State private var showAddCategory = false
    @State private var searchText = ""
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header - Always visible
                HStack {
                    Text("Categories")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Theme.Colors.secondaryBackground)
                
                // Custom Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.leading, 8)
                    
                    TextField("Search categories", text: $searchText)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                }
                .background(Theme.Colors.background)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Theme.Colors.secondaryBackground)
                
                // Categories Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredCategories) { category in
                            NavigationLink(destination: CategoryDetailView(category: category)) {
                                CategoryCard(category: category)
                            }
                        }
                    }
                    .padding()
                }
                .background(Theme.Colors.secondaryBackground)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(Theme.Colors.secondaryBackground)
            .ignoresSafeArea(.all, edges: .horizontal)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView()
            }
        }
    }
}

struct CategoryCard: View {
    let category: Category
    @Query private var products: [Product]
    
    init(category: Category) {
        self.category = category
        let name = category.name
        _products = Query(filter: #Predicate<Product> { $0.category == name })
    }
    
    // Color based on category name hash for variety
    private var categoryColor: Color {
        let colors: [Color] = [
            Theme.Colors.accent,
            Theme.Colors.cardBlue,
            Theme.Colors.cardPurple,
            Theme.Colors.cardPink,
            Theme.Colors.cardTeal,
            Theme.Colors.safe,
            Theme.Colors.warning
        ]
        let index = abs(category.name.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            if let _ = UIImage(named: category.iconName) {
                Image(category.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(categoryColor)
                    .frame(width: 50, height: 50)
            }
            
            Text(category.name)
                .font(Theme.Fonts.title(14))
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Theme.Colors.background)
        .cornerRadius(Theme.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(Theme.Colors.neutral.opacity(0.1), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if !products.isEmpty {
                Text("\(products.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 24, minHeight: 24)
                    .background(Theme.Colors.accent)
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryDetailView: View {
    @Bindable var category: Category
    @Query private var products: [Product]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showAddProduct = false
    
    init(category: Category) {
        self.category = category
        // Filter products by category name
        let name = category.name
        _products = Query(filter: #Predicate<Product> { $0.category == name }, sort: \.expirationDate)
    }
    
    var body: some View {
        List {
            Section("Settings") {
                HStack {
                    Text("Default Shelf Life")
                    Spacer()
                    TextField("Days", value: $category.defaultExpirationDays, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("days")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Items in \(category.name)") {
                Button(action: {
                    showAddProduct = true
                    HapticsManager.shared.selection()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Add Product in this Category")
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
                
                if products.isEmpty {
                    Text("No items in this category")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            HStack {
                                Text(product.name)
                                Spacer()
                                Text(product.expirationDate.formattedString())
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            if category.isCustom {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Category")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .toolbar(.hidden, for: .tabBar)
        .alert("Delete Category", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text("Are you sure you want to delete this category? Items in this category will remain but won't be linked to it.")
        }
        .sheet(isPresented: $showAddProduct) {
            AddProductView(presetCategory: category)
        }
    }
    
    private func deleteCategory() {
        modelContext.delete(category)
        dismiss()
    }
}

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var defaultDays = 30
    @State private var selectedIcon = "baby_food"
    
    // Note: icons list is now managed inside CarouselIconPicker or can be passed if needed
    // For now we rely on CarouselIconPicker's internal list or we can pass the full list of assets.
    // The previous list was system icons, now we want the assets.
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Name", text: $name)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Icon")
                            .font(Theme.Fonts.body(14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 4)
                        
                        // Passing empty list will make CarouselIconPicker use its default asset list
                        CarouselIconPicker(selectedIcon: $selectedIcon)
                            .listRowInsets(EdgeInsets()) // Full width
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Shelf Life")
                            .font(Theme.Fonts.body(14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                        
                        // Quick selection buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                QuickDaysButton(title: "3 Days", days: 3, selectedDays: $defaultDays)
                                QuickDaysButton(title: "7 Days", days: 7, selectedDays: $defaultDays)
                                QuickDaysButton(title: "14 Days", days: 14, selectedDays: $defaultDays)
                                QuickDaysButton(title: "30 Days", days: 30, selectedDays: $defaultDays)
                                QuickDaysButton(title: "90 Days", days: 90, selectedDays: $defaultDays)
                                QuickDaysButton(title: "180 Days", days: 180, selectedDays: $defaultDays)
                                QuickDaysButton(title: "365 Days", days: 365, selectedDays: $defaultDays)
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        // Input field with +/- buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                if defaultDays > 1 {
                                    defaultDays -= 1
                                    HapticsManager.shared.selection()
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(defaultDays > 1 ? Theme.Colors.accent : Theme.Colors.neutral.opacity(0.3))
                            }
                            .disabled(defaultDays <= 1)
                            
                            TextField("Days", value: $defaultDays, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(Theme.Fonts.title(18))
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Theme.Colors.background)
                                .cornerRadius(8)
                                .onChange(of: defaultDays) { _, newValue in
                                    // Validate range
                                    if newValue < 1 {
                                        defaultDays = 1
                                    } else if newValue > 3650 {
                                        defaultDays = 3650
                                    }
                                }
                            
                            Button(action: {
                                if defaultDays < 3650 {
                                    defaultDays += 1
                                    HapticsManager.shared.selection()
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(defaultDays < 3650 ? Theme.Colors.accent : Theme.Colors.neutral.opacity(0.3))
                            }
                            .disabled(defaultDays >= 3650)
                        }
                        
                        Text("\(defaultDays) days")
                            .font(Theme.Fonts.body(12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCategory = Category(name: name, defaultExpirationDays: defaultDays, isCustom: true, iconName: selectedIcon)
                        modelContext.insert(newCategory)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct QuickDaysButton: View {
    let title: String
    let days: Int
    @Binding var selectedDays: Int
    
    private var isSelected: Bool {
        selectedDays == days
    }
    
    var body: some View {
        Button(action: {
            selectedDays = days
            HapticsManager.shared.selection()
        }) {
            Text(title)
                .font(Theme.Fonts.body(13))
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.accent : Theme.Colors.background)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    CategoriesView()
}
