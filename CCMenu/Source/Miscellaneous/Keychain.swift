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

class Keychain {

    func setPassword(_ password: String, forURL urlString: String) throws {
        let url = try getOrThrow(error: .invalidURLErr) { URL(string: urlString) }
        let query: [String: Any] = [
            kSecClass as String:        kSecClassInternetPassword,
            kSecAttrServer as String:   try getOrThrow(error: .missingHostErr) { url.host() },
            kSecAttrPort as String:     url.port ?? 80,
            kSecAttrAccount as String:  try getOrThrow(error: .missingUserErr) { url.user }
        ]
        var item: [String: Any] = [
            kSecAttrProtocol as String: try getOrThrow(error: .missingSchemeErr) { url.scheme },
            kSecValueData as String:    try getOrThrow(error: .passwordEncodingErr) { password.data(using: .utf8) }
        ]
        item.merge(query) { i, q in i }
        try setItem(item, forQuery: query)
    }

    func getPassword(forURL url: URL) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassInternetPassword,
            kSecAttrServer as String:   try getOrThrow(error: .missingHostErr) { url.host() },
            kSecAttrPort as String:     url.port ?? 80,
            kSecAttrAccount as String:  try getOrThrow(error: .missingUserErr) { url.user },
            kSecReturnData as String:   true
        ]
        return try getStringForQuery(query)
    }


    func setToken(_ token: String, forService service: String) throws {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  serviceForKeychain(service: service)
        ]
        var item: [String: Any] = [
            kSecValueData as String:    try getOrThrow(error: .passwordEncodingErr) { token.data(using: .utf8) }
        ]
        item.merge(query) { i, q in i }
        try setItem(item, forQuery: query)
    }

    func getToken(forService service: String) throws -> String? {
        if service == "GitHub", let token = UserDefaults.active.string(forKey: "GitHubToken") {
            return token
        }
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  serviceForKeychain(service: service),
            kSecReturnData as String:   true
        ]
        return try getStringForQuery(query)
     }
    
    
    private func setItem(_ item: [String: Any], forQuery query: [String: Any]) throws {
        var status = SecItemAdd(item as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(query as CFDictionary, item as CFDictionary)
        }
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
    private func getStringForQuery(_ query: [String: Any]) throws -> String? {
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status == errSecItemNotFound {
            return nil
        }
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getOrThrow<T>(error: KeychainAccessError, _ getter: () -> T?) throws -> T {
        guard let v = getter() else { throw error }
        return v
    }
    
    private func serviceForKeychain(service: String) -> String {
        "CCMenu \(service)"
    }

}
