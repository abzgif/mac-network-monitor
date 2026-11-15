import SwiftUI
import AppKit

/// A compact two-line view to display upload and download speeds in the macOS menu bar
/// with a fixed width so the status item never shifts horizontally.
public struct MenuBarLabelView: View {
    @ObservedObject var monitor: NetworkStatsManager
    
    public init(monitor: NetworkStatsManager) {
        self.monitor = monitor
    }
    
    public var body: some View {
        Image(nsImage: Self.renderMenuBarImage(
            upSpeed: SpeedFormatter.formatMenuBarSpeed(monitor.upSpeed),
            downSpeed: SpeedFormatter.formatMenuBarSpeed(monitor.downSpeed)
        ))
    }
    
    /// Renders a fixed-width two-line template NSImage for the macOS status bar:
    /// Top line:    ↑ 2 KB/s
    /// Bottom line: ↓ 1 KB/s
    public static func renderMenuBarImage(upSpeed: String, downSpeed: String) -> NSImage {
        let size = NSSize(width: 56, height: 22)
        let image = NSImage(size: size, flipped: false) { _ in
            let arrowFont = NSFont.systemFont(ofSize: 8.5, weight: .regular)
            let textFont = NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .semibold)
            
            let arrowAttributes: [NSAttributedString.Key: Any] = [
                .font: arrowFont,
                .foregroundColor: NSColor.black
            ]
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: NSColor.black
            ]
            
            let arrowX: CGFloat = 2.0
            let textX: CGFloat = 11.5
            let topY: CGFloat = 10.5
            let bottomY: CGFloat = 1.0
            
            // Top row: Upload (↑)
            ("↑" as NSString).draw(at: NSPoint(x: arrowX, y: topY), withAttributes: arrowAttributes)
            (upSpeed as NSString).draw(at: NSPoint(x: textX, y: topY), withAttributes: textAttributes)
            
            // Bottom row: Download (↓)
            ("↓" as NSString).draw(at: NSPoint(x: arrowX, y: bottomY), withAttributes: arrowAttributes)
            (downSpeed as NSString).draw(at: NSPoint(x: textX, y: bottomY), withAttributes: textAttributes)
            
            return true
        }
        image.isTemplate = true
        return image
    }
}

// Custom semantic color extensions for standard SwiftUI Colors to provide premium visuals.
extension Color {
    static let emeraldGreen = Color(nsColor: .init(red: 0.10, green: 0.74, blue: 0.61, alpha: 1.0))
    static let skyBlue = Color(nsColor: .init(red: 0.20, green: 0.60, blue: 0.86, alpha: 1.0))
}
