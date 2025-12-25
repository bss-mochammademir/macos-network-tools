import Foundation

/// Defines the various enforcement levels of NetPulse.
/// Based on the "Context-Aware" security model.
enum EnforcementState: String, Codable {
    /// Standard operations with minimal background monitoring.
    case normal = "Normal"
    
    /// User-initiated stabilization for meetings or deep work.
    case focus = "Focus / Meeting"
    
    /// Baseline corporate compliance rules (ISO 27001).
    case pdp = "PDP (Corporate Default)"
    
    /// Temporary exceptions granted via external Risk Acceptance API.
    case pdpRiskAccepted = "PDP Risk Accepted"
    
    /// Incident-triggered maximum restriction.
    case lockdown = "Lock Down"
    
    var icon: String {
        switch self {
        case .normal: return "shield"
        case .focus: return "video.fill"
        case .pdp: return "building.columns.fill"
        case .pdpRiskAccepted: return "timer"
        case .lockdown: return "exclamationmark.shield.fill"
        }
    }
}

// MARK: - Local Legacy Model (For backwards compatibility / flattened view)
struct Policy: Codable {
    var version: Int
    var tenantId: String
    var currentState: EnforcementState
    var whitelist: [String]
    var lastUpdated: Date
    var lullabyHash: String?
    
    // New fields mapped from Cloud Policy
    var features: PolicyFeatures?
}

// MARK: - Cloud JSON Models
/// Represents the root JSON response from the Cloud Function
struct PolicyResponse: Codable {
    let meta: PolicyMeta
    let policy: PolicyConfig
}

struct PolicyMeta: Codable {
    let version: Int
    let last_updated: String
    let tenant_id: String
}

struct PolicyConfig: Codable {
    let enforcement_mode: String // "monitor_only", "soft", "strict"
    let global_whitelist: [String]
    let features: PolicyFeatures
}

struct PolicyFeatures: Codable {
    let meeting_mode: Bool
    let hardening: Bool
}

class PolicyStorage {
    static let shared = PolicyStorage()
    private let fileName = "policy_config.json"
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appDir = paths[0].appendingPathComponent("NetPulse")
        
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        return appDir.appendingPathComponent(fileName)
    }
    
    func savePolicy(_ policy: Policy) {
        do {
            let data = try JSONEncoder().encode(policy)
            try data.write(to: fileURL)
            print("💾 Policy saved to: \(fileURL.path)")
        } catch {
            print("❌ Failed to save policy: \(error)")
        }
    }
    
    func loadPolicy() -> Policy? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Policy.self, from: data)
        } catch {
            print("ℹ️ No local policy found, using defaults.")
            return nil
        }
    }
}
