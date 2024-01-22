/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct CCTrayProject: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    var path: String?

    init(name: String) {
        self.id = name.hashValue
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var isValid: Bool {
        return !name.isEmpty && !name.starts(with: "(")
    }

}

struct CCTrayProjectContainer: Decodable {
    var projects: [CCTrayProject]
}
