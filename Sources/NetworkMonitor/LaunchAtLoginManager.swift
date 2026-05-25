import Foundation
import ServiceManagement

/// Manages registration of the app as a login item using SMAppService (macOS 13+).
public class LaunchAtLoginManager: ObservableObject {
    @Published public var isEnabled: Bool = false
    
    public init() {
        checkStatus()
    }
    
    /// Synchronizes the local publisher state with the actual system registration status.
    public func checkStatus() {
        let status = SMAppService.mainApp.status
        DispatchQueue.main.async {
            self.isEnabled = (status == .enabled)
        }
    }
    
    /// Toggles the login item state.
    public func toggle() {
        let service = SMAppService.mainApp
        if isEnabled {
            do {
                try service.unregister()
                DispatchQueue.main.async {
                    self.isEnabled = false
                }
            } catch {
                print("Failed to unregister login item: \(error.localizedDescription)")
                checkStatus() // Reset state on failure
            }
        } else {
            do {
                try service.register()
                DispatchQueue.main.async {
                    self.isEnabled = true
                }
            } catch {
                print("Failed to register login item: \(error.localizedDescription)")
                checkStatus() // Reset state on failure
            }
        }
    }
}
