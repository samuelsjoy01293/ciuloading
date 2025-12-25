import Foundation

extension Date {
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    var daysFromToday: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }
    
    var isExpired: Bool {
        return daysFromToday < 0
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: self)
    }
    
    func relativeString() -> String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if daysFromToday < 0 { return "Expired" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

