import UIKit

final class OrientationManager {
    static let shared = OrientationManager()
    private init() {}
    
    func set(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationMask = mask
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        
        rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
