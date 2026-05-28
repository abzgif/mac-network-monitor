import SwiftUI
import AppKit

/// The About View displaying app info, GitHub link, and check for updates.
struct AboutView: View {
    @State private var checkStatus: UpdateCheckStatus = .idle
    @State private var latestVersion: String? = nil
    @State private var latestUrl: String? = nil
    
    enum UpdateCheckStatus {
        case idle
        case checking
        case upToDate
        case updateAvailable(version: String, url: String)
        case error(String)
    }
    
    var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 12)
            
            // App Icon with glow and shadow
            ZStack {
                if let nsImage = NSImage(named: "AppIcon") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Modern premium SwiftUI icon representation
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.skyBlue, Color.emeraldGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "network")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 72, height: 72)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .shadow(color: Color.skyBlue.opacity(0.2), radius: 12, x: 0, y: 6)
            
            // App Name
            Text("Network Monitor")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            // Version
            Text(appVersionString)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            // GitHub Link
            Link("GitHub", destination: URL(string: "https://github.com/abzgif/mac-network-monitor")!)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.skyBlue)
            
            Divider()
                .padding(.horizontal, 24)
            
            // Check for Update / Status
            VStack(spacing: 8) {
                switch checkStatus {
                case .idle:
                    Button(action: checkForUpdates) {
                        Text("Check for Updates")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.emeraldGreen)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                case .checking:
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking for updates...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                case .upToDate:
                    VStack(spacing: 6) {
                        Text("You're up to date!")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.emeraldGreen)
                        
                        Button(action: { checkStatus = .idle }) {
                            Text("OK")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.link)
                    }
                    
                case .updateAvailable(let version, let url):
                    VStack(spacing: 6) {
                        Text("Update Available: \(version)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Link("Download Update", destination: URL(string: url)!)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(6)
                        
                        Button(action: { checkStatus = .idle }) {
                            Text("Cancel")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.link)
                    }
                    
                case .error(let errorMsg):
                    VStack(spacing: 6) {
                        Text(errorMsg)
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        
                        Button(action: { checkStatus = .idle }) {
                            Text("Try Again")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.skyBlue)
                        }
                        .buttonStyle(.link)
                    }
                }
            }
            .frame(height: 56)
            
            Spacer()
        }
        .padding(16)
        .frame(width: 260, height: 310)
        .background(
            Color(nsColor: .windowBackgroundColor)
        )
    }
    
    private func checkForUpdates() {
        checkStatus = .checking
        
        guard let url = URL(string: "https://api.github.com/repos/abzgif/mac-network-monitor/releases/latest") else {
            checkStatus = .error("Invalid update URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("mac-network-monitor-updater", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    checkStatus = .error("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    checkStatus = .error("No data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tagName = json["tag_name"] as? String,
                       let htmlUrl = json["html_url"] as? String {
                        
                        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                        let cleanTagName = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                        
                        if cleanTagName.compare(currentVersion, options: .numeric) == .orderedDescending {
                            checkStatus = .updateAvailable(version: tagName, url: htmlUrl)
                        } else {
                            checkStatus = .upToDate
                        }
                    } else {
                        checkStatus = .error("Failed to parse update info")
                    }
                } catch {
                    checkStatus = .error("Failed to check for updates")
                }
            }
        }.resume()
    }
}

/// A controller to manage the standalone About window lifecycle.
public class AboutWindowController: NSObject {
    public static let shared = AboutWindowController()
    
    private var window: NSWindow?
    
    public func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 310),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.center()
        
        self.window = window
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
