import Foundation
import SwiftData

@Model
final class AppSettings {
    var warningDays: Int
    var notificationsEnabled: Bool
    var theme: String // "System", "Light", "Dark"
    var isFirstLaunch: Bool
    
    init(warningDays: Int = 7, notificationsEnabled: Bool = true, theme: String = "System") {
        self.warningDays = warningDays
        self.notificationsEnabled = notificationsEnabled
        self.theme = theme
        self.isFirstLaunch = true
    }
}

