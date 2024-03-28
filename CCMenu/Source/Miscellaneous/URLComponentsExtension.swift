/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

extension URLComponents {

    mutating func appendQueryItem(_ item: URLQueryItem) {
        if queryItems == nil {
            queryItems = [ ]
        }
        queryItems?.append(item)
    }

}

