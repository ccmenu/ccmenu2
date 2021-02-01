/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineDisplayStyle {
    var detailMode: DetailMode = .buildStatus

    enum DetailMode: Int {
        case buildStatus
        case feedUrl
    }
}


struct PipelineListView: View {
    @ObservedObject var model: ViewModel
    @State var style: PipelineDisplayStyle = PipelineDisplayStyle()
    @State var selection: Set<String> = Set()
    @State var isShowingSheet: Bool = false
    @State var editIndex: Int?

    var body: some View {
        List(selection: $selection) {
            ForEach(model.pipelines) { p in
                PipelineRow(pipeline: p, style: style)
            }
            .onMove { (itemsToMove, destination) in
                withAnimation {
                    model.pipelines.move(fromOffsets: itemsToMove, toOffset: destination)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    model.pipelines.remove(atOffsets: indexSet)
                }
            }
        }
        .frame(minWidth: 440, minHeight: 56)
        .focusedValue(\.pipelineDisplayStyle, $style)
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
                style: $style,
                add: {
                    editIndex = nil
                    isShowingSheet = true
                },
                edit: {
                    editIndex = model.pipelines.firstIndex(where: { selection.contains($0.id) })
                    isShowingSheet = true
                },
                remove: {
                    var indexSet = IndexSet()
                    for (i, p) in model.pipelines.enumerated() {
                        if selection.contains(p.id) {
                            indexSet.insert(i)
                        }
                    }
                    selection.removeAll()
                    withAnimation {
                        model.pipelines.remove(atOffsets: indexSet)
                    }
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
    
}


struct PipelineListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PipelineListView(model: makeViewModel(), style: PipelineDisplayStyle(detailMode: .feedUrl))
            .preferredColorScheme(.light)
            PipelineListView(model: makeViewModel(), style: PipelineDisplayStyle(detailMode: .buildStatus))
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
