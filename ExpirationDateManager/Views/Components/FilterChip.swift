import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.body(14))
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.accent : Theme.Colors.background)
                .foregroundStyle(isSelected ? Color.white : Theme.Colors.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.accent.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

#Preview {
    HStack {
        FilterChip(title: "Selected", isSelected: true, action: {})
        FilterChip(title: "Unselected", isSelected: false, action: {})
    }
    .padding()
    .background(Theme.Colors.secondaryBackground)
}

