/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineRow: View {
    var pipeline: Pipeline
    var style: PipelineDisplayStyle

    var body: some View {
        HStack(alignment: .center) {
            Image(nsImage: ImageManager().image(forPipeline: pipeline))
            VStack(alignment: .leading) {
                Text(pipeline.name)
                    .font(Font.headline)
                Text(style.detailMode == .buildStatus ? pipeline.status : pipeline.connectionDetails.feedUrl)
                    .font(Font.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxHeight: 36) // TODO: figure out why items want to grow when order changes
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        PipelineRow(pipeline: makePipeline(), style: PipelineDisplayStyle())
    }

    static func makePipeline() -> Pipeline {
        var p = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cc.xml")
        p.activity = .building
        p.lastBuild = Pipeline.Build(result: .success)
        p.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        return p
    }

}
