/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineListMenu: View {
    
    @ObservedObject var model: PipelineModel
    @ObservedObject var viewState: ListViewState
    @EnvironmentObject var ghAuthenticator: GitHubAuthenticator
    var contextSelection: Set<String> = []

    var body: some View {
        Button("Copy Feed URL") {
            let value = model.pipelines
                .filter({ selection.contains($0.id) })
                .map({ $0.feed.url.absoluteString })
                .joined(separator: "\n")
            NSPasteboard.general.prepareForNewContents()
            NSPasteboard.general.setString(value, forType: .string)
        }
        .disabled(selection.isEmpty)
        Button("Open Web Page") {
            model.pipelines
                .filter({ selection.contains($0.id) })
                .forEach({ NSWorkspace.shared.openWebPage(pipeline: $0) })
        }
        .disabled(selection.isEmpty)
        if !contextSelection.isEmpty {
            Divider()
            Button("Edit...") {
                let p = model.pipelines.first(where: { viewState.selection.contains($0.id) })
                viewState.editPipelineSheetConfig.setPipeline(p)
                viewState.editPipelineSheetConfig.isPresented = true
            }
            .disabled(contextSelection.count != 1)
            Button("Remove") {
                withAnimation {
                    contextSelection.forEach({ model.remove(pipelineId: $0) })
                    viewState.selection = viewState.selection.subtracting(contextSelection)
                }
           }
        }
        Divider()
        Button("Import pipelines...") {
            viewState.isShowingImporter = true
        }
        Button("Export pipelines...") {
            viewState.isShowingExporter = true
        }
        Divider()
        Button("Sign In at GitHub...") {
            Task { 
                if await ghAuthenticator.signInAtGitHub() {
                    viewState.signInAtGitHubSheetSheetConfig.isPresented = true
                    await ghAuthenticator.waitForToken()
                }
            }
        }
    }

    private var selection: Set<String> {
        !contextSelection.isEmpty ? contextSelection : viewState.selection
    }

    private var isCCTrayFeedSelected: Bool {
        model.pipelines.first(where: { selection.contains($0.id) && $0.feed.type == .cctray }) != nil
    }
}
