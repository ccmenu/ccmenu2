/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct HTTPCredential {
    var user: String
    var password: String

    var isEmpty: Bool {
        user.isEmpty && password.isEmpty
    }
}

class CCTrayAPI {

    static func requestForProjects(url: URL, credential: HTTPCredential?) -> URLRequest {
        var request = URLRequest(url: url)

        if let credential {
            let v = URLRequest.basicAuthValue(user: credential.user, password: credential.password)
            request.setValue(v, forHTTPHeaderField: "Authorization")
        }

        return request
    }

}
