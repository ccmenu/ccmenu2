/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineList: View {
    @EnvironmentObject var modelData: ModelData
    
    var body: some View {
        List(modelData.pipelines, rowContent: { p in
            PipelineRow(pipeline: p)
        })
        .listStyle(PlainListStyle())
        
            

    }
}


struct PipelineList_Previews: PreviewProvider {
    static var previews: some View {
        PipelineList()
            .environmentObject(ModelData())
    }
}
