import SwiftUI

struct ContentView: View {
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("NetPulse")
                            .font(.system(size: 18, weight: .bold))
                        Text("PHASE 3 • PERFORMANCE MONITOR")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.pink)
                    }
                    Spacer()
                    
                    // Meeting Mode Toggle
                    Button(action: { networkMonitor.toggleMeetingMode() }) {
                        HStack {
                            Image(systemName: networkMonitor.isMeetingModeEnabled ? "video.fill" : "video")
                            Text("Meeting Mode")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(networkMonitor.isMeetingModeEnabled ? Color.green : Color.secondary.opacity(0.2))
                        .foregroundColor(networkMonitor.isMeetingModeEnabled ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Pause heavy background apps to prioritize your meeting.")

                    if networkMonitor.isLoading {
                        ProgressView().scaleEffect(0.6)
                    }
                }
                
                Picker("", selection: $networkMonitor.sortMode) {
                    Text("Top Total").tag(SortMode.total)
                    Text("Active Speed").tag(SortMode.speed)
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()

            // Meeting Mode Info
            if networkMonitor.isMeetingModeEnabled {
                HStack {
                    Image(systemName: "info.circle.fill")
                    Text("Meeting Mode Active: Background apps with heavy traffic will be suspended.")
                        .font(.system(size: 10))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                Divider()
            }

            // IP Info Bar
            HStack {
                Label(networkMonitor.localIP, systemImage: "macmini")
                Spacer()
                Label(networkMonitor.publicIP, systemImage: "globe")
            }
            .font(.system(size: 11, design: .monospaced))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.05))

            Divider()

            // Main List with Bars
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(networkMonitor.connections) { app in
                        AppRow(
                            app: app, 
                            maxVal: networkMonitor.sortMode == .total ? 
                                Double(networkMonitor.connections.first?.totalBytes ?? 1) : 
                                (networkMonitor.connections.first?.currentSpeed ?? 1.0),
                            mode: networkMonitor.sortMode
                        )
                    }
                }
                .padding()
            }
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Footer (Total Stats)
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("TOTAL DOWNLOAD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(formatBytes(networkMonitor.totalIn))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                
                VStack(alignment: .leading) {
                    Text("TOTAL UPLOAD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(formatBytes(networkMonitor.totalOut))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                
                Spacer()
                
                if networkMonitor.isMeetingModeEnabled {
                    Text("STABILIZING NETWORK...")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.green)
                        .opacity(0.8)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onAppear {
            networkMonitor.startMonitoring()
        }
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct AppRow: View {
    let app: Connection
    let maxVal: Double
    let mode: SortMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(app.processName)
                    .font(.system(size: 13, weight: .medium))
                
                if app.isPaused {
                    Text("SUSPENDED")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                }

                Spacer()
                HStack(spacing: 8) {
                    if app.currentSpeed > 0 {
                        Text(formatSpeed(app.currentSpeed))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(app.isPaused ? .orange : .pink)
                    }
                    Text(formatBytes(app.totalBytes))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 6)
                    
                    let ratio = mode == .total ? Double(app.totalBytes) / maxVal : app.currentSpeed / maxVal
                    Capsule()
                        .fill(LinearGradient(
                            colors: app.isPaused ? [.orange, .yellow] : (mode == .total ? [.pink, .orange] : [.blue, .cyan]), 
                            startPoint: .leading, 
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(min(1.0, ratio)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func formatSpeed(_ bytesPerSec: Double) -> String {
        let kbps = bytesPerSec / 1024.0
        if kbps < 1024 {
            return String(format: "%.1f KB/s", kbps)
        } else {
            return String(format: "%.1f MB/s", kbps / 1024.0)
        }
    }
}
