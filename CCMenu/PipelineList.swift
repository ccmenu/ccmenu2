/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineList: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        List(selection: $viewModel.selection) {
            ForEach(viewModel.pipelines) { p in
                PipelineRow(pipeline: p)
            }.onMove(perform: { (itemsToMove, destination) in
                viewModel.pipelines.move(fromOffsets: itemsToMove, toOffset: destination)
            })
        }.frame(minWidth: 440, minHeight: 56)
//         .listStyle(PlainListStyle()) // TODO: maybe as a preference?
    }

}


struct PipelineList_Previews: PreviewProvider {
    static var previews: some View {
        PipelineList()
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
