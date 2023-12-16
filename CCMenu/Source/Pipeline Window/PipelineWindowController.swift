/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class PipelineWindowController {

    var ghSheetController: GitHubSheetController

    @ObservedObject var listViewState: ListViewState

    init() {
        listViewState = ListViewState()
        ghSheetController = GitHubSheetController()
    }


}
