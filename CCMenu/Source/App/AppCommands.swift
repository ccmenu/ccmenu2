/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
        }
        CommandGroup(replacing: .saveItem) {
        }
        CommandGroup(replacing: .importExport) {
            FileMenuItems()
        }
        CommandGroup(before: .toolbar) {
        }
        CommandGroup(before: .windowList) {
            WindowMenuItems()
        }
    }

    private struct FileMenuItems: View {
        var body: some View {
            Button("Import...") {
                // TODO: how to use file selector
                // TODO: how to access view model
            }
            Button("Export...") {
                // TODO: how to use file selector
                // TODO: how to access view model
            }
        }
    }

    private struct WindowMenuItems: View {
        @Environment(\.openWindow) var openWindow

        var body: some View {
            Button("Pipelines") {
                openWindow(id: "pipeline-list")
            }
            .keyboardShortcut("0")
            Divider()
        }
    }

}



