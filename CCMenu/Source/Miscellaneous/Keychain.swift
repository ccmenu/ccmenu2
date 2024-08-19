/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Security
import os

enum KeychainAccessError: Error {
    case passwordEncodingErr
    case invalidURLErr
    case missingSchemeErr
    case missingHostErr
    case missingUserErr
    case invalidKeychainType
}

class Keychain {

    static let standard = Keychain()

    private let lock: NSLock
    private var cache: [String: String]

    private init() {
        lock = NSLock()
        cache = Dictionary()
    }

    func setPassword(_ password: String, forURL urlString: String) throws {
        let url = try getOrThrow(error: .invalidURLErr) { URL(string: urlString) }
        let query = [
            kSecClass:        kSecClassInternetPassword,
            kSecAttrServer:   try getOrThrow(error: .missingHostErr) { url.host() },
            kSecAttrPort:     url.port ?? 80,
            kSecAttrAccount:  try getOrThrow(error: .missingUserErr) { url.user(percentEncoded: false) }
        ] as NSDictionary
        let item = [
            kSecClass:        kSecClassInternetPassword,
            kSecAttrServer:   try getOrThrow(error: .missingHostErr) { url.host() },
            kSecAttrPort:     url.port ?? 80,
            kSecAttrAccount:  try getOrThrow(error: .missingUserErr) { url.user(percentEncoded: false) },
            kSecAttrProtocol: try getOrThrow(error: .missingSchemeErr) { url.scheme },
            kSecValueData:    try getOrThrow(error: .passwordEncodingErr) { password.data(using: .utf8) }
        ] as NSDictionary
        try setItem(item, forQuery: query)
        cache[urlString] = nil
    }

    func getPassword(forURL url: URL) throws -> String? {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "keychain")
        if let password = cache[url.absoluteString] {
            logger.log("Using cached password for \(url, privacy: .public)")
            return password
        }
        logger.log("Retrieving password for \(url, privacy: .public) from keychain")
        let query = [
            kSecClass:        kSecClassInternetPassword,
            kSecAttrServer:   try getOrThrow(error: .missingHostErr) { url.host() },
            kSecAttrPort:     url.port ?? 80,
            kSecAttrAccount:  try getOrThrow(error: .missingUserErr) { url.user(percentEncoded: false) },
            kSecMatchLimit:   kSecMatchLimitOne,
            kSecReturnData:   true
        ] as NSDictionary
        let password = try getStringForQuery(query)
        if let password {
            logger.log("Got password (length = \(password.count, privacy: .public))")
        } else {
            logger.log("Didn't get a password")
        }
        cache[url.absoluteString] = password
        return password
    }


    func setToken(_ token: String, forService service: String) throws {
        let query = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  serviceForKeychain(service: service)
        ] as NSDictionary
        let item = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  serviceForKeychain(service: service),
            kSecValueData:    try getOrThrow(error: .passwordEncodingErr) { token.data(using: .utf8) }
        ] as NSDictionary
        try setItem(item, forQuery: query)
        cache[service] = nil
    }

    func getToken(forService service: String) throws -> String? {
        if service == "GitHub", let token = UserDefaults.active.string(forKey: "GitHubToken") {
            return token.isEmpty ? nil : token
        }
        if let token = cache[service] {
            return token
        }
        let query = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  serviceForKeychain(service: service),
            kSecMatchLimit:   kSecMatchLimitOne,
            kSecReturnData:   true
        ] as NSDictionary
        let token = try getStringForQuery(query)
        cache[service] = token
        return token
    }

    
    private func setItem(_ item: NSDictionary, forQuery query: NSDictionary) throws {
        lock.lock()
        defer { lock.unlock() }

        var status = SecItemAdd(item, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(query, item)
        }
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
    private func getStringForQuery(_ query: NSDictionary) throws -> String? {
        lock.lock()
        defer { lock.unlock() }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)
        if status == errSecItemNotFound {
            return nil
        }
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard let data = result as? Data else { throw KeychainAccessError.invalidKeychainType }
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
