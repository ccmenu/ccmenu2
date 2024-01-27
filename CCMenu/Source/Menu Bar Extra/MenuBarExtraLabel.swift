/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct MenuBarExtraLabel: View {
    @ObservedObject var model: PipelineModel
    @AppStorage(.useColorInMenuBar) var useColorInMenuBar: Bool = true
    @AppStorage(.useColorInMenuBarFailedOnly) var useColorInMenuBarFailedOnly: Bool = false
    @AppStorage(.showBuildTimerInMenuBar) var showBuildTimerInMenuBar: Bool = false
    @Environment(\.displayScale) var displayScale   // TODO: Find out why this doesn't work here

    var body: some View {
        let viewModel = MenuExtraViewModel(pipelines: model.pipelines, useColorInMenuBar: useColorInMenuBar, useColorInMenuBarFailedOnly: useColorInMenuBarFailedOnly, showBuildTimerInMenuBar: showBuildTimerInMenuBar)
        HStack {
            if viewModel.title.isEmpty {
                Image(nsImage: viewModel.icon)
            } else {
                renderCapsuleImage(viewModel: viewModel)
            }
        }
        .accessibilityIdentifier("CCMenuMenuExtra")
    }

    @MainActor
    private func renderCapsuleImage(viewModel: MenuExtraViewModel) -> Image? {
        let image: NSImage?
        if let color = viewModel.color {
            let v = makeTextView(viewModel: viewModel, color: color)
            // TODO: Find out how to type v to avoid the duplicated lines below
            let renderer = ImageRenderer(content: v)
            renderer.scale = 2 // This should be displayScale, but that seems broken
            image = renderer.nsImage
        } else {
            let v =  makeTemplateTextView(viewModel: viewModel)
            let renderer = ImageRenderer(content: v)
            renderer.scale = 2 // This should be displayScale, but that seems broken
            image = renderer.nsImage
            image?.isTemplate = true
        }
        guard let image else {
            return nil
        }
        return Image(nsImage: image)
    }

    private func makeTextView(viewModel: MenuExtraViewModel, color: Color) -> some View {
        ZStack(alignment: .leading) {
            Text(viewModel.title)
                .monospacedDigit()
                .foregroundStyle(Color(nsColor: .statusText))
                .padding([.top, .bottom], 1)
                .padding(.trailing, 6)
                .padding(.leading, 18)
                .background() {
                    Capsule()
                        .foregroundStyle(color)
                }
            Image(nsImage: viewModel.icon)
        }
    }

    private func makeTemplateTextView(viewModel: MenuExtraViewModel) -> some View {
            Text(viewModel.title)
                .monospacedDigit()
                .foregroundStyle(.clear)
                .padding([.top, .bottom], 1)
                .padding(.trailing, 6)
                .padding(.leading, 18)
                .background() {
                    Capsule()
                        .mask(        
                            ZStack(alignment: .leading) {
                                Text(viewModel.title)
                                    .monospacedDigit()
                                    .padding([.top, .bottom], 1)
                                    .padding(.trailing, 6)
                                    .padding(.leading, 18)
                                    .background(Color.white)
                                Image(nsImage: NSImage(forActivity: .building))
                                    .colorInvert()
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                        )
                }
    }

}


struct MenuBarExtraLabel_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarExtraLabel(model: viewModelForPreview())
    }

    static func viewModelForPreview() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
        p0.status.activity = .building
        p0.status.currentBuild = Build(result: .unknown)
        p0.status.currentBuild?.timestamp = Date.now
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p0.status.lastBuild!.duration = 90

        var p1 = Pipeline(name: "erikdoe/ccmenu", feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
        p1.status.activity = .sleeping
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]

        model.update(pipeline: p0)
        model.update(pipeline: p1)

        return model
    }

}
