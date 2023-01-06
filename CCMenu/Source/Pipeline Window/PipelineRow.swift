/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineRow: View {
    var pipeline: Pipeline
    var style: PipelineDisplayStyle
    var avatars: Dictionary<URL, NSImage>

    var body: some View {
        HStack(alignment: .center) {
            if style.detailMode == .buildStatus && style.showAvatar {
                if let avatarUrl = pipeline.lastBuild?.avatar, let avatar = avatars[avatarUrl] {
                    Image(nsImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding([.trailing], 4)
                } else {
                    Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.gray)
                    .padding([.trailing], 4)
                }
            }
            VStack(alignment: .leading) {
                Text(pipeline.name)
                .font(.system(size: 16, weight: .bold))
                if style.detailMode == .feedUrl {
                    let connection = pipeline.connectionDetails
                    Text("\(connection.feedUrl) [\(connection.feedType.rawValue)]") // TODO: use icons for feed type
                } else {
                    Text(pipeline.status)
                    if style.showComment {
                        Text(pipeline.lastBuild?.comment ?? "–")
                    }
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(nsImage: ImageManager().image(forPipeline: pipeline))
        }
        .padding(4)
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        let style = PipelineDisplayStyle(detailMode: .buildStatus, showComment: true, showAvatar: true)
        PipelineRow(pipeline: makePipeline(), style: style, avatars: Dictionary())
    }

    static func makePipeline() -> Pipeline {
        var p = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cc.xml")
        p.activity = .building
        p.lastBuild = Build(result: .success)
        p.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p.lastBuild!.comment = "Made an important change."
        return p
    }

}
