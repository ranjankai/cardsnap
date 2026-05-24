import Foundation
import Security

/// Helper class for secure Keychain access on iOS and macOS Catalyst
class KeychainHelper {
    static let shared = KeychainHelper()
    private let service = "com.rkant.cardsnap"
    private let account = "GeminiAPIKey"
    
    private init() {}
    
    /// Securely saves a string value to the Keychain. If an entry already exists, it is updated.
    func save(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Delete any pre-existing entry
        SecItemDelete(query as CFDictionary)
        
        // Construct standard attributes
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainHelper] Save Error: \(status)")
        }
    }
    
    /// Reads a string value securely from the Keychain.
    func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    /// Wipes the secure key from the Keychain.
    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
