/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

final class ListViewState: ObservableObject {
    @Published var isShowingSheet: Bool = false
    @Published var sheetType: Pipeline.FeedType = .cctray
    @Published var editIndex: Int?
    @Published var selection: Set<String> = Set()
}

struct PipelineListView: View {
    var controller: PipelineWindowController
    @ObservedObject var model: PipelineModel
    @ObservedObject var viewState: ListViewState
    @EnvironmentObject var settings: UserSettings
    @Environment(\.openURL) private var openUrl

    var body: some View {
        List(selection: $viewState.selection) {
            ForEach(model.pipelines) { p in
                PipelineRow(pvm: ListRowModel(pipeline: p, settings: settings))
            }
            .onMove { (itemsToMove, destination) in
                withAnimation {
                    model.pipelines.move(fromOffsets: itemsToMove, toOffset: destination)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    model.pipelines.remove(atOffsets: indexSet)
                    viewState.selection.removeAll()
                }
            }
        }
        .frame(minWidth: 500)
        .contextMenu(forSelectionType: String.self) {_ in
            Text("Copy URL") // TODO: add functionality
        } primaryAction: { _ in
            // TODO: figure out what to open (same logic as in menu?)
            openUrl(URL(string: "http://ccmenu.org")!)
        }
        .sheet(isPresented: $viewState.isShowingSheet) {
            if let index = viewState.editIndex {
                EditPipelineSheet(model: model, editIndex: index)
            } else {
                switch viewState.sheetType {
                case .cctray:
                    AddCCTrayPipelineSheet(model: model)
                case .github:
                    // TODO: Consider: pass only controller, and then view pulls out models?
                    let sheetController = controller.ghSheetController
                    AddGithubPipelineSheet(controller: sheetController, selectionState: sheetController.workflowState, authState: sheetController.authState)
                }
            }
        }
        .toolbar {
            PipelineListToolbar(model: model, viewState: viewState)
        }
    }

}


struct PipelineListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let controller = PipelineWindowController(model: makeViewModel())
            PipelineListView(controller: controller, model: controller.model, viewState: controller.listViewState)
                .environmentObject(makeSettings())
        }
    }

    static func makeViewModel() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cc.xml", name: "connectfour"))
        p0.status.activity = .building
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "ccmenu2 (build-and-test)", feed: Pipeline.Feed(type: .github, url: "https://api.github.com/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs", name: nil))
        p1.status.activity = .sleeping
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"
        p1.status.lastBuild?.message = "Push ⋮ Made some refactorings."

        model.pipelines = [p0, p1]
        return model
    }

    static func makeSettings() -> UserSettings {
        let settings = UserSettings()
        settings.showStatusInPipelineWindow = true
        return settings
    }
}
