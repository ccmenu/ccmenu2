/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineList: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        VStack {
            List(viewModel.pipelines, selection: $viewModel.selectionIds) { p in
                PipelineRow(pipeline: p)
            }
//                    .listStyle(PlainListStyle()) // TODO: maybe as a preference?
        }
    }

}


struct PipelineList_Previews: PreviewProvider {
    static var previews: some View {
        PipelineList()
                .environmentObject(ViewModel(withPreviewData: true))
    }
}
