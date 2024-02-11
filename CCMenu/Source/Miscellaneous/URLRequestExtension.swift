/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

extension URLRequest {
    
    public static func basicAuthValue(user: String, password: String) -> String {
        let credentialString = "\(user):\(password)"
        guard let credentialData = credentialString.data(using: .utf8) else {
            // TODO: Consider adding error handling here
            return ""
        }
        let credentialAsBase64 = credentialData.base64EncodedString(options: [])
        return "Basic \(credentialAsBase64)"
    }
    
    public static func bearerAuthValue(token: String) -> String {
        return "Bearer \(token)"
    }
    
}
