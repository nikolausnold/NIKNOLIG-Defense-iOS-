import Foundation

public protocol SecureStore: Sendable {
    func read(forKey key: String) throws -> Data?
    func write(_ data: Data, forKey key: String) throws
    func delete(forKey key: String) throws
}

public enum SecureStoreError: Error, Equatable, Sendable {
    case invalidKey
    case platformUnavailable
    case operationFailed(Int32)
    case unexpectedResult
}

public enum SecurityGateStatus: String, Equatable, Sendable {
    case blocked = "BLOCKED"
}

public enum SecurityReadiness {
    public static let securityChainP0 = SecurityGateStatus.blocked
}

#if canImport(Security)
import Security

public final class KeychainSecureStore: SecureStore, @unchecked Sendable {
    private let service: String
    private let lock = NSLock()

    public init(service: String) {
        self.service = service
    }

    public func read(forKey key: String) throws -> Data? {
        try withLock {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: try account(forKey: key),
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: true
            ]
            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecItemNotFound {
                return nil
            }
            guard status == errSecSuccess else {
                throw SecureStoreError.operationFailed(Int32(status))
            }
            guard let data = result as? Data else {
                throw SecureStoreError.unexpectedResult
            }
            return data
        }
    }

    public func write(_ data: Data, forKey key: String) throws {
        try withLock {
            let account = try account(forKey: key)
            let identity: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            let update: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(identity as CFDictionary, update as CFDictionary)
            if updateStatus == errSecSuccess {
                return
            }
            guard updateStatus == errSecItemNotFound else {
                throw SecureStoreError.operationFailed(Int32(updateStatus))
            }

            var item = identity
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SecureStoreError.operationFailed(Int32(addStatus))
            }
        }
    }

    public func delete(forKey key: String) throws {
        try withLock {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: try account(forKey: key)
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw SecureStoreError.operationFailed(Int32(status))
            }
        }
    }

    private func account(forKey key: String) throws -> String {
        guard !key.isEmpty else { throw SecureStoreError.invalidKey }
        return key
    }

    private func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }
}
#else
public final class KeychainSecureStore: SecureStore, Sendable {
    public init(service: String) {}

    public func read(forKey key: String) throws -> Data? {
        throw SecureStoreError.platformUnavailable
    }

    public func write(_ data: Data, forKey key: String) throws {
        throw SecureStoreError.platformUnavailable
    }

    public func delete(forKey key: String) throws {
        throw SecureStoreError.platformUnavailable
    }
}
#endif
