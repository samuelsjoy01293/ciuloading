import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var products: [Product]
    @State private var selectedDate: Date = Date()
    @State private var showDayDetails = false
    @Environment(\.colorScheme) var colorScheme
    
    // Calendar navigation state
    @State private var currentMonth: Date = Date()
    
    private var productsByDate: [Date: [Product]] {
        Dictionary(grouping: products) { product in
            Calendar.current.startOfDay(for: product.expirationDate)
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        var dates: [Date] = []
        var currentDate = monthStart
        
        // Add padding days for grid alignment (if needed, can be handled by LazyVGrid)
        // Simple iteration:
        while currentDate < monthEnd {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Month Navigation
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .padding(12)
                            .background(Theme.Colors.adaptiveWhite(for: colorScheme))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(currentMonth.formattedString(format: "MMMM yyyy"))
                        .font(Theme.Fonts.header(20))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .padding(12)
                            .background(Theme.Colors.adaptiveWhite(for: colorScheme))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Days Header
                HStack {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Calendar Grid
                let columns = Array(repeating: GridItem(.flexible()), count: 7)
                LazyVGrid(columns: columns, spacing: 8) {
                    // Offset for first day of month
                    let firstDayWeekday = Calendar.current.component(.weekday, from: daysInMonth.first ?? Date())
                    ForEach(0..<(firstDayWeekday - 1), id: \.self) { _ in
                        Color.clear
                    }
                    
                    ForEach(daysInMonth, id: \.self) { date in
                        let dayProducts = productsByDate[Calendar.current.startOfDay(for: date)] ?? []
                        CalendarDayCell(date: date, products: dayProducts, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                selectedDate = date
                                if !dayProducts.isEmpty {
                                    showDayDetails = true
                                }
                                HapticsManager.shared.selection()
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.Colors.secondaryBackground.ignoresSafeArea())
            .navigationTitle("Calendar")
            .sheet(isPresented: $showDayDetails) {
                DayDetailSheet(date: selectedDate, products: productsByDate[Calendar.current.startOfDay(for: selectedDate)] ?? [])
                    .presentationDetents([.medium, .large])
            }
        }
        .background(Theme.Colors.secondaryBackground.ignoresSafeArea())
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let products: [Product]
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var statusColor: Color? {
        if products.isEmpty { return nil }
        // Check if any expired
        if products.contains(where: { $0.expirationDate.isExpired }) { return Theme.Colors.critical }
        // Any today/tomorrow
        if products.contains(where: { $0.expirationDate.isToday || $0.expirationDate.isTomorrow }) { return Theme.Colors.critical }
        // Any soon
        return Theme.Colors.warning
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(Theme.Fonts.body(16))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(isSelected ? Theme.Colors.accent : Theme.Colors.adaptiveWhite(for: colorScheme))
                .clipShape(Circle())
            
            if let color = statusColor {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .shadow(color: color.opacity(0.5), radius: 2)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct ProductWrapper: Identifiable {
    let id: UUID
    let product: Product
    
    init(product: Product) {
        self.id = product.id
        self.product = product
    }
}

struct DayDetailSheet: View {
    let date: Date
    let products: [Product]
    @State private var selectedProductWrapper: ProductWrapper?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(products) { product in
                    Button(action: {
                        selectedProductWrapper = ProductWrapper(product: product)
                    }) {
                        HStack {
                            // Status indicator
                            Circle()
                                .fill(product.expirationDate.isExpired ? Theme.Colors.critical : Theme.Colors.warning)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(product.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(product.quantity)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(date.formattedString())
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedProductWrapper) { wrapper in
                ProductDetailView(product: wrapper.product)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

extension Date {
    func formattedString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

#Preview {
    CalendarView()
}

