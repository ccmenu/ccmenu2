/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct DynamicFeedSource: Identifiable, Equatable {
    
    let id: String
    var url: URL
    var isEnabled: Bool
    var removeDeletedPipelines: Bool
    var lastSyncTime: Date?
    var lastSyncError: String?
    
    init(url: URL, id: String = UUID().uuidString) {
        self.id = id
        self.url = url
        self.isEnabled = true
        self.removeDeletedPipelines = true
    }
    
    init?(dictionary dict: [String: String]) {
        guard
            let id = dict["id"],
            let urlString = dict["url"],
            let url = URL(string: urlString),
            !urlString.isEmpty,
            let isEnabledString = dict["isEnabled"],
            let removeDeletedString = dict["removeDeletedPipelines"]
        else {
            return nil
        }
        
        self.id = id
        self.url = url
        self.isEnabled = isEnabledString == "true"
        self.removeDeletedPipelines = removeDeletedString == "true"
    }
    
    func toDictionary() -> [String: String] {
        [
            "id": id,
            "url": url.absoluteString,
            "isEnabled": isEnabled ? "true" : "false",
            "removeDeletedPipelines": removeDeletedPipelines ? "true" : "false"
        ]
    }
    
    static func == (lhs: DynamicFeedSource, rhs: DynamicFeedSource) -> Bool {
        lhs.id == rhs.id
    }
    
}

