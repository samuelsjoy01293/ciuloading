import SwiftUI

struct ProductCardView: View {
    let product: Product
    
    private var statusColor: Color {
        let days = product.expirationDate.daysFromToday
        if days <= 1 {
            return Theme.Colors.critical
        } else if days <= 7 {
            return Theme.Colors.warning
        } else if days <= 30 {
            return Theme.Colors.attention
        } else {
            return Theme.Colors.safe
        }
    }
    
    private var daysRemaining: String {
        let days = product.expirationDate.daysFromToday
        if days < 0 { return "EXPIRED" }
        if days == 0 { return "TODAY" }
        if days == 1 { return "1 DAY" }
        return "\(days) DAYS"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Status Strip
            Rectangle()
                .fill(statusColor)
                .frame(width: 6)
            
            HStack(spacing: 12) {
                // Icon/Photo
                Group {
                    if let path = product.photoPath, let uiImage = loadImageFromDisk(path: path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Try to load category icon
                        let iconName = product.category.lowercased().replacingOccurrences(of: " ", with: "_")
                        if let _ = UIImage(named: iconName) {
                            Image(iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [statusColor.opacity(0.2), statusColor.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "cube.box.fill")
                                    .foregroundStyle(statusColor.opacity(0.6))
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(Theme.Fonts.title(16))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(product.category) • \(product.storageLocation)")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(daysRemaining)
                        .font(Theme.Fonts.date(16))
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor)
                    
                    Text(product.expirationDate.formattedString())
                        .font(Theme.Fonts.body(10))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .background(
            LinearGradient(
                colors: [
                    Theme.Colors.background,
                    Theme.Colors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(statusColor.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: statusColor.opacity(0.1), radius: 4, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func loadImageFromDisk(path: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }
}

#Preview {
    ProductCardView(product: Product(name: "Milk", expirationDate: Date().addingTimeInterval(86400 * 2), category: "Dairy", storageLocation: "Fridge"))
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
}

