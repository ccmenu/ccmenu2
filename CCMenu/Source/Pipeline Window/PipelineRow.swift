/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineRow: View {

    var pipeline: Pipeline
    var avatars: Dictionary<URL, NSImage>
    @EnvironmentObject var settings: UserSettings

    var body: some View {
        HStack(alignment: .center) {
            if settings.showStatusInPipelineWindow && settings.showAvatarsInPipelineWindow {
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
                if !settings.showStatusInPipelineWindow {
                    Text("\(pipeline.feed.url) [\(pipeline.feed.type.rawValue)]") // TODO: use icons for feed type
                } else {
                    Text(pipeline.statusDescription)
                    if settings.showMessagesInPipelineWindow {
                        Text(pipeline.message ?? "–")
                    }
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(nsImage: pipeline.statusImage)
        }
        .padding(4)
    }

    private func avatarImage() -> Image {
        guard let avatarUrl = pipeline.avatar, let avatar = avatars[avatarUrl] else {
            return Image(systemName: "person.circle.fill")
        }
        return Image(nsImage: avatar)
    }
}


struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        PipelineRow(pipeline: pipelineForPreview(), avatars: Dictionary())
            .environmentObject(settingsForPreview(status: false))
        PipelineRow(pipeline: pipelineForPreview(), avatars: Dictionary())
            .environmentObject(settingsForPreview(status: true))
    }

    static func pipelineForPreview() -> Pipeline {
        var p = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cc.xml", activity: .sleeping)
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
