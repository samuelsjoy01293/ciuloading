import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var product: Product
    @Query private var categories: [Category]
    
    @State private var showEditSheet = false
    @State private var showShareSheet = false
    @State private var showExtendPicker = false
    @State private var customExtendDate = Date()
    @State private var showCustomExtendSheet = false
    @State private var showDeleteConfirmation = false
    
    // Calculate days and progress
    private var daysRemaining: Int {
        product.expirationDate.daysFromToday
    }
    
    private var totalDays: Int {
        Calendar.current.dateComponents([.day], from: product.createdAt, to: product.expirationDate).day ?? 1
    }
    
    private var progress: Double {
        let passed = Calendar.current.dateComponents([.day], from: product.createdAt, to: Date()).day ?? 0
        return min(max(Double(passed) / Double(totalDays), 0.0), 1.0)
    }
    
    private var statusColor: Color {
        if product.expirationDate.isExpired || product.expirationDate.isToday { return Theme.Colors.critical }
        if daysRemaining <= 7 { return Theme.Colors.warning }
        if daysRemaining <= 30 { return Theme.Colors.attention }
        return Theme.Colors.safe
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image
                if let path = product.photoPath, let uiImage = loadImageFromDisk(path: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                } else {
                    // Category Icon Header
                    let iconName = product.category.lowercased().replacingOccurrences(of: " ", with: "_")
                    ZStack(alignment: .bottom) {
                        Color.clear
                            .frame(height: 250)
                        
                        if let _ = UIImage(named: iconName) {
                            Image(iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 140)
                                .padding(.bottom, 10)
                        } else {
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Theme.Colors.accent.opacity(0.2))
                                .padding(.bottom, 40)
                        }
                    }
                }
                
                VStack(spacing: 24) {
                    // Title & Info
                    VStack(spacing: 8) {
                        Text(product.name)
                            .font(Theme.Fonts.header(32))
                            .multilineTextAlignment(.center)
                        
                        Text("\(product.category) • \(product.storageLocation)")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Circular Countdown
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.background, lineWidth: 20)
                        
                        Circle()
                            .trim(from: 0, to: 1 - progress) // Remaining
                            .stroke(statusColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: progress)
                        
                        VStack {
                            Text(daysRemaining < 0 ? "EXPIRED" : "\(daysRemaining)")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundStyle(statusColor)
                            
                            if daysRemaining >= 0 {
                                Text("Days Left")
                                    .font(Theme.Fonts.body())
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding(.vertical)
                    
                    Text("Expires: \(product.expirationDate.formattedString())")
                        .font(Theme.Fonts.date(18))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    
                    // Actions Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ActionButton(icon: "trash", title: "Used / Throw", color: .red) {
                            showDeleteConfirmation = true
                        }
                        
                        // Extend Menu
                        Menu {
                            Button("+3 Days") { extendProduct(days: 3) }
                            Button("+7 Days") { extendProduct(days: 7) }
                            Button("+30 Days") { extendProduct(days: 30) }
                            Button("Custom Date...") { showCustomExtendSheet = true }
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 24))
                                Text("Extend")
                                    .font(Theme.Fonts.body(14))
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                            .background(Theme.Colors.background)
                            .foregroundStyle(Theme.Colors.accent)
                            .cornerRadius(Theme.Layout.cornerRadius)
                        }
                        
                        ActionButton(icon: "pencil", title: "Edit", color: Theme.Colors.textPrimary) {
                            showEditSheet = true
                        }
                        
                        ActionButton(icon: "square.and.arrow.up", title: "Share", color: Theme.Colors.textPrimary) {
                            showShareSheet = true
                        }
                    }
                    .padding(.horizontal)
                    
                    if !product.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(Theme.Fonts.title(18))
                            Text(product.notes)
                                .font(Theme.Fonts.body())
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Theme.Colors.background)
                                .cornerRadius(Theme.Layout.cornerRadius)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Theme.Colors.secondaryBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Theme.Colors.background)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.leading, 16)
            .padding(.top, 10)
        }
        .sheet(isPresented: $showEditSheet) {
            EditProductView(product: product)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: getShareItems())
        }
        .sheet(isPresented: $showCustomExtendSheet) {
            NavigationView {
                VStack {
                    DatePicker("New Expiration Date", selection: $customExtendDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                    Spacer()
                }
                .padding(.bottom, 160)
                .navigationTitle("Extend Expiration")
                .toolbar {
                    Button("Save") {
                        product.expirationDate = customExtendDate
                        HapticsManager.shared.notification(type: .success)
                        showCustomExtendSheet = false
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            customExtendDate = product.expirationDate
        }
        .alert("Delete Product", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProduct()
            }
        } message: {
            Text("Are you sure you want to delete this product? This action cannot be undone.")
        }
    }
    
    private func deleteProduct() {
        modelContext.delete(product)
        HapticsManager.shared.notification(type: .success)
        dismiss()
    }
    
    private func extendProduct(days: Int) {
        product.expirationDate = Calendar.current.date(byAdding: .day, value: days, to: product.expirationDate) ?? product.expirationDate
        HapticsManager.shared.notification(type: .success)
    }
    
    private func loadImageFromDisk(path: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }
    
    private func getShareImage() -> UIImage? {
        // Try to load product photo first
        if let path = product.photoPath, let photo = loadImageFromDisk(path: path) {
            return photo
        }
        
        // If no photo, use category icon
        // Find category by name
        let category = categories.first { $0.name == product.category }
        let iconName = category?.iconName ?? product.category.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Try to load PNG asset
        if let categoryImage = UIImage(named: iconName) {
            return categoryImage
        }
        
        // Try system icon if iconName is a system icon name
        let config = UIImage.SymbolConfiguration(pointSize: 512, weight: .regular, scale: .large)
        if let systemIcon = UIImage(systemName: iconName, withConfiguration: config) {
            // Render with white background for better sharing
            return renderIconWithBackground(systemIcon)
        }
        
        // Fallback: create image from default system icon
        if let defaultIcon = UIImage(systemName: "cube.box.fill", withConfiguration: config) {
            return renderIconWithBackground(defaultIcon)
        }
        
        return nil
    }
    
    private func renderIconWithBackground(_ icon: UIImage) -> UIImage? {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // Accent color: green (0.0, 0.7, 0.3)
        let accentColor = UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0)
        
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw icon in center with accent color
            let iconSize = CGSize(width: 400, height: 400)
            let iconRect = CGRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
            
            // Create tinted version of icon with accent color
            let tintedIcon = icon.withTintColor(accentColor, renderingMode: .alwaysOriginal)
            tintedIcon.draw(in: iconRect, blendMode: .normal, alpha: 1.0)
        }
    }
    
    private func getShareItems() -> [Any] {
        var items: [Any] = []
        
        // Add text
        let text = "\(product.name) expires on \(product.expirationDate.formattedString())"
        items.append(text)
        
        // Add image if available
        if let image = getShareImage() {
            items.append(image)
        }
        
        return items
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.impact(style: .medium)
            action()
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(Theme.Fonts.body(14))
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110) // Fixed height for uniformity
            .background(Theme.Colors.background)
            .foregroundStyle(color)
            .cornerRadius(Theme.Layout.cornerRadius)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EditProductView: View {
    @Bindable var product: Product
    @Environment(\.dismiss) var dismiss
    
    @State private var quantityValue: String = ""
    @State private var quantityUnit: String = "pcs"
    @State private var storageLocation: String = ""
    
    let locations = ["Pantry", "Fridge", "Freezer", "Medicine Cabinet", "Bathroom", "Basement", "Garage"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name", text: $product.name)
                    DatePicker("Expires", selection: $product.expirationDate, displayedComponents: .date)
                }
                
                Section("Quantity") {
                    HStack {
                        TextField("Value", text: $quantityValue)
                            .keyboardType(.decimalPad)
                        
                        Picker(selection: $quantityUnit) {
                            Text("pcs").tag("pcs")
                            Text("g").tag("g")
                            Text("kg").tag("kg")
                            Text("ml").tag("ml")
                            Text("L").tag("L")
                            Text("packs").tag("packs")
                            Text("boxes").tag("boxes")
                            Text("bottles").tag("bottles")
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }
                
                Section("Location") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(locations, id: \.self) { loc in
                                FilterChip(title: loc, isSelected: storageLocation == loc) {
                                    storageLocation = loc
                                    HapticsManager.shared.selection()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    
                    TextField("Or custom location", text: $storageLocation)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $product.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Product")
            .toolbar {
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
            }
            .onAppear {
                parseQuantity()
                storageLocation = product.storageLocation
            }
        }
    }
    
    private func parseQuantity() {
        let parts = product.quantity.split(separator: " ")
        if let first = parts.first {
            quantityValue = String(first)
        }
        if parts.count > 1 {
            quantityUnit = String(parts[1])
        }
    }
    
    private func saveChanges() {
        product.quantity = "\(quantityValue) \(quantityUnit)"
        product.storageLocation = storageLocation
    }
}
