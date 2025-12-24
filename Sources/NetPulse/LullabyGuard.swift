import Foundation
import CryptoKit

class LullabyGuard {
    static let shared = LullabyGuard()
    
    // Default salt for local storage (in a real enterprise app, this should be per-user or fetched from server)
    private let salt = "netpulse-lullaby-static-salt"
    
    /// Verifies the provided password against the stored hash in Policy
    func verify(_ password: String) -> Bool {
        var storedHash = PolicyStorage.shared.loadPolicy()?.lullabyHash
        
        if storedHash == nil {
            // SECURITY FIX: If no password set, default to "lullaby" instead of allowing access.
            // We also save this default to the policy so it's persisted.
            let defaultPwd = "lullaby"
            let defaultHash = hash(defaultPwd)
            setPassword(defaultPwd) // Persist it
            storedHash = defaultHash
        }
        
        guard let validHash = storedHash else { return false }
        
        let inputHash = hash(password)
        return inputHash == validHash
    }
    
    func setPassword(_ password: String) {
        var policy = PolicyStorage.shared.loadPolicy()
        // If policy doesn't exist, Create a default one?
        // This relies on policy existing. PolicyStorage.shared.loadPolicy() returns optional.
        
        if policy == nil {
            // Create default policy if missing
             policy = Policy(version: 1, 
                             tenantId: "local", 
                             currentState: .normal, 
                             whitelist: [], 
                             lastUpdated: Date(),
                             lullabyHash: nil)
        }
        
        if var currentPolicy = policy {
            currentPolicy.lullabyHash = hash(password)
            PolicyStorage.shared.savePolicy(currentPolicy)
            print("🔒 Lullaby: Password updated.")
        }
    }
    
    func isLocked() -> Bool {
        // Implementation for UI state if needed
        return PolicyStorage.shared.loadPolicy()?.lullabyHash != nil
    }
    
    private func hash(_ input: String) -> String {
        let saltedInput = input + salt
        let data = saltedInput.data(using: .utf8)!
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
