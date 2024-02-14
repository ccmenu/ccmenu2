/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Security


enum KeychainAccessError: Error {
    case passwordEncodingErr
    case invalidURLErr
    case missingSchemeErr
    case missingHostErr
    case missingUserErr
}

class KeychainHelper {

    public func setPassword(_ password: String, forURL urlString: String) throws {
        let url = try getOrThrow(error: .invalidURLErr) { URL(string: urlString) }
        let host = try getOrThrow(error: .missingHostErr) { url.host() }
        let port = url.port ?? 80
        let user = try getOrThrow(error: .missingUserErr) { url.user }
        let scheme = try getOrThrow(error: .missingSchemeErr) { url.scheme }
        let passwordData = try getOrThrow(error: .passwordEncodingErr) { password.data(using: .utf8) }

        let query: [String: Any] = [
            kSecClass as String:        kSecClassInternetPassword,
            kSecAttrServer as String:   host,
            kSecAttrPort as String:     port,
            kSecAttrAccount as String:  user
        ]
        var item: [String: Any] = [
            kSecAttrProtocol as String: scheme,
            kSecValueData as String:    passwordData
        ]
        item.merge(query) { i, q in i }

        var status = SecItemAdd(item as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(query as CFDictionary, item as CFDictionary)
        }

        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    public func getPassword(forURL url: URL) throws -> String? {
        let host = try getOrThrow(error: .missingHostErr) { url.host() }
        let port = url.port ?? 80
        let user = try getOrThrow(error: .missingUserErr) { url.user }

        let query: [String: Any] = [
            kSecClass as String:        kSecClassInternetPassword,
            kSecAttrServer as String:   host,
            kSecAttrPort as String:     port,
            kSecAttrAccount as String:  user,
            kSecReturnData as String:   true
        ]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }


    private func getOrThrow<T>(error: KeychainAccessError, _ getter: () -> T?) throws -> T {
        guard let v = getter() else {
            throw error
        }
        return v
    }

}
