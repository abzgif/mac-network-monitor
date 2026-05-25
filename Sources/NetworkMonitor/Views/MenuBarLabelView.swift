import SwiftUI

/// A compact view to display download and upload speeds in the macOS menu bar.
public struct MenuBarLabelView: View {
    @ObservedObject var monitor: NetworkStatsManager
    
    public init(monitor: NetworkStatsManager) {
        self.monitor = monitor
    }
    
    public var body: some View {
        (Text("↓").font(.system(size: 9.5, weight: .bold)).foregroundColor(.emeraldGreen) +
         Text(" \(SpeedFormatter.formatSpeed(monitor.downSpeed))   ") +
         Text("↑").font(.system(size: 9.5, weight: .bold)).foregroundColor(.skyBlue) +
         Text(" \(SpeedFormatter.formatSpeed(monitor.upSpeed))"))
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
    }
}

// Custom semantic color extensions for standard SwiftUI Colors to provide premium visuals.
extension Color {
    static let emeraldGreen = Color(nsColor: .init(red: 0.10, green: 0.74, blue: 0.61, alpha: 1.0))
    static let skyBlue = Color(nsColor: .init(red: 0.20, green: 0.60, blue: 0.86, alpha: 1.0))
}
