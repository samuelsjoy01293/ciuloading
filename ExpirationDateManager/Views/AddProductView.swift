import SwiftUI
import SwiftData

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @Query(sort: \Product.createdAt, order: .reverse) private var allProducts: [Product] // For autocomplete history
    
    let presetCategory: Category?
    
    @State private var name: String = ""
    @State private var expirationDate: Date = Date().addingTimeInterval(86400 * 365) // +1 year default
    @State private var selectedCategory: Category?
    
    init(presetCategory: Category? = nil) {
        self.presetCategory = presetCategory
    }
    @State private var storageLocation: String = "Pantry"
    @State private var quantity: String = "1"
    @State private var quantityUnit: String = "pcs" // pcs, g, kg, packs, etc.
    @State private var notes: String = ""
    @State private var inputImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var showCategoryPicker = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Autocomplete logic
    private var uniqueNames: [String] {
        let names = allProducts.map { $0.name }
        return Array(Set(names)).filter { !name.isEmpty && $0.localizedCaseInsensitiveContains(name) && $0 != name }.sorted().prefix(3).map { String($0) }
    }
    
    let locations = ["Pantry", "Fridge", "Freezer", "Medicine Cabinet", "Bathroom", "Basement", "Garage"]
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                Section {
                    VStack(alignment: .leading) {
                        TextField("Product Name", text: $name)
                            .font(Theme.Fonts.header(24))
                            .submitLabel(.next)
                        
                        // Autocomplete suggestions
                        if !uniqueNames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(uniqueNames, id: \.self) { suggestion in
                                        Button(action: {
                                            name = suggestion
                                            HapticsManager.shared.selection()
                                        }) {
                                            Text(suggestion)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Theme.Colors.secondaryBackground)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Expiration Date") {
                    DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: expirationDate) { _, _ in
                            HapticsManager.shared.selection()
                        }
                }
                
                Section("Details") {
                    // Category Picker Button
                    Button(action: {
                        showCategoryPicker = true
                        HapticsManager.shared.selection()
                    }) {
                        HStack {
                            Text("Category")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            if let category = selectedCategory {
                                HStack(spacing: 8) {
                                    if let _ = UIImage(named: category.iconName) {
                                        Image(category.iconName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: category.iconName)
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                    Text(category.name)
                                        .foregroundStyle(Theme.Colors.accent)
                                }
                            } else {
                                Text("Select")
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .font(.caption)
                        }
                    }
                    
                    // Location Picker
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
                    
                    // Quantity with Unit
                    HStack {
                        TextField("Quantity", text: $quantity)
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
                
                Section("Optional") {
                    // Photo Preview
                    if let image = inputImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(Theme.Fonts.title(14))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                                .overlay(alignment: .topTrailing) {
                                    Button(action: {
                                        inputImage = nil
                                        HapticsManager.shared.selection()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                            .padding(8)
                                    }
                                }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Menu {
                        Button(action: {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            } else {
                                toastMessage = "Camera is not available"
                                showToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showToast = false
                                    }
                                }
                            }
                        }) {
                            Label("Camera", systemImage: "camera")
                        }
                        
                        Button(action: {
                            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                                showImagePicker = true
                            }
                        }) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        HStack {
                            Text(inputImage == nil ? "Add Photo" : "Change Photo")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            if inputImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.safe)
                            } else {
                                Image(systemName: "camera")
                                    .foregroundColor(Theme.Colors.accent)
                            }
                        }
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProduct()
                    }
                    .disabled(name.isEmpty || selectedCategory == nil)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    ImagePicker(image: $inputImage, sourceType: .photoLibrary)
                }
            }
            .sheet(isPresented: $showCamera) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    ImagePicker(image: $inputImage, sourceType: .camera)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory, expirationDate: $expirationDate)
            }
            .onAppear {
                // Set preset category if provided
                if let preset = presetCategory {
                    selectedCategory = preset
                    // Set default expiration date based on category's default shelf life
                    expirationDate = Date().addingTimeInterval(TimeInterval(preset.defaultExpirationDays * 86400))
                }
            }
        }
        
        // Toast notification
        if showToast {
            VStack {
                Spacer()
                Text(toastMessage)
                    .font(Theme.Fonts.body(14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showToast)
        }
    }
    }
    
    private func saveProduct() {
        guard let category = selectedCategory else { return }
        
        var photoPath: String? = nil
        if let image = inputImage {
            photoPath = saveImageToDisk(image)
        }
        
        // Combine quantity and unit
        let fullQuantity = quantityUnit.isEmpty ? quantity : "\(quantity) \(quantityUnit)"
        
        let newProduct = Product(
            name: name,
            expirationDate: expirationDate,
            category: category.name,
            storageLocation: storageLocation,
            quantity: fullQuantity,
            photoPath: photoPath,
            notes: notes
        )
        
        modelContext.insert(newProduct)
        HapticsManager.shared.notification(type: .success)
        dismiss()
    }
    
    private func saveImageToDisk(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

#Preview {
    AddProductView()
}

