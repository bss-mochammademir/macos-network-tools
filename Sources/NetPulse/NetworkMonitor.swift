import Foundation
import Combine

enum SortMode {
    case total, speed
}

struct Connection: Identifiable, Equatable {
    let id: String
    let pid: Int32?
    let processName: String
    let bytesIn: Int64
    let bytesOut: Int64
    let speedIn: Double  // bytes per second
    let speedOut: Double // bytes per second
    var totalBytes: Int64 { bytesIn + bytesOut }
    var currentSpeed: Double { speedIn + speedOut }
    var isPaused: Bool = false
}

class NetworkMonitor: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var totalIn: Int64 = 0
    @Published var totalOut: Int64 = 0
    @Published var sortMode: SortMode = .speed
    @Published var publicIP: String = "Loading..."
    @Published var localIP: String = "Loading..."
    @Published var isLoading: Bool = false
    @Published var isHardened: Bool = PersistenceManager.shared.isHardened()
    @Published var isPersistenceEnabled: Bool = UserDefaults.standard.bool(forKey: "persistencePreference")
    
    func verifyPassword(_ input: String) -> Bool {
        return LullabyGuard.shared.verify(input)
    }

    func setPersistence(_ enabled: Bool, password: String) {
        if enabled {
            // Enabling doesn't strictly need password if we want to allow re-enabling easily? 
            // But strict mode says yes. Let's stick to requiring it for disabling primarily.
            // But for consistency let's ask for it if we are changing state.
            // Actually, enabling persistence is usually fine? 
            // The prompt "Verify End-to-End Persistence" implies we need protection against disabling.
            // Let's require it for DISABLE only to avoid friction on enable?
            // "The 'Lullaby' master password must consistently protect all critical actions, including enabling/disabling"
            // So yes, enabling also needs it if the user requirement says "including enabling/disabling".
            if LullabyGuard.shared.verify(password) {
                 isPersistenceEnabled = enabled
                 UserDefaults.standard.set(enabled, forKey: "persistencePreference")
                 PersistenceManager.shared.register()
            }
        } else {
             // Disable
             if PersistenceManager.shared.unregister(password: password) {
                 isPersistenceEnabled = false
                 UserDefaults.standard.set(false, forKey: "persistencePreference")
             }
        }
    }

    func toggleHardening(password: String) {
        if isHardened {
            _ = PersistenceManager.shared.relaxHardening(password: password)
        } else {
            // Elevation scripts inside PersistenceManager don't take the Lullaby password, 
            // they take the System Admin Password (via osascript).
            // BUT, strictly speaking, we should GATE the request behind Lullaby first.
            if LullabyGuard.shared.verify(password) {
                _ = PersistenceManager.shared.elevateToHardened()
            }
        }
        // Force refresh status after the process completes
        isHardened = PersistenceManager.shared.isHardened()
    }
    @Published var isMeetingModeEnabled: Bool = false {
        didSet {
            // Mapping UI Meeting Mode to Enforcement State
            currentPolicy.currentState = isMeetingModeEnabled ? .focus : .normal
            saveCurrentPolicy()
        }
    }
    
    @Published var currentPolicy: Policy
    
    private var timer: Timer?
    private var lastStats: [String: (in: Int64, out: Int64)] = [:]
    private var lastFetchTime: Date?
    private var pausedPIDs: Set<Int32> = []
    
    // Default fallback whitelist
    private let defaultWhitelist = [
        "zoom", "zoom.us", "Teams", "Microsoft Teams", "Slack", "Webex", 
        "Skype", "FaceTime", "Google Chrome", "Safari", "Firefox",
        "Tailscale", "Cloudflare", "CloudflareWARP", "WARP", "AnyConnect", 
        "GlobalProtect", "NetPulse", "Antigravity", "ControlCenter", 
        "SystemUIServer", "WindowServer", "trustd", "mDNSResponder",
        "hidd", "coreaudiod", "bluetoothd", "language_server", "Antigravity"
    ]
    
    init() {
        // Load policy or use default
        if let localPolicy = PolicyStorage.shared.loadPolicy() {
            self.currentPolicy = localPolicy
        } else {
            self.currentPolicy = Policy(
                version: 1,
                tenantId: "DEFAULT",
                currentState: .normal,
                whitelist: defaultWhitelist,
                lastUpdated: Date()
            )
        }
        
        // Sync UI state
        // Temporarily avoid didSet recursion if needed, but in init it's fine
        self.isMeetingModeEnabled = (currentPolicy.currentState == .focus)
        
        // Automatic Persistence on First Launch & Update Check
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            isPersistenceEnabled = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else if isPersistenceEnabled && !isHardened {
            // Re-register to ensure plist is up-to-date
            PersistenceManager.shared.register()
        }
    }
    
    func saveCurrentPolicy() {
        currentPolicy.lastUpdated = Date()
        PolicyStorage.shared.savePolicy(currentPolicy)
    }
    
    func startMonitoring() {
        fetchPublicIP()
        getLocalIP()
        fetchConnections()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchConnections()
            self?.applyMeetingModeLogic()
        }
    }
    
    func stopMonitoring() {
        if isMeetingModeEnabled {
            toggleMeetingMode() // Resume all before stopping monitor
        }
        timer?.invalidate()
        timer = nil
    }

    func toggleMeetingMode() {
        isMeetingModeEnabled.toggle()
        if !isMeetingModeEnabled {
            resumeAll()
        }
    }

    private func applyMeetingModeLogic() {
        guard isMeetingModeEnabled else { return }
        
        // Find processes using more than 10 KB/s that are not in whitelist
        for conn in connections {
            guard let pid = conn.pid, pid > 1 else { continue }
            
            let isWhitelisted = currentPolicy.whitelist.contains { whitelistItem in
                conn.processName.lowercased().contains(whitelistItem.lowercased())
            }
            
            if isWhitelisted && pausedPIDs.contains(pid) {
                resumeProcess(pid: pid)
            } else if !isWhitelisted && conn.currentSpeed > 10240 { // > 10KB/s
                pauseProcess(pid: pid)
            }
        }
    }

    private func pauseProcess(pid: Int32) {
        if !pausedPIDs.contains(pid) {
            print("⏸ Pausing PID \(pid)")
            kill(pid, SIGSTOP)
            pausedPIDs.insert(pid)
        }
    }

    private func resumeProcess(pid: Int32) {
        if pausedPIDs.contains(pid) {
            print("▶️ Resuming PID \(pid)")
            kill(pid, SIGCONT)
            pausedPIDs.remove(pid)
        }
    }

    private func resumeAll() {
        for pid in pausedPIDs {
            print("▶️ Resuming PID \(pid)")
            kill(pid, SIGCONT)
        }
        pausedPIDs.removeAll()
    }
    
    func getLocalIP() {
        let addresses = Host.current().addresses
        if let ip = addresses.first(where: { $0.contains(".") && !$0.starts(with: "127.") }) {
            self.localIP = ip
        } else {
            self.localIP = "Unknown"
        }
    }
    
    func fetchPublicIP() {
        guard let url = URL(string: "https://api.ipify.org") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let ip = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { self.publicIP = ip }
            }
        }.resume()
    }
    
    func fetchConnections() {
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
            process.arguments = ["-L", "1", "-P"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let parsed = self.parseNettopOutput(output)
                    let now = Date()
                    let deltaSeconds = now.timeIntervalSince(self.lastFetchTime ?? now.addingTimeInterval(-2.0))
                    self.lastFetchTime = now
                    
                    let newConnections = parsed.connections.map { conn in
                        let prev = self.lastStats[conn.id] ?? (in: conn.bytesIn, out: conn.bytesOut)
                        let speedIn = Double(max(0, conn.bytesIn - prev.in)) / deltaSeconds
                        let speedOut = Double(max(0, conn.bytesOut - prev.out)) / deltaSeconds
                        // Updated structure hack: map doesn't allow direct update easily if let
                        return Connection(
                            id: conn.id, 
                            pid: conn.pid,
                            processName: conn.processName, 
                            bytesIn: conn.bytesIn, 
                            bytesOut: conn.bytesOut, 
                            speedIn: speedIn, 
                            speedOut: speedOut,
                            isPaused: self.pausedPIDs.contains(conn.pid ?? -1)
                        )
                    }
                    
                    self.lastStats = Dictionary(uniqueKeysWithValues: parsed.connections.map { ($0.id, (in: $0.bytesIn, out: $0.bytesOut)) })

                    DispatchQueue.main.async {
                        switch self.sortMode {
                        case .total:
                            self.connections = newConnections.sorted(by: { $0.totalBytes > $1.totalBytes })
                        case .speed:
                            self.connections = newConnections.sorted(by: { $0.currentSpeed > $1.currentSpeed })
                        }
                        self.totalIn = parsed.totalIn
                        self.totalOut = parsed.totalOut
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error running nettop: \(error)")
            }
        }
    }
    
    private func parseNettopOutput(_ output: String) -> (connections: [Connection], totalIn: Int64, totalOut: Int64) {
        var results: [String: (pid: Int32?, in: Int64, out: Int64)] = [:]
        var globalIn: Int64 = 0
        var globalOut: Int64 = 0
        
        let lines = output.components(separatedBy: .newlines)
        guard lines.count > 1 else { return ([], 0, 0) }
        
        for line in lines.dropFirst() {
            let cols = line.components(separatedBy: ",")
            if cols.count >= 6 {
                let procInfo = cols[1] // e.g. "Google Chrome.1234"
                let bytesIn = Int64(cols[4]) ?? 0
                let bytesOut = Int64(cols[5]) ?? 0
                
                let parts = procInfo.components(separatedBy: ".")
                let procName = parts.first ?? procInfo
                let pidStr = parts.last ?? ""
                let pid = Int32(pidStr)
                
                if procName.isEmpty || procName == "time" { continue }

                let current = results[procName] ?? (pid: pid, in: 0, out: 0)
                results[procName] = (pid: pid ?? current.pid, in: current.in + bytesIn, out: current.out + bytesOut)
                
                globalIn += bytesIn
                globalOut += bytesOut
            }
        }
        
        let connections = results.map { name, stats in
            Connection(id: name, pid: stats.pid, processName: name, bytesIn: stats.in, bytesOut: stats.out, speedIn: 0, speedOut: 0)
        }
        
        return (connections, globalIn, globalOut)
    }
}
