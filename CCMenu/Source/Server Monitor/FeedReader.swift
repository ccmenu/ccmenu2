/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

protocol FeedReader {
    
    var delegate: FeedReaderDelegate? { get set }

    func updatePipelineStatus()
}


protocol FeedReaderDelegate {
    
    func feedReader(_ reader: FeedReader, didUpdate pipeline: Pipeline)
    
}
