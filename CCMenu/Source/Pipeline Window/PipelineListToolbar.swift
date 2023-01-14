/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListToolbar: ToolbarContent {

    // TODO: the default values are replicated here from PipelineRow
    @AppStorage("pipelineDetailMode") var detailMode: DetailMode = .feedUrl
    @AppStorage("pipelineShowComment") var showComment: Bool = true
    @AppStorage("pipelineShowAvatar") var showAvatar: Bool = true

    let add: () -> Void
    let edit: () -> Void
    let remove: () -> Void
    let canEdit: () -> Bool
    let canRemove: () -> Bool

    var body: some ToolbarContent {
        ToolbarItem() {
            Menu() {
                Picker(selection: $detailMode, label: EmptyView()) {
                    Text("Pipeline").tag(DetailMode.feedUrl)
                    Text("Build Status").tag(DetailMode.buildStatus)
                }
                .pickerStyle(InlinePickerStyle())
                .accessibility(label: Text("Details picker"))
                Toggle("Status Comment", isOn: $showComment)
                Toggle("Status Avatar", isOn: $showAvatar)
            }
            label: {
                Image(systemName: "ellipsis.rectangle")
            }
            .menuStyle(.borderlessButton)
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
        ToolbarItem {
            Button(action: edit) {
                Label("Info", systemImage: "info.circle")
            }
            .help("Edit pipeline")
            .accessibility(label: Text("Edit pipeline"))
            .disabled(!canEdit())
        }
        ToolbarItem() {
            Button(action: remove) {
                Label("Remove", systemImage: "trash")
            }
            .help("Remove pipeline")
            .accessibility(label: Text("Remove pipeline"))
            .disabled(!canRemove())
        }
    }
    
    func updatePipelines() {
        NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
    }
    
}
