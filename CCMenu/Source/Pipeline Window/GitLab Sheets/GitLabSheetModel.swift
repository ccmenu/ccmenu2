/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct GitLabProject: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    
    init(id: Int, name: String, path_with_namespace: String) {
        self.id = id
        self.name = name
    }
    
    init(message: String) {
        self.id = message.hashValue
        self.name = "(" + message + ")"
    }
    
    init() {
        self.id = 0
        self.name = ""
    }
    
    static func == (lhs: GitLabProject, rhs: GitLabProject) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var isValid: Bool {
        return !name.isEmpty && !name.starts(with: "(")
    }
    
    var displayName: String {
        return name
    }
}

struct GitLabBranch: Identifiable, Hashable, Decodable {
    var name: String
    
    init(name: String?) {
        self.name = name ?? "all branches"
    }
    
    init(message: String) {
        self.name = "(" + message + ")"
    }
    
    init() {
        self.name = ""
    }
    
    var id: Int {
        name.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var isAllBranchPlaceholder: Bool {
        return name == "all branches"
    }
    
    var isValid: Bool {
        return !name.isEmpty && !name.starts(with: "(")
    }
}

struct GitLabPersonalAccessToken: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    var scopes: [String]
    var active: Bool
    var expiresAt: String

    init() {
        self.id = 0
        self.name = ""
        self.scopes = []
        self.active = false
        self.expiresAt = ""
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var expiresAtDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: expiresAt)
    }

}
