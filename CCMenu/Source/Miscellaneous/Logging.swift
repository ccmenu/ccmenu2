/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import os
import Foundation

public func logRequest(_ request: URLRequest, response: HTTPURLResponse? = nil) {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
    let status: String
    if let code = response?.statusCode {
        status = String(format: "%3d", code)
    } else {
        status = (request.value(forHTTPHeaderField: "Authorization") != nil) ? "···" : "   "
    }
    let method = request.httpMethod ?? ""
    let url = request.url?.absoluteString ?? ""
    logger.info("Request: \(status, privacy: .public) \(method, privacy: .public) \(url, privacy: .public)")
}

