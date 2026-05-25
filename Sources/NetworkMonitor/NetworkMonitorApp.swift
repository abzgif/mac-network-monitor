import SwiftUI

@main
struct NetworkMonitorApp: App {
    // Instantiate our state managers. Because they are StateObjects, they will persist for the app's lifetime.
    @StateObject private var monitor = NetworkStatsManager()
    @StateObject private var launchManager = LaunchAtLoginManager()
    
    var body: some Scene {
        // MenuBarExtra defines our status bar item on macOS 13+.
        MenuBarExtra {
            DashboardView(monitor: monitor, launchManager: launchManager)
        } label: {
            MenuBarLabelView(monitor: monitor)
        }
        .menuBarExtraStyle(.window) // Renders the dashboard as a premium interactive popover window
    }
}
