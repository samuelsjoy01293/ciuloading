import SwiftUI
import SwiftData

struct ProductListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.expirationDate, order: .forward) private var products: [Product]
    @Query(sort: \Category.name, order: .forward) private var categories: [Category]
    
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var selectedCategories: Set<String> = []
    @State private var showAddSheet = false
    @State private var productToDelete: Product?
    @State private var showDeleteConfirmation = false
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case expired = "Expired"
        case valid = "Valid"
        case checkUp = "Check Up"
    }
    
    var filteredProducts: [Product] {
        var result = products
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected categories
        if !selectedCategories.isEmpty {
            result = result.filter { selectedCategories.contains($0.category) }
        }
        
        // Filter by status
        switch selectedFilter {
        case .all:
            return result
        case .expired:
            return result.filter { $0.expirationDate.isExpired }
        case .valid:
            // All cards except red (not expired and not <= 1 day)
            return result.filter {
                let days = $0.expirationDate.daysFromToday
                return days > 1
            }
        case .checkUp:
            // Orange cards (2-7 days)
            return result.filter {
                let days = $0.expirationDate.daysFromToday
                return days > 1 && days <= 7
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header - Always visible
                HStack {
                    Text("All Items")
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
                    
                    TextField("Search items", text: $searchText)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                }
                .background(Theme.Colors.background)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Theme.Colors.secondaryBackground)
                
                // Custom Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                selectedFilter = filter
                                HapticsManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Theme.Colors.secondaryBackground)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Clear all categories button
                        ClearCategoryFilterChip(isSelected: selectedCategories.isEmpty) {
                            selectedCategories.removeAll()
                            HapticsManager.shared.selection()
                        }
                        
                        ForEach(categories, id: \.name) { category in
                            CategoryFilterChip(category: category, isSelected: selectedCategories.contains(category.name)) {
                                if selectedCategories.contains(category.name) {
                                    selectedCategories.remove(category.name)
                                } else {
                                    selectedCategories.insert(category.name)
                                }
                                HapticsManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Theme.Colors.secondaryBackground)
                
                // List
                if filteredProducts.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.Colors.neutral)
                            .padding()
                        Text("No items found")
                            .font(Theme.Fonts.title())
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Colors.secondaryBackground)
                } else {
                    List {
                        ForEach(filteredProducts) { product in
                            ZStack {
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                ProductCardView(product: product)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    productToDelete = product
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    productToDelete = product
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Used", systemImage: "checkmark.circle")
                                }
                                .tint(Theme.Colors.safe)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.secondaryBackground)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(Theme.Colors.secondaryBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddProductView()
            }
            .alert("Delete Product", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    productToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let product = productToDelete {
                        deleteProduct(product)
                        productToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this product? This action cannot be undone.")
            }
        }
    }
    
    private func deleteProduct(_ product: Product) {
        withAnimation {
            modelContext.delete(product)
            HapticsManager.shared.notification(type: .success)
        }
    }
}

struct ClearCategoryFilterChip: View {
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // White circle background (dark gray in dark mode)
                Circle()
                    .fill(Theme.Colors.adaptiveWhite(for: colorScheme))
                    .frame(width: 50, height: 50)
                
                // Red stop/no icon
                Image(systemName: "nosign")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.critical)
                    .frame(width: 34, height: 34)
            }
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct CategoryFilterChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // White circle background (dark gray in dark mode)
                Circle()
                    .fill(Theme.Colors.adaptiveWhite(for: colorScheme))
                    .frame(width: 50, height: 50)
                
                // Category icon (reduced by 15%: 40 * 0.85 = 34)
                if let _ = UIImage(named: category.iconName) {
                    Image(category.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 34, height: 34)
                }
            }
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    ProductListView()
}
