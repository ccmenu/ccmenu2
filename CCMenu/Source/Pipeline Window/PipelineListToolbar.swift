/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListToolbar: ToolbarContent {

    @ObservedObject var model: PipelineModel
    @ObservedObject var viewState: ListViewState
    @AppStorage(.showStatusInWindow) var showStatus = true
    @AppStorage(.showAvatarsInWindow) var showAvatars = true
    @AppStorage(.showMessagesInWindow) var showMessages = true
    @State var isHoveringOverDetailMenu = false
    @State var isHoveringOverAddMenu = false
    @State var isHoveringOverOverflowMenu = false

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu() {
                Picker(selection: $showStatus, label: EmptyView()) {
                    Text("Pipeline URL").tag(false)
                    Text("Build Status").tag(true)
                }
                .pickerStyle(InlinePickerStyle())
                .accessibility(label: Text("Details picker"))
                Button(showMessages ? "Hide Messages" : "Show Messages") {
                    showMessages.toggle()
                }
                .disabled(!showStatus)
                Button(showAvatars ? "Hide Avatars" : "Show Avatars") {
                    showAvatars.toggle()
                }
                .disabled(!showStatus)
            } label: {
                Image(systemName: "list.dash.header.rectangle")
            }
            .menuStyle(.borderlessButton)
            .padding(.bottom, 1)
            .padding([.leading, .trailing], 8)
            .frame(height: 28)
            .opacity(0.7)
            .background() {
                Color(.unemphasizedSelectedContentBackgroundColor).opacity(isHoveringOverDetailMenu ? 0.45 : 0)
            }
            .onHover {
                isHoveringOverDetailMenu = $0
            }
            .cornerRadius(6)
            .accessibility(label: Text("Display detail menu"))
            .help("Select which details to show for the pipelines")
        }

        ToolbarItemGroup(placement: .principal) {
            Menu() {
                Button("Add project from CCTray feed...") {
                    viewState.showSheet = .addCCTrayPipelineSheet
                }
                Button("Add GitHub Actions workflow...") {
                    viewState.showSheet = .addGitHubPipelineSheet
                }
            } label: {
                Image(systemName: "plus")
            }
            .menuStyle(.borderlessButton)
            .padding(.bottom, 1)
            .padding([.leading, .trailing], 8)
            .frame(height: 28)
            .opacity(0.7)
            .background() {
                // TODO: Fix transparency in dark mode
                Color(.unemphasizedSelectedContentBackgroundColor).opacity(isHoveringOverAddMenu ? 0.45 : 0)
            }
            .onHover {
                isHoveringOverAddMenu = $0
            }
            .cornerRadius(6)
            .accessibility(label: Text("Add pipeline menu"))
            .help("Add a pipeline")

            Button() {
                viewState.pipelineToEdit = model.pipelines.first(where: { viewState.selection.contains($0.id) })
                viewState.showSheet = .editPipelineSheet
            } label: {
                Label("Edit", systemImage: "gearshape")
            }
            .help("Edit pipeline")
            .accessibility(label: Text("Edit pipeline"))
            .disabled(viewState.selection.count != 1)

            Button() {
                withAnimation {
                    viewState.selection.forEach({ model.remove(pipelineId: $0) })
                    viewState.selection.removeAll()
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .help("Remove pipeline")
            .accessibility(label: Text("Remove pipeline"))
            .disabled(viewState.selection.isEmpty)

            Menu() {
                PipelineListMenu(model: model, viewState: viewState)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .padding(.bottom, 1)
            .padding([.leading, .trailing], 8)
            .frame(height: 28)
            .opacity(0.7)
            .background() {
                // TODO: Fix transparency in dark mode
                Color(.unemphasizedSelectedContentBackgroundColor).opacity(isHoveringOverOverflowMenu ? 0.45 : 0)
            }
            .onHover {
                isHoveringOverOverflowMenu = $0
            }
            .cornerRadius(6)
            .accessibility(label: Text("Additional actions menu"))
            .help("Additional actions")
        }

    }

}
