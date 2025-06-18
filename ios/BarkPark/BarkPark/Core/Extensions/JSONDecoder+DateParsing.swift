import Foundation

extension JSONDecoder {
    static let barkParkDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        // Create a custom date formatter that handles PostgreSQL timestamps
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try different formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",    // 2025-06-18T05:10:42.093Z
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",   // 2025-06-18T05:10:42.093Z (literal Z)
                "yyyy-MM-dd'T'HH:mm:ssZ",         // 2025-06-18T05:10:42Z
                "yyyy-MM-dd'T'HH:mm:ss'Z'",       // 2025-06-18T05:10:42Z (literal Z)
                "yyyy-MM-dd'T'HH:mm:ss"           // 2025-06-18T05:10:42
            ]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // If none of the formats work, try ISO8601
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string '\(dateString)'"
            )
        }
        
        return decoder
    }()
}