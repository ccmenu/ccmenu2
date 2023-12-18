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
    @ObservedObject var viewState: ListViewState = ListViewState()
    @EnvironmentObject var settings: UserSettings

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
        .listStyle(.inset(alternatesRowBackgrounds: true))
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
                    AddGithubPipelineSheet(controller: sheetController, selectionState: sheetController.selectionState, authState: sheetController.authState)
                }
            }
        }
        .toolbar {
            PipelineListToolbar(model: model, viewState: viewState)
        }
    }

}


//struct PipelineListView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            PipelineListView(model: makeViewModel(), settings: UserSettings(), viewState: ListViewState())
//            .preferredColorScheme(.light)
//            PipelineListView(model: makeViewModel(), settings: UserSettings(), viewState: ListViewState())
//            .preferredColorScheme(.dark)
//        }
//    }
//
//    static func makeViewModel() -> PipelineModel {
//        let model = PipelineModel()
//
//        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cc.xml", name: "connectfour"))
//        p0.status.activity = .building
//        p0.status.lastBuild = Build(result: .failure)
//        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
//
//        var p1 = Pipeline(name: "erikdoe/ccmenu", feed: Pipeline.Feed(type: .cctray, url: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml", name: "connectfour"))
//        p1.status.activity = .sleeping
//        p1.status.lastBuild = Build(result: .success)
//        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
//        p1.status.lastBuild!.label = "build.151"
//
//        model.pipelines = [p0, p1]
//        return model
//    }
//}
