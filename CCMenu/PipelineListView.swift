/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State var selection: Set<String> = Set()

    var body: some View {
        List(selection: $selection) {
            ForEach(viewModel.pipelines) { p in
                PipelineRow(pipeline: p)
            }.onMove(perform: { (itemsToMove, destination) in
                viewModel.pipelines.move(fromOffsets: itemsToMove, toOffset: destination)
            })
        }
            .frame(minWidth: 440, minHeight: 56)
            // .listStyle(PlainListStyle()) // TODO: maybe as a preference?
            .toolbar {
                ToolbarItem {
                    Button(action: updatePipelines) {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem {
                    Spacer()
                }
                ToolbarItem {
                    Button(action: addPipeline) {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem() {
                    Button(action: removePipeline) {
                        Label("Remove", systemImage: "trash")
                    }
                }
                ToolbarItem {
                    Button(action: editPipeline) {
                        Label("Edit", systemImage: "gearshape")
                    }
                }

            }
    }
    
    func updatePipelines() {
    }
    
    func addPipeline() {
        viewModel.pipelines.move(fromOffsets: IndexSet(integer: 1), toOffset: 0)
    }

    func removePipeline() {
        var indexSet = IndexSet()
        for (i, p) in viewModel.pipelines.enumerated() {
            if selection.contains(p.id) {
                indexSet.insert(i)
            }
        }
        selection.removeAll()
        viewModel.pipelines.remove(atOffsets: indexSet)
    }

    func editPipeline() {
         NSLog("selection = \(selection)")
     }
}


struct PipelineListView_Previews: PreviewProvider {
    static var previews: some View {
        PipelineListView()
            .environmentObject(makeViewModel())
    }

    static func makeViewModel() -> ViewModel {
        let model = ViewModel()

        var p0 = Pipeline(name: "connectfour",
                          feedUrl: "http://localhost:4567/cctray.xml")
        p0.status = Pipeline.Status(buildResult: .failure, pipelineActivity: .building)
        p0.statusSummary = "Started 5 minutes ago\nETA: 04 Jan 2021, 14:37"

        var p1 = Pipeline(name: "erikdoe/ccmenu",
                          feedUrl: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml")
        p1.status = Pipeline.Status(buildResult: .success, pipelineActivity: .sleeping)
        p1.statusSummary = "Built 27 Dec 2020, 09:47pm\nLabel: 151"

        model.pipelines = [p0, p1]
        return model
    }
}