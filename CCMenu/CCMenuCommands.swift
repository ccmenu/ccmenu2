/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct CCMenuCommands: Commands {

    private struct MenuContent: View {
        var body: some View {
            Button("Update Status of All Pipelines") {
            }
                .disabled(false)
        }
    }

    var body: some Commands {
        CommandMenu("Pipeline") {
            MenuContent()
        }
    }

}
