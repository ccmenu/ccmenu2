/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineRow: View {

    var viewModel: PipelineRowModel
    @EnvironmentObject var settings: UserSettings
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                if settings.showStatusInPipelineWindow && settings.showAvatarsInPipelineWindow {
                    avatarImage()
                        .padding([.trailing], 6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.title)
                        .font(.system(size: NSFont.systemFontSize + 1, weight: .bold))
                    if settings.showStatusInPipelineWindow {
                        Text(viewModel.statusDescription)
                            .adjustedColor(colorScheme: colorScheme)
                    } else {
                        HStack(alignment: .top, spacing: 4) {
                            Image(viewModel.feedTypeIconName)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .adjustedColor(colorScheme: colorScheme)
                            Text(viewModel.feedUrl)
                                .adjustedColor(colorScheme: colorScheme)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.bottom], 2)
                Image(nsImage: viewModel.statusIcon)
            }
            .padding(2)
        }
        .listRowSeparator(.visible, edges: [.bottom])

    }


    private func avatarImage() -> some View {
        AsyncImage(url: viewModel.pipeline.avatar) { image in
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
    }

}

extension View {
    func adjustedColor(colorScheme: ColorScheme) -> some View {
        let factor = colorScheme == .dark ? 0.8 : 1
        return self.foregroundColor(.primary).colorMultiply(Color(white: factor))
    }
}

struct PipelineRow_Previews: PreviewProvider {
    static var previews: some View {
        PipelineRow(viewModel: PipelineRowModel(pipeline: pipelineForPreview(), settings: settingsForPreview(status: false)))
            .environmentObject(settingsForPreview(status: false))
        PipelineRow(viewModel: PipelineRowModel(pipeline: pipelineForPreview(), settings: settingsForPreview(status: true)))
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
