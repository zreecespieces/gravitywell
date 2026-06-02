import Foundation
import LocalAuthentication
import Security

struct KeychainService {
    private let service = "com.gravitywell.pihole.credential.v4"
    private let account = "default"

    private func authenticateWithBiometrics(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw KeychainError.biometricAuthenticationUnavailable(error?.localizedDescription)
        }

        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: KeychainError.biometricAuthenticationFailed(error?.localizedDescription))
                }
            }
        }
    }

    func hasCredential() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        return SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess
    }

    func saveCredential(_ credential: String, reason: String) async throws {
        try await authenticateWithBiometrics(reason: reason)
        let data = Data(credential.utf8)
        try upsertCredential(data: data)
    }

    func readCredential(reason: String) async throws -> String? {
        try await authenticateWithBiometrics(reason: reason)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }

        guard let data = item as? Data else {
            throw KeychainError.invalidData
        }

        return String(data: data, encoding: .utf8)
    }

    func deleteCredential() throws {
        try deleteCredential(service: service)
    }

    private func deleteCredential(service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    private func upsertCredential(data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(updateStatus)
        }

        try addCredential(data: data)
    }

    private func addCredential(data: Data) throws {
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unhandledStatus(addStatus)
        }
    }
}

enum KeychainError: LocalizedError {
    case invalidData
    case biometricAuthenticationUnavailable(String?)
    case biometricAuthenticationFailed(String?)
    case unhandledStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            "Keychain returned unreadable credential data."
        case .biometricAuthenticationUnavailable(let message):
            if let message {
                "Touch ID is not available: \(message)"
            } else {
                "Touch ID is not available or is not enrolled on this Mac."
            }
        case .biometricAuthenticationFailed(let message):
            if let message {
                "Touch ID authentication failed: \(message)"
            } else {
                "Touch ID authentication failed."
            }
        case .unhandledStatus(let status):
            "Keychain operation failed with status \(status)."
        }
    }
}
