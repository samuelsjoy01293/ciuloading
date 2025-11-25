import Foundation
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    // Show notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Count products expiring within 30 days
    private func countExpiringProducts(_ products: [Product]) -> Int {
        return products.filter { product in
            let days = product.expirationDate.daysFromToday
            return days >= 0 && days <= 30
        }.count
    }
    
    // Schedule daily notification with products array
    func scheduleDailyNotification(at hour: Int, minute: Int, products: [Product]) {
        let expiringCount = countExpiringProducts(products)
        scheduleDailyNotification(at: hour, minute: minute, expiringCount: expiringCount)
    }
    
    // Schedule daily notification with count
    private func scheduleDailyNotification(at hour: Int, minute: Int, expiringCount: Int) {
        // Cancel existing notification first
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Expiration Update"
        
        // Format message according to count
        if expiringCount == 0 {
            content.body = "All items are fresh!"
        } else if expiringCount == 1 {
            content.body = "1 item needs your attention"
        } else {
            content.body = "\(expiringCount) items need your attention"
        }
        
        content.sound = .default
        content.badge = expiringCount > 0 ? NSNumber(value: expiringCount) : nil
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Update notification with current products count
    func updateDailyNotification(products: [Product]) {
        // Check if notifications are enabled
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            return
        }
        
        // Get notification time from settings (default 9:00)
        let hour = 9
        let minute = 0
        
        scheduleDailyNotification(at: hour, minute: minute, products: products)
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

