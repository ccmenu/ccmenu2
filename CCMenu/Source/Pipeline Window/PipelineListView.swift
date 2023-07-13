/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListView: View {
    @ObservedObject var model: ViewModel
    @ObservedObject var settings: UserSettings
    @State var selection: Set<String> = Set()
    @State var isShowingSheet: Bool = false
    @State var sheetType: Pipeline.FeedType = .cctray
    @State var editIndex: Int?

    var body: some View {
        List(selection: $selection) {
            ForEach(model.pipelines) { p in
                PipelineRow(pipeline: p)
            }
            .onMove { (itemsToMove, destination) in
                movePipelines(at: itemsToMove, to: destination)
            }
            .onDelete { indexSet in
                removePipelines(at: indexSet)
            }
        }
        .frame(minWidth: 500)
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .sheet(isPresented: $isShowingSheet) {
            if let index = editIndex {
                EditPipelineSheet(model: model, editIndex: index)
            } else {
                switch sheetType {
                case .cctray: AddCCTrayPipelineSheet(model: model)
                case .github: AddGithubPipelineSheet(model: model)
                }
            }
        }
        .onChange(of: editIndex) { value in
            // TODO: without this empty onChange editIndex doesn't propogate for first sheet -- why?
        }
        .toolbar {
            PipelineListToolbar(
                add:        { type in addPipeline(type: type) },
                edit:       { editPipeline(at: selectionIndexSet().first) },
                remove:     { removePipelines(at: selectionIndexSet()) },
                canEdit:    { selection.count == 1 },
                canRemove:  { !selection.isEmpty },
                reload:     { model.reloadPipelineStatus() }
            )
        }
        .environmentObject(settings)
    }

    func selectionIndexSet() -> IndexSet {
        var indexSet = IndexSet()
        for (i, p) in model.pipelines.enumerated() {
            if selection.contains(p.id) {
                indexSet.insert(i)
            }
        }
        return indexSet
    }

    func addPipeline(type: Pipeline.FeedType) {
        // TODO: for Github the CCTray sheet is shown for about a second; why?
        editIndex = nil
        sheetType = type
        isShowingSheet = true
    }

    func editPipeline(at index: Int?) {
        editIndex = index
        isShowingSheet = true
    }

    func removePipelines(at indexSet: IndexSet) {
        withAnimation {
            model.pipelines.remove(atOffsets: indexSet)
            selection.removeAll()
        }
    }

    func movePipelines(at indexSet: IndexSet, to destination: Int) {
        withAnimation {
            model.pipelines.move(fromOffsets: indexSet, toOffset: destination)
        }
    }

}


struct PipelineListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PipelineListView(model: makeViewModel(), settings: UserSettings())
            .preferredColorScheme(.light)
            PipelineListView(model: makeViewModel(), settings: UserSettings())
            .preferredColorScheme(.dark)
        }
    }

    static func makeViewModel() -> ViewModel {
        let model = ViewModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cc.xml", name: "connectfour"))
        p0.status.activity = .building
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "erikdoe/ccmenu", feed: Pipeline.Feed(type: .cctray, url: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml", name: "connectfour"))
        p1.status.activity = .sleeping
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]
        return model
    }
}
