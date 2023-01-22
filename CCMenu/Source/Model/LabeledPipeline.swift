/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


// Used for the menu. Label is the full text shown in the menu.

struct LabeledPipeline: Hashable, Identifiable {
    var pipeline: Pipeline
    var label: String
    var id: String {
        pipeline.id
    }
}
