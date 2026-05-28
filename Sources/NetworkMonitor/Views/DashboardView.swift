import SwiftUI

/// The main dashboard view displayed when the user clicks the menu bar item.
public struct DashboardView: View {
    @ObservedObject var monitor: NetworkStatsManager
    @ObservedObject var launchManager: LaunchAtLoginManager
    
    @State private var startTime = Date()
    @State private var timeElapsed: TimeInterval = 0
    @State private var isHoveringQuit = false
    @State private var isInterfacesExpanded = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public init(monitor: NetworkStatsManager, launchManager: LaunchAtLoginManager) {
        self.monitor = monitor
        self.launchManager = launchManager
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Network Monitor")
                        .font(.system(size: 14, weight: .bold))
                    Text("Active Session: \(formatUptime(timeElapsed))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quit Button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 10, weight: .bold))
                        Text("Quit")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .foregroundColor(isHoveringQuit ? .white : .red)
                    .background(isHoveringQuit ? Color.red : Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .onHover { hover in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveringQuit = hover
                    }
                }
            }
            .padding(.bottom, 4)
            
            // Speeds Grid
            HStack(spacing: 12) {
                SpeedCard(
                    title: "Download",
                    speed: monitor.downSpeed,
                    totalSession: monitor.sessionDownloaded,
                    totalSystem: monitor.systemTotalDownloaded,
                    icon: "arrow.down.circle.fill",
                    color: .emeraldGreen
                )
                
                SpeedCard(
                    title: "Upload",
                    speed: monitor.upSpeed,
                    totalSession: monitor.sessionUploaded,
                    totalSystem: monitor.systemTotalUploaded,
                    icon: "arrow.up.circle.fill",
                    color: .skyBlue
                )
            }
            
            // Interfaces Disclosure Group
            VStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isInterfacesExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "network")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Network Interfaces (\(monitor.interfaces.count))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isInterfacesExpanded ? 90 : 0))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                }
                .buttonStyle(.plain)
                
                if isInterfacesExpanded {
                    VStack(spacing: 0) {
                        Divider()
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 2) {
                                ForEach(monitor.interfaces) { interface in
                                    InterfaceRow(stats: interface)
                                    if interface != monitor.interfaces.last {
                                        Divider().opacity(0.4)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                        }
                        .frame(height: 120)
                    }
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.1))
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            
            Divider()
            
            // Preferences / Auto-start Section
            HStack {
                Toggle(isOn: Binding(
                    get: { launchManager.isEnabled },
                    set: { _ in launchManager.toggle() }
                )) {
                    Text("Start Automatically at Login")
                        .font(.system(size: 11, weight: .medium))
                }
                .toggleStyle(.checkbox)
                
                Spacer()
                
                Button(action: {
                    AboutWindowController.shared.show()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("About Network Monitor")
            }
        }
        .padding(14)
        .frame(width: 320, height: isInterfacesExpanded ? 390 : 270)
        .onReceive(timer) { _ in
            timeElapsed = Date().timeIntervalSince(startTime)
        }
    }
    
    private func formatUptime(_ seconds: TimeInterval) -> String {
        let secs = Int(seconds)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let remainingSecs = secs % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, remainingSecs)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, remainingSecs)
        } else {
            return "\(remainingSecs)s"
        }
    }
}

/// A card helper component for speeds (Download/Upload).
struct SpeedCard: View {
    let title: String
    let speed: Double
    let totalSession: UInt64
    let totalSystem: UInt64
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(SpeedFormatter.formatSpeed(speed))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Session: \(SpeedFormatter.formatBytes(totalSession))")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("System: \(SpeedFormatter.formatBytes(totalSystem))")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(isHovered ? 0.6 : 0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? color.opacity(0.4) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

/// A compact row component for showing active network interface stats.
struct InterfaceRow: View {
    let stats: InterfaceStats
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName(for: stats.name))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(iconColor(for: stats.name))
                .frame(width: 14)
            
            Text(stats.name)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
            
            Spacer()
            
            // Speeds
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.emeraldGreen)
                    Text(SpeedFormatter.formatSpeed(stats.rxSpeed))
                        .font(.system(size: 9.5, design: .monospaced))
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.skyBlue)
                    Text(SpeedFormatter.formatSpeed(stats.txSpeed))
                        .font(.system(size: 9.5, design: .monospaced))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconName(for name: String) -> String {
        if name == "en0" {
            return "wifi"
        } else if name.hasPrefix("en") {
            return "cable.connector"
        } else if name.hasPrefix("utun") {
            return "lock.shield.fill"
        } else if name.hasPrefix("bridge") {
            return "point.3.connected.trianglepath.dotted"
        } else if name.hasPrefix("awdl") {
            return "wifi.shared"
        } else if name == "lo0" {
            return "link"
        } else {
            return "network"
        }
    }
    
    private func iconColor(for name: String) -> Color {
        if name == "en0" {
            return .skyBlue
        } else if name.hasPrefix("en") {
            return .primary
        } else if name.hasPrefix("utun") {
            return .orange
        } else if name.hasPrefix("bridge") {
            return .purple
        } else {
            return .secondary
        }
    }
}
