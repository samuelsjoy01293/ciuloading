import SwiftUI

struct CarouselIconPicker: View {
    @Binding var selectedIcon: String
    
    // List of available image assets
    let icons: [String] = [
        "baby_food", "bakery", "batteries", "beverages", 
        "canned_food", "cleaning_supplies", "cosmetics", "dairy",
        "fish", "frozen_food", "fruits", "grains",
        "household", "meat", "medicines", "oils",
        "pet_food", "sauces", "snacks", "spices",
        "sweets", "vegetables"
    ]
    
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollWorkItem: DispatchWorkItem?
    
    var body: some View {
        GeometryReader { geometry in
            let itemWidth: CGFloat = 80
            let spacing: CGFloat = 20
            let sidePadding = (geometry.size.width - itemWidth) / 2
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(Array(icons.enumerated()), id: \.element) { index, icon in
                            GeometryReader { itemGeo in
                                let frame = itemGeo.frame(in: .named("scrollContainer"))
                                let midX = frame.midX
                                let containerCenter = geometry.size.width / 2
                                let distance = abs(midX - containerCenter)
                                let scale = max(0.6, 1 - (distance / (geometry.size.width * 0.6)))
                                
                                ZStack {
                                    Image(icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    if selectedIcon == icon {
                                        Circle()
                                            .stroke(Theme.Colors.accent, lineWidth: 3)
                                            .frame(width: 90, height: 90)
                                    }
                                }
                                .scaleEffect(scale)
                                .opacity(scale)
                                .position(x: itemWidth / 2, y: itemGeo.size.height / 2)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        proxy.scrollTo(icon, anchor: .center)
                                        selectedIcon = icon
                                    }
                                    HapticsManager.shared.selection()
                                }
                            }
                            .frame(width: itemWidth, height: 120)
                            .id(icon)
                        }
                    }
                    .padding(.horizontal, sidePadding)
                    .background(
                        GeometryReader { scrollGeo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeo.frame(in: .named("scrollContainer")).minX
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scrollContainer")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    handleScrollChange(proxy: proxy, geometry: geometry, itemWidth: itemWidth, spacing: spacing, sidePadding: sidePadding)
                }
                .onAppear {
                    // Initial scroll to selected icon
                    if !selectedIcon.isEmpty && icons.contains(selectedIcon) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(selectedIcon, anchor: .center)
                            }
                        }
                    } else if !icons.isEmpty {
                        // Default to first icon if selectedIcon is not in list
                        selectedIcon = icons[0]
                    }
                }
            }
        }
        .frame(height: 140)
    }
    
    private func handleScrollChange(proxy: ScrollViewProxy, geometry: GeometryProxy, itemWidth: CGFloat, spacing: CGFloat, sidePadding: CGFloat) {
        // Cancel previous work item
        scrollWorkItem?.cancel()
        
        // Check if scroll position changed significantly
        let offsetDiff = abs(scrollOffset - lastScrollOffset)
        if offsetDiff > 0.5 {
            lastScrollOffset = scrollOffset
            
            // Create a new work item to detect when scrolling stops
            let workItem = DispatchWorkItem {
                self.snapToNearestItem(proxy: proxy, geometry: geometry, itemWidth: itemWidth, spacing: spacing, sidePadding: sidePadding)
            }
            scrollWorkItem = workItem
            
            // Schedule the work item with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        }
    }
    
    private func snapToNearestItem(proxy: ScrollViewProxy, geometry: GeometryProxy, itemWidth: CGFloat, spacing: CGFloat, sidePadding: CGFloat) {
        let containerCenter = geometry.size.width / 2
        let totalItemWidth = itemWidth + spacing
        
        // Calculate which item is closest to center
        // scrollOffset is negative when scrolled right, positive when scrolled left
        // We need to find which item's center is closest to the screen center
        var closestIcon: String?
        var minDistance: CGFloat = .infinity
        
        for (index, icon) in icons.enumerated() {
            // Position of item center in the scroll view's coordinate space
            let itemCenterX = sidePadding + CGFloat(index) * totalItemWidth + itemWidth / 2
            
            // Position relative to the visible area (accounting for scroll offset)
            // scrollOffset is the minX of the scroll content, so we subtract it
            let itemVisibleX = itemCenterX + scrollOffset
            
            // Distance from screen center
            let distance = abs(itemVisibleX - containerCenter)
            
            if distance < minDistance {
                minDistance = distance
                closestIcon = icon
            }
        }
        
        // Snap to the closest item with smooth animation
        if let closestIcon = closestIcon, closestIcon != selectedIcon {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                proxy.scrollTo(closestIcon, anchor: .center)
                selectedIcon = closestIcon
                HapticsManager.shared.selection()
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    CarouselIconPicker(selectedIcon: .constant("dairy"))
        .background(Color.gray.opacity(0.1))
}
