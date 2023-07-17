/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListToolbar: ToolbarContent {

    @EnvironmentObject var settings: UserSettings

    let add: (_: Pipeline.FeedType) -> Void
    let edit: () -> Void
    let remove: () -> Void
    let canEdit: () -> Bool
    let canRemove: () -> Bool
    let reload: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Menu() {
                Picker(selection: $settings.showStatusInPipelineWindow, label: EmptyView()) {
                    Text("Pipeline URL").tag(false)
                    Text("Build Status").tag(true)
                }
                .pickerStyle(InlinePickerStyle())
                .accessibility(label: Text("Details picker"))
                Button(settings.showMessagesInPipelineWindow ? "Hide Messages" : "Show Messages") {
                    settings.showMessagesInPipelineWindow.toggle()
                }
                .disabled(!settings.showStatusInPipelineWindow)
                Button(settings.showAvatarsInPipelineWindow ? "Hide Avatars" : "Show Avatars") {
                    settings.showAvatarsInPipelineWindow.toggle()
                }
                .disabled(!settings.showStatusInPipelineWindow)
            }
            label: {
                Image(systemName: "list.dash.header.rectangle")
            }
            .menuStyle(.borderlessButton)
            .accessibility(label: Text("Display detail menu"))
            .help("Select which details to show for the pipelines")

            Spacer() // TODO: This shouldn't be necessary
        }
        ToolbarItemGroup {
            Menu() {
                Button("Add project from CCTray feed...") {
                    add(.cctray)
                }
                Button("Add Github workflow...") {
                    add(.github)
                }
            }
            label: {
                Image(systemName: "plus.square")
            }
            .menuStyle(.borderlessButton)
            .accessibility(label: Text("Add pipeline menu"))
            .help("Add a pipeline")

            Button(action: edit) {
                Label("Edit", systemImage: "gearshape")
            }
            .help("Edit pipeline")
            .accessibility(label: Text("Edit pipeline"))
            .disabled(!canEdit())

            Button(action: remove) {
                Label("Remove", systemImage: "trash")
            }
            .help("Remove pipeline")
            .accessibility(label: Text("Remove pipeline"))
            .disabled(!canRemove())
        }
        ToolbarItemGroup {
            Button(action: reload) {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .help("Update status of all pipelines")
        }
    }

}
