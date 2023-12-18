/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */


import Foundation
import Combine


struct GitHubRepository: Identifiable, Hashable, Decodable {

    var id: Int
    var name: String
    var owner: GitHubOwner?

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    init(id: Int, name: String, owner: GitHubOwner) {
        self.init(id: id, name: name)
        self.owner = owner
    }

    init(message: String) {
        self.id = message.hashValue
        self.name = "(" + message + ")"
    }

    init() {
        self.id = 0
        self.name = ""
    }

    static func == (lhs: GitHubRepository, rhs: GitHubRepository) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var isValid: Bool {
        return !name.isEmpty && !name.starts(with: "(")
    }

}

struct GitHubOwner: Decodable {

    var login: String

    init() {
        self.login = ""
    }

    init(login: String) {
        self.login = login
    }

}


struct GitHubWorkflow: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    var path: String?

    init(id: Int, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }

    init(message: String) {
        self.id = message.hashValue
        self.name = "(" + message + ")"
    }

    init() {
        self.id = 0
        self.name = ""
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var isValid: Bool {
        return !name.isEmpty && !name.starts(with: "{")
    }

    var filename: String {
        guard let path = path else {
            return ""
        }
        return (path as NSString).lastPathComponent // TODO: is this the way to do it, really?
    }

}

