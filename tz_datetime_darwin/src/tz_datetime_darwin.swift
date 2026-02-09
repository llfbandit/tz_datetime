import Foundation

@objc public class TzDatetimeDarwin: NSObject {
    
    @objc public func getAvailableTimezones() -> [String] {
        var timezones: [String] = []
        for timezone in TimeZone.knownTimeZoneIdentifiers {
            timezones.append(timezone)
        }
        return timezones
    }
    
    @objc public func getOffset(_ date: Date, zoneId: String) -> TimeInterval {
        guard let timezone = TimeZone(identifier: zoneId) else {
            return 0.0 // Return 0 if timezone is invalid
        }
        
        let seconds = timezone.secondsFromGMT(for: date)
        return Double(seconds)
    }
}