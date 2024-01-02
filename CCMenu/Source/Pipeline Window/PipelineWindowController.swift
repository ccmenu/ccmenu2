/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class PipelineWindowController {

    @ObservedObject var model: PipelineModel
    @ObservedObject var listViewState: ListViewState

    init(model: PipelineModel) {
        self.model = model
        listViewState = ListViewState()
    }


}
