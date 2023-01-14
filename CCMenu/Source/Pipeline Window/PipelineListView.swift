/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListView: View {
    @ObservedObject var model: ViewModel
    @State var selection: Set<String> = Set()
    @State var isShowingSheet: Bool = false
    @State var editIndex: Int?

    var body: some View {
        List(selection: $selection) {
            ForEach(model.pipelines) { p in
                PipelineRow(pipeline: p, avatars: model.avatars)
            }
            .onMove { (itemsToMove, destination) in
                movePipelines(at: itemsToMove, to: destination)
            }
            .onDelete { indexSet in
                removePipelines(at: indexSet)
            }
        }
        .frame(minWidth: 400)
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .sheet(isPresented: $isShowingSheet) {
            if let index = editIndex {
                EditPipelineSheet(model: model, editIndex: index)
            } else {
                AddPipelineSheet(model: model)
            }
        }
        .onChange(of: editIndex) { value in
            // TODO: without this empty onChange editIndex doesn't propogate for first sheet -- why?
        }
        .toolbar {
            PipelineListToolbar(
            add: {
                addPipeline()
            },
            edit: {
                editPipeline(at: selectionIndexSet().first)
            },
            remove: {
                removePipelines(at: selectionIndexSet())
            },
            canEdit: {
                selection.count == 1
            },
            canRemove: {
                !selection.isEmpty
            }

            )
        }
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

    func addPipeline() {
        editIndex = nil
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
            PipelineListView(model: makeViewModel())
            .preferredColorScheme(.light)
            PipelineListView(model: makeViewModel())
            .preferredColorScheme(.dark)
        }
    }

    static func makeViewModel() -> ViewModel {
        let model = ViewModel()

        var p0 = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cctray.xml")
        p0.activity = .building
        p0.lastBuild = Build(result: .failure)
        p0.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "erikdoe/ccmenu", feedUrl: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml")
        p1.activity = .sleeping
        p1.lastBuild = Build(result: .success)
        p1.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]
        return model
    }
}
