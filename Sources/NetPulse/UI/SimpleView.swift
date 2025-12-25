import SwiftUI

struct SimpleView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NetPulse")
                        .font(.system(size: 24, weight: .bold))
                    
                    // Status Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(statusColor)
                            .textCase(.uppercase)
                    }
                }
                
                Spacer()
                
                // Settings Button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main Content
            VStack(spacing: 24) {
                Spacer()
                
                // Meeting Mode Toggle
                VStack(spacing: 12) {
                    Button(action: {
                        networkMonitor.toggleMeetingMode()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: networkMonitor.isMeetingModeEnabled ? "video.fill" : "video")
                                .font(.system(size: 20))
                            
                            Text("Meeting Mode")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(networkMonitor.isMeetingModeEnabled ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(networkMonitor.isMeetingModeEnabled ? Color.green : Color.gray.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if networkMonitor.isMeetingModeEnabled {
                        Text("Background apps with heavy traffic will be suspended")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Cloud Status
                VStack(spacing: 12) {
                    CloudPulseIndicator(status: networkMonitor.cloudStatus)
                    
                    if let lastSync = networkMonitor.lastPolicySync {
                        Text("Last sync: \(timeAgoString(from: lastSync))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Current Speed (Realtime)
                VStack(spacing: 8) {
                    Text("Current Speed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text(formatSpeed(currentSpeedIn))
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(formatSpeed(currentSpeedOut))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 500)
        .onAppear {
            networkMonitor.startMonitoring()
        }
        .onDisappear {
            networkMonitor.stopMonitoring()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(networkMonitor: networkMonitor)
        }
    }
    
    private var statusText: String {
        switch networkMonitor.currentPolicy.currentState {
        case .normal: return "Normal"
        case .focus: return "Focus / Meeting"
        case .pdp: return "PDP Compliance"
        case .pdpRiskAccepted: return "PDP Risk Accepted"
        case .lockdown: return "Lock Down"
        }
    }
    
    private var statusColor: Color {
        switch networkMonitor.currentPolicy.currentState {
        case .normal: return .green
        case .focus: return .orange
        case .pdp: return .blue
        case .pdpRiskAccepted: return .yellow
        case .lockdown: return .red
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "\(seconds) seconds ago"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }
    
    private var currentSpeedIn: Double {
        networkMonitor.connections.reduce(0) { $0 + $1.speedIn }
    }
    
    private var currentSpeedOut: Double {
        networkMonitor.connections.reduce(0) { $0 + $1.speedOut }
    }
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let kbps = bytesPerSec / 1024.0
        if kbps < 1 {
            return "0 KB/s"
        } else if kbps < 1024 {
            return String(format: "%.1f KB/s", kbps)
        } else {
            return String(format: "%.1f MB/s", kbps / 1024.0)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}
