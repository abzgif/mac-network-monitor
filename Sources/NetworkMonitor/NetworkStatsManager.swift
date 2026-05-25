import Foundation
import Combine
import Darwin

/// Represents statistics for a single network interface.
public struct InterfaceStats: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let rxBytes: UInt64
    public let txBytes: UInt64
    public let rxSpeed: Double
    public let txSpeed: Double
    public let isPhysical: Bool
}

/// Manages high-performance network monitoring using sysctl.
public class NetworkStatsManager: ObservableObject {
    // Published properties for UI binding (always updated on main thread)
    @Published public var downSpeed: Double = 0.0
    @Published public var upSpeed: Double = 0.0
    @Published public var sessionDownloaded: UInt64 = 0
    @Published public var sessionUploaded: UInt64 = 0
    @Published public var systemTotalDownloaded: UInt64 = 0
    @Published public var systemTotalUploaded: UInt64 = 0
    @Published public var interfaces: [InterfaceStats] = []
    
    // Background polling queue and timer
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.abuzar.mac-network-monitor.stats", qos: .background)
    
    // Thread-safe state tracking (only accessed on background queue)
    private var lastInterfaceData: [String: (rx: UInt64, tx: UInt64, time: Date)] = [:]
    private var privateSessionDownloaded: UInt64 = 0
    private var privateSessionUploaded: UInt64 = 0
    private var isFirstTick = true
    
    public init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// Starts the background monitoring timer.
    public func startMonitoring() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.timer = DispatchSource.makeTimerSource(queue: self.queue)
            self.timer?.schedule(deadline: .now(), repeating: .seconds(1))
            self.timer?.setEventHandler { [weak self] in
                self?.updateStats()
            }
            self.timer?.resume()
        }
    }
    
    /// Stops the monitoring timer.
    public func stopMonitoring() {
        queue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
        }
    }
    
    /// Queries the kernel for updated network statistics using sysctl.
    private func updateStats() {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: size_t = 0
        
        // Query required buffer size
        if sysctl(&mib, u_int(mib.count), nil, &len, nil, 0) < 0 {
            return
        }
        
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        defer { data.deallocate() }
        
        // Fetch actual interface list and metrics
        if sysctl(&mib, u_int(mib.count), data, &len, nil, 0) < 0 {
            return
        }
        
        var ptr = data
        let end = data.advanced(by: len)
        let currentTime = Date()
        
        var currentInterfaces: [InterfaceStats] = []
        var totalDownSpeed: Double = 0
        var totalUpSpeed: Double = 0
        var totalSystemRx: UInt64 = 0
        var totalSystemTx: UInt64 = 0
        
        while ptr < end {
            let ifm = ptr.withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
            
            if ifm.ifm_type == RTM_IFINFO2 {
                let if2m = ptr.withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }
                
                var nameBuffer = [CChar](repeating: 0, count: Int(IF_NAMESIZE))
                let name = if_indextoname(UInt32(if2m.ifm_index), &nameBuffer) != nil ? String(cString: nameBuffer) : "unknown"
                
                // Exclude loopback to focus on real traffic
                if name != "lo0" && name != "unknown" {
                    let rxBytes = if2m.ifm_data.ifi_ibytes
                    let txBytes = if2m.ifm_data.ifi_obytes
                    
                    // Heuristic: interfaces starting with "en" are physical ethernet/Wi-Fi
                    let isPhysical = name.hasPrefix("en")
                    
                    var rxSpeed: Double = 0.0
                    var txSpeed: Double = 0.0
                    
                    if let last = lastInterfaceData[name] {
                        let timeDelta = currentTime.timeIntervalSince(last.time)
                        if timeDelta > 0 {
                            if rxBytes >= last.rx {
                                let rxDelta = rxBytes - last.rx
                                rxSpeed = Double(rxDelta) / timeDelta
                                if isPhysical && !isFirstTick {
                                    privateSessionDownloaded += rxDelta
                                }
                            }
                            if txBytes >= last.tx {
                                let txDelta = txBytes - last.tx
                                txSpeed = Double(txDelta) / timeDelta
                                if isPhysical && !isFirstTick {
                                    privateSessionUploaded += txDelta
                                }
                            }
                        }
                    }
                    
                    // Cache the current metrics for next comparison
                    lastInterfaceData[name] = (rx: rxBytes, tx: txBytes, time: currentTime)
                    
                    if isPhysical {
                        totalDownSpeed += rxSpeed
                        totalUpSpeed += txSpeed
                        totalSystemRx += rxBytes
                        totalSystemTx += txBytes
                    }
                    
                    // Include in details if interface has seen traffic or is physical
                    if rxBytes > 0 || txBytes > 0 || isPhysical {
                        currentInterfaces.append(InterfaceStats(
                            name: name,
                            rxBytes: rxBytes,
                            txBytes: txBytes,
                            rxSpeed: rxSpeed,
                            txSpeed: txSpeed,
                            isPhysical: isPhysical
                        ))
                    }
                }
            }
            
            ptr = ptr.advanced(by: Int(ifm.ifm_msglen))
        }
        
        if isFirstTick {
            isFirstTick = false
        }
        
        // Sort: Physical interfaces first, then alphabetical by name
        currentInterfaces.sort {
            if $0.isPhysical != $1.isPhysical {
                return $0.isPhysical && !$1.isPhysical
            }
            return $0.name < $1.name
        }
        
        let sessionDownloadedCopy = privateSessionDownloaded
        let sessionUploadedCopy = privateSessionUploaded
        
        // Update published properties on main thread
        DispatchQueue.main.async {
            self.downSpeed = totalDownSpeed
            self.upSpeed = totalUpSpeed
            self.sessionDownloaded = sessionDownloadedCopy
            self.sessionUploaded = sessionUploadedCopy
            self.systemTotalDownloaded = totalSystemRx
            self.systemTotalUploaded = totalSystemTx
            self.interfaces = currentInterfaces
        }
    }
}
