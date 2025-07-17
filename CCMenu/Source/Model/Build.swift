/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum BuildResult: String, Codable {
    case
    success,
    failure,
    unknown,
    other
}

struct Build: Codable {
    var result: BuildResult
    var id: String?
    var label: String?
    var timestamp: Date?
    var duration: TimeInterval?
    var message: String?
    var user: String?
    var avatar: URL?
}
