import Foundation

/// A utility to format byte counts and transfer rates into human-readable strings.
public struct SpeedFormatter {
    
    /// Formats network speed in bytes per second to a human-readable string.
    /// - Parameter bytesPerSecond: The speed in bytes per second.
    /// - Returns: A formatted string, e.g., "1.2 MB/s", "400 KB/s", "0 B/s".
    public static func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024.0)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB/s", bytesPerSecond / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    /// Formats a total byte count to a human-readable string.
    /// - Parameter bytes: The total number of bytes.
    /// - Returns: A formatted string, e.g., "1.20 GB", "450.5 MB".
    public static func formatBytes(_ bytes: UInt64) -> String {
        let doubleBytes = Double(bytes)
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", doubleBytes / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", doubleBytes / (1024.0 * 1024.0))
        } else if bytes < 1024 * 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", doubleBytes / (1024.0 * 1024.0 * 1024.0))
        } else {
            return String(format: "%.2f TB", doubleBytes / (1024.0 * 1024.0 * 1024.0 * 1024.0))
        }
    }
}
