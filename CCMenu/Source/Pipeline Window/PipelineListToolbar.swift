/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListToolbar: ToolbarContent {

    @ObservedObject var model: PipelineModel
    @ObservedObject var viewState: ListViewState
    @EnvironmentObject var settings: UserSettings
    @State var isHoveringOverDetailMenu = false
    @State var isHoveringOverAddMenu = false

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
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
                    viewState.sheetType = .cctray
                    viewState.isShowingAddSheet = true
                }
                Button("Add GitHub Actions workflow...") {
                    viewState.sheetType = .github
                    viewState.isShowingAddSheet = true
                }
            } label: {
                Image(systemName: "plus.square")
            }
            .menuStyle(.borderlessButton)
            .padding(.bottom, 1)
            .padding([.leading, .trailing], 8)
            .frame(height: 28)
            .opacity(0.7)
            .background() {
                Color(.unemphasizedSelectedContentBackgroundColor).opacity(isHoveringOverAddMenu ? 0.45 : 0)
            }
            .onHover {
                isHoveringOverAddMenu = $0
            }
            .cornerRadius(6)
            .accessibility(label: Text("Add pipeline menu"))
            .help("Add a pipeline")

            Button() {
                viewState.isShowingEditSheet = true
            } label: {
                Label("Edit", systemImage: "gearshape")
            }
            .help("Edit pipeline")
            .accessibility(label: Text("Edit pipeline"))
            .disabled(viewState.selection.count != 1)

            Button() {
                withAnimation {
                    model.pipelines.removeAll(where: { viewState.selection.contains($0.id) })
//                    model.pipelines.remove(atOffsets: viewState.selectionIndexSet(pipelines: model.pipelines))
                    viewState.selection.removeAll()
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .help("Remove pipeline")
            .accessibility(label: Text("Remove pipeline"))
            .disabled(viewState.selection.isEmpty)
        }

//        ToolbarItem(placement: .principal) {
//            Button() {
//                model.reloadPipelineStatus()
//            } label: {
//                Label("Reload", systemImage: "arrow.clockwise")
//            }
//            .help("Update status of all pipelines")
//        }
    }

}
