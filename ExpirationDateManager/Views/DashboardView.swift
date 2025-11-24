import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Product.expirationDate, order: .forward) private var products: [Product]
    @State private var showAddSheet = false
    @State private var showSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    // Filtered computed properties
    private var criticalItems: [Product] {
        products.filter { 
            let days = $0.expirationDate.daysFromToday
            // Critical: Expired (days < 0) OR Today (days == 0) OR Tomorrow (days == 1)
            return days <= 1
        }
    }
    
    private var warningItems: [Product] {
        products.filter { 
            let days = $0.expirationDate.daysFromToday
            return days > 1 && days <= 7 
        }
    }
    
    private var attentionItems: [Product] {
        products.filter {
            let days = $0.expirationDate.daysFromToday
            return days > 7 && days <= 30
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(greeting)
                                .font(Theme.Fonts.body(16))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            
                            let count = criticalItems.count + warningItems.count
                            if count > 0 {
                                Text("\(count) items need attention")
                                    .font(Theme.Fonts.header(28))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            } else {
                                Text("All clear today")
                                    .font(Theme.Fonts.header(28))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        if products.isEmpty {
                            EmptyStateView()
                        } else {
                            // Sections
                            // Critical (Expired / Today / Tomorrow) - Red
                            if !criticalItems.isEmpty {
                                SectionView(title: "Expiring Soon", color: Theme.Colors.critical, items: criticalItems)
                            }
                            
                            // Warning (2-7 days) - Orange
                            if !warningItems.isEmpty {
                                SectionView(title: "Check Up", color: Theme.Colors.warning, items: warningItems)
                            }
                            
                            // Attention (8-30 days) - Yellow
                            if !attentionItems.isEmpty {
                                SectionView(title: "Attention", color: Theme.Colors.attention, items: attentionItems)
                            }
                            
                            if criticalItems.isEmpty && warningItems.isEmpty && attentionItems.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Theme.Colors.safe)
                                    Text("No items expiring soon!")
                                        .font(Theme.Fonts.title())
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            }
                        }
                    }
                    .padding(.bottom, 100) // Space for FAB
                }
                .background(Theme.Colors.secondaryBackground.ignoresSafeArea())
                
                // Custom Floating Action Button with Text
                Button(action: {
                    HapticsManager.shared.selection()
                    showAddSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                        Text("Add Product")
                            .font(Theme.Fonts.body(16).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showSettings = true
                        HapticsManager.shared.selection()
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddProductView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.large])
            }
            .animation(.easeInOut(duration: 0.3), value: showSettings)
            .onAppear {
                // Update notification when view appears
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    NotificationService.shared.updateDailyNotification(products: products)
                }
            }
            .onChange(of: products.count) { _, _ in
                // Update notification when products change
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    NotificationService.shared.updateDailyNotification(products: products)
                }
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let color: Color
    let items: [Product]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.title(18))
                    .foregroundStyle(color)
                Spacer()
                Text("\(items.count)")
                    .font(Theme.Fonts.body(14))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.background)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            ForEach(items) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    ProductCardView(product: product)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "basket")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.neutral)
            Text("Your pantry is empty")
                .font(Theme.Fonts.title())
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Start tracking expiration dates by adding your first item.")
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(height: 400)
    }
}

#Preview {
    DashboardView()
}
