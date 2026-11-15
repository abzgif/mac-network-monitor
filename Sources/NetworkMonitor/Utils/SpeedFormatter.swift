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
    
    /// Formats network speed into a compact string for the two-line menu bar item.
    /// Uses KB/s as the base unit with whole numbers to prevent rapid text-length jitter.
    /// - Parameter bytesPerSecond: The speed in bytes per second.
    /// - Returns: A compact string, e.g., "2 KB/s", "1.2 MB/s".
    public static func formatMenuBarSpeed(_ bytesPerSecond: Double) -> String {
        let kb = bytesPerSecond / 1024.0
        if kb < 999.5 {
            return String(format: "%.0f KB/s", max(0, kb))
        }
        let mb = kb / 1024.0
        if mb < 100.0 {
            return String(format: "%.1f MB/s", mb)
        } else if mb < 999.5 {
            return String(format: "%.0f MB/s", mb)
        } else {
            let gb = mb / 1024.0
            return String(format: "%.1f GB/s", gb)
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
