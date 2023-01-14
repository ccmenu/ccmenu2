/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


enum DetailMode: String, CaseIterable {
    case buildStatus
    case feedUrl
}


struct PipelineRow: View {

    var pipeline: Pipeline
    var detail: DetailMode
    var showComment: Bool
    var showAvatar: Bool
    var avatars: Dictionary<URL, NSImage>

    var body: some View {
        HStack(alignment: .center) {
            if detail == .buildStatus && showAvatar {
                avatarImage()
                .resizable()
                .scaledToFill()
                .clipShape(Circle())    // TODO: should be in avatarImage but I can't figure out the return type
                .foregroundColor(.gray) // TODO: should be in avatarImage but I can't figure out the return type
                .frame(width: 32, height: 32)
                .padding([.trailing], 4)
            }
            VStack(alignment: .leading) {
                Text(pipeline.name)
                .font(.system(size: 16, weight: .bold))
                if detail == .feedUrl {
                    let connection = pipeline.connectionDetails
                    Text("\(connection.feedUrl) [\(connection.feedType.rawValue)]") // TODO: use icons for feed type
                } else {
                    Text(pipeline.status)
                    if showComment {
                        Text(pipeline.lastBuild?.comment ?? "–")
                    }
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(nsImage: ImageManager().image(forPipeline: pipeline))
        }
        .padding(4)
    }

    private func avatarImage() -> Image {
        guard let avatarUrl = pipeline.lastBuild?.avatar, let avatar = avatars[avatarUrl] else {
            return Image(systemName: "person.circle.fill")
        }
        return Image(nsImage: avatar)
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        PipelineRow(pipeline: makePipeline(), detail: .buildStatus, showComment: true, showAvatar: true, avatars: Dictionary())
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
