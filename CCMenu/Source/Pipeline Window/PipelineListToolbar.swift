/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListToolbar: ToolbarContent {
    @Binding var style: PipelineDisplayStyle
    let add: () -> Void
    let edit: () -> Void
    let remove: () -> Void
    let canEdit: () -> Bool
    let canRemove: () -> Bool

    var body: some ToolbarContent {
        ToolbarItem() {
            Menu() {
                Picker(selection: $style.detailMode, label: Text("Details to show")) {
                    Text("Build status").tag(PipelineDisplayStyle.DetailMode.buildStatus)
                    Text("Feed URL").tag(PipelineDisplayStyle.DetailMode.feedUrl)
                }
                .pickerStyle(InlinePickerStyle())
                .accessibility(label: Text("Details picker"))
            } label: {
                Label("Details", systemImage: "captions.bubble")
            }
            .help("Select which details to show for the pipelines")
        }
        ToolbarItem() {
            Button(action: updatePipelines) {
                Label("Update", systemImage: "arrow.clockwise")
            }
            .help("Retrieve status for all pipelines from servers")
        }
        ToolbarItem(placement: .primaryAction) {
            Button(action: add) {
                Label("Add", systemImage: "plus")
            }
            .help("Add pipeline")
            .accessibility(label: Text("Add pipeline"))
        }
        ToolbarItem(placement: .destructiveAction) {
            Button(action: remove) {
                Label("Remove", systemImage: "trash")
            }
            .help("Remove pipeline")
            .accessibility(label: Text("Remove pipeline"))
            .disabled(!canRemove())
        }
        ToolbarItem {
            Button(action: edit) {
                Label("Edit", systemImage: "gearshape")
            }
            .help("Edit pipeline")
            .accessibility(label: Text("Edit pipeline"))
            .disabled(!canEdit())
        }
    }
    
    func updatePipelines() {
        NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
    }
    
}
