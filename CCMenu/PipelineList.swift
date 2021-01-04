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
         .listStyle(PlainListStyle()) // TODO: maybe as a preference?
    }


}


struct PipelineList_Previews: PreviewProvider {
    static var previews: some View {
        PipelineList()
            .environmentObject(ViewModel(withPreviewData: true))
    }
}
