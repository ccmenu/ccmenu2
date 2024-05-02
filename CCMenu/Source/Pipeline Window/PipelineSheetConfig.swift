/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct PipelineSheetConfig {
    var isPresented: Bool = false
    var pipeline: Pipeline?
    
    mutating func setPipeline(_ pipeline: Pipeline?) {
        self.pipeline = pipeline
    }
}
