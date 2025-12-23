import Foundation
import Combine

enum SortMode {
    case total, speed
}

struct Connection: Identifiable, Equatable {
    let id: String
    let processName: String
    let bytesIn: Int64
    let bytesOut: Int64
    let speedIn: Double  // bytes per second
    let speedOut: Double // bytes per second
    var totalBytes: Int64 { bytesIn + bytesOut }
    var currentSpeed: Double { speedIn + speedOut }
}

class NetworkMonitor: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var totalIn: Int64 = 0
    @Published var totalOut: Int64 = 0
    @Published var sortMode: SortMode = .total
    @Published var publicIP: String = "Loading..."
    @Published var localIP: String = "Loading..."
    @Published var isLoading: Bool = false
    
    private var timer: Timer?
    private var lastStats: [String: (in: Int64, out: Int64)] = [:]
    private var lastFetchTime: Date?
    
    func startMonitoring() {
        fetchPublicIP()
        getLocalIP()
        
        // Initial fetch
        fetchConnections()
        
        // Schedule timer
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchConnections()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func getLocalIP() {
        // Simple way to get local IP (interface en0 usually)
        // For simplicity in this demo, we can just use Host.current().address assuming it resolves correctly,
        // or parse ifconfig. Let's try Host way first, if failure we can parse later.
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
                DispatchQueue.main.async {
                    self.publicIP = ip
                }
            } else {
                DispatchQueue.main.async {
                    self.publicIP = "Error"
                }
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
                        return Connection(id: conn.id, processName: conn.processName, bytesIn: conn.bytesIn, bytesOut: conn.bytesOut, speedIn: speedIn, speedOut: speedOut)
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
        var results: [String: (in: Int64, out: Int64)] = [:]
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
                
                let procName = procInfo.components(separatedBy: ".").first ?? procInfo
                if procName.isEmpty || procName == "time" { continue }

                let current = results[procName] ?? (0, 0)
                results[procName] = (current.in + bytesIn, current.out + bytesOut)
                
                globalIn += bytesIn
                globalOut += bytesOut
            }
        }
        
        let connections = results.map { name, stats in
            Connection(id: name, processName: name, bytesIn: stats.in, bytesOut: stats.out, speedIn: 0, speedOut: 0)
        }
        
        return (connections, globalIn, globalOut)
    }
}
