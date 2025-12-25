import Foundation

class PolicyService {
    static let shared = PolicyService()
    
    // The Cloud Function Endpoint (Phase 4)
    private let endpointURL = URL(string: "https://getpolicy-junzrg67yq-et.a.run.app")!
    
    /// Fetches the latest policy configuration from the cloud.
    /// - Returns: A decoded `PolicyResponse` object.
    /// - Throws: `URLError` or `DecodingError` if the operation fails.
    func fetchPolicy() async throws -> PolicyResponse {
        let (data, response) = try await URLSession.shared.data(from: endpointURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("☁️ PolicyFetch Error: Status Code \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            // Note: The structs in PolicyStorage use snake_case property names 
            // matching the JSON keys, so no key decoding strategy is needed.
            let policyResponse = try decoder.decode(PolicyResponse.self, from: data)
            print("✅ Policy Fetched Successfully: v\(policyResponse.meta.version)")
            return policyResponse
        } catch {
            print("❌ Policy Decoding Error: \(error)")
            throw error
        }
    }
}
