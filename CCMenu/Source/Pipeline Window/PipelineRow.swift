/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineRow: View {

    var pipeline: Pipeline
    @EnvironmentObject var settings: UserSettings

    var body: some View {
        HStack(alignment: .center) {
            if settings.showStatusInPipelineWindow && settings.showAvatarsInPipelineWindow {
                avatarImage()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(pipeline.name)
                .font(.system(size: NSFont.systemFontSize + 1, weight: .bold))
                if settings.showStatusInPipelineWindow {
                    statusDescription()
                } else {
                    pipelineUrl()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(nsImage: pipeline.statusImage)
        }
        .padding(4)
    }

    private func avatarImage() -> some View {
        AsyncImage(url: pipeline.avatar) { image in
            image
            .resizable()
            .clipShape(Circle())
        } placeholder: {
            Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray)
        }
        .frame(width: 40, height: 40)
        .scaledToFill()
        .padding([.trailing], 4)
    }

    private func pipelineUrl() -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            Image("feed-\(pipeline.feed.type)-template")
            .resizable()
            .frame(width: 16, height: 16)
            Text(pipeline.feed.url)
            if pipeline.feed.type == .cctray, let name = pipeline.feed.name, name != pipeline.name {
                Text(String(format: "(%@)", name))
            }
        }
    }

    private func statusDescription() -> some View {
        VStack(alignment: .leading) {
            Text(pipeline.statusDescription)
            if settings.showMessagesInPipelineWindow {
                Text(pipeline.message ?? "–")
            }
        }
    }

}


struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        PipelineRow(pipeline: pipelineForPreview())
            .environmentObject(settingsForPreview(status: false))
        PipelineRow(pipeline: pipelineForPreview())
            .environmentObject(settingsForPreview(status: true))
    }

    static func pipelineForPreview() -> Pipeline {
        var p = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cc.xml", name: "connectfour"))
        p.status.lastBuild = Build(result: .success)
        p.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:34Z")
        p.status.lastBuild!.duration = 12*60 + 34
        p.status.currentBuild = Build(result: .unknown)
        p.status.currentBuild!.timestamp = ISO8601DateFormatter().date(from: "2023-01-22T14:24:16Z")
        p.status.currentBuild!.message = "Made an important change."
        return p
    }

    private static func settingsForPreview(status: Bool) -> UserSettings {
        let s = UserSettings()
        s.showStatusInPipelineWindow = status
        s.showMessagesInPipelineWindow = true
        s.showAvatarsInPipelineWindow = true
        return s
    }

}
