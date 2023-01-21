/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
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

struct Build: Hashable, Codable {
    var result: BuildResult
    var label: String?
    var timestamp: Date?
    var duration: TimeInterval?
    var message: String?
    var user: String?
    var avatar: URL?
}
