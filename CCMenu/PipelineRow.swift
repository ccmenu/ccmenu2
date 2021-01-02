/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineRow: View {
    var pipeline: Pipeline

    var body: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            HStack(alignment: .center, spacing: nil, content: {
                Image(nsImage: ImageManager().image(forPipeline: pipeline))
                    .padding(.all, 8)
                VStack(alignment: .leading) {
                    Text(pipeline.name)
                        .font(Font.title)
                    Text(pipeline.connectionDetails.feedUrl)
                        .font(Font.caption)
                    }
                Spacer(minLength: 8)
                Text(pipeline.statusSummary)
                    .frame(width: 200, height: 36, alignment: .bottomLeading)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            })
            Divider()
        })
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var pipelines = ModelData().pipelines
    static var previews: some View {
        Group {
            PipelineRow(pipeline: pipelines[0])
            PipelineRow(pipeline: pipelines[1])
            PipelineRow(pipeline: pipelines[2])
        }
    }
}
