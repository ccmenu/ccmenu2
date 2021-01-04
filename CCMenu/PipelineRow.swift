/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineRow: View {
    var pipeline: Pipeline

    var body: some View {
        HStack(alignment: .top, spacing: nil) {
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
                .frame(width: 180, alignment: .topLeading)  // TODO: find best width based on user's date formatting
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .font(Font.callout)
        }.frame(maxHeight: 32) // TODO: figure out items want to grow when order changes
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        PipelineRow(pipeline: makePipeline())
    }

    static func makePipeline() -> Pipeline {
        var p = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cc.xml")
        p.status = Pipeline.Status(buildResult: .success, pipelineActivity: .building)
        p.statusSummary = "Built 27 Dec 2020, 09:47pm\nLabel: 151"
        return p
    }

}
