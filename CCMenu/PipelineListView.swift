/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


enum DetailMode: Int {
    case buildStatus
    case feedUrl
}


struct PipelineListView: View {
    @ObservedObject var viewModel: ViewModel
    @State var details: DetailMode = .buildStatus
    @State var selection: Set<String> = Set()
    
    var body: some View {
        List(selection: $selection) {
            ForEach(viewModel.pipelines) { p in
                PipelineRow(pipeline: p, details: details)
            }
            .onMove { (itemsToMove, destination) in
                withAnimation {
                    viewModel.pipelines.move(fromOffsets: itemsToMove, toOffset: destination)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    viewModel.pipelines.remove(atOffsets: indexSet)
                }
            }
        }
        .frame(minWidth: 440, minHeight: 56)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Details", selection: $details) {
                    Text("Status").tag(DetailMode.buildStatus)
                    Text("URL").tag(DetailMode.feedUrl)
                }
                .pickerStyle(MenuPickerStyle()) // TODO: How to show icons?
                .help("Select which details to show for the pipelines")
                .accessibility(label: Text("Details picker"))
            }
            ToolbarItem {
                Button(action: updatePipelines) {
                    Label("Update", systemImage: "arrow.clockwise")
                }
                .help("Retrieve status for all pipelines from servers")
            }
            ToolbarItem {
                Button(action: addPipeline) {
                    Label("Add", systemImage: "plus")
                }
                .help("Add pipeline")
                .accessibility(label: Text("Add pipeline"))
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(action: removePipeline) {
                    Label("Remove", systemImage: "trash")
                }
                .help("Remove pipeline")
                .accessibility(label: Text("Remove pipeline(s)"))
                .disabled(selection.isEmpty)
            }
            ToolbarItem {
                Button(action: editPipeline) {
                    Label("Edit", systemImage: "gearshape")
                }
                .help("Edit pipeline")
                .accessibility(label: Text("Edit pipeline"))
                .disabled(selection.count != 1)
            }

        }
    }

    func updatePipelines() {
        NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
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
        withAnimation {
            viewModel.pipelines.remove(atOffsets: indexSet)
        }
    }

    func editPipeline() {
        NSLog("selection = \(selection)")
    }
}


struct PipelineListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PipelineListView(viewModel: makeViewModel(), details: .feedUrl)
            .preferredColorScheme(.light)
            PipelineListView(viewModel: makeViewModel(), details: .buildStatus)
            .preferredColorScheme(.dark)
        }
    }

    static func makeViewModel() -> ViewModel {
        let model = ViewModel()

        var p0 = Pipeline(name: "connectfour",
                          feedUrl: "http://localhost:4567/cctray.xml")
        p0.status = Pipeline.Status(buildResult: .failure, pipelineActivity: .building)
        p0.statusSummary = "Started: 5 minutes ago, ETA: 04 Jan 2021, 14:37"

        var p1 = Pipeline(name: "erikdoe/ccmenu",
                          feedUrl: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml")
        p1.status = Pipeline.Status(buildResult: .success, pipelineActivity: .sleeping)
        p1.statusSummary = "Built: 27 Dec 2020 09:47, Label: 151"

        model.pipelines = [p0, p1]
        return model
    }
}
