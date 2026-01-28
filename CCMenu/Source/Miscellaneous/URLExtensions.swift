/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

extension URL {

    func removing(queryItem: String) -> URL {
        var c = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        c.removeQueryItem(name: queryItem)
        return c.url!.absoluteURL
    }

}

private extension URLComponents {

    mutating func removeQueryItem(name: String) {
        guard var tempItems = queryItems else { return }
        tempItems = tempItems.filter { $0.name != name }
        queryItems = tempItems.isEmpty ? nil : tempItems
    }

}

