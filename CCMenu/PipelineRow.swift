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
            HStack(alignment: .top, spacing: nil, content: {
                Image(nsImage: ImageManager().image(forPipeline: pipeline))
                    .padding(.top, 6)
                VStack(alignment: .leading) {
                    Text(pipeline.name)
                        .font(Font.headline)
                    Text(pipeline.connectionDetails.feedUrl)
                        .font(Font.caption)
                        .foregroundColor(.secondary)
                    }
                Spacer(minLength: 8)
                Text(pipeline.statusSummary)
                    .frame(width:180, alignment: .topLeading)  // TODO: find best width based on user's date formatting
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .font(Font.callout)

            })
        })
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var pipelines = ViewModel(withPreviewData: true).pipelines
    static var previews: some View {
        Group {
            PipelineRow(pipeline: pipelines[0])
            PipelineRow(pipeline: pipelines[1])
        }
    }
}
