/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import os

struct HTTPCredential {
    var user: String
    var password: String

    var isEmpty: Bool {
        user.isEmpty && password.isEmpty
    }
}

class CCTrayAPI {

    static func requestForProjects(url: URL, credential: HTTPCredential?) -> URLRequest {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")
        var request = URLRequest(url: url)

        if let credential {
            let v = URLRequest.basicAuthValue(user: credential.user, password: credential.password)
            request.setValue(v, forHTTPHeaderField: "Authorization")
            let redacted = v.replacingOccurrences(of: "[A-Za-z0-9=]", with: "*", options: [.regularExpression])
            logger.log("Making request for url \(url, privacy: .public) with authorization \(redacted, privacy: .public)")
        } else {
            logger.log("Making request for url \(url, privacy: .public)")
        }

        return request
    }

}
