/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


final class ListViewState: ObservableObject {
    @Published var selection: Set<String> = Set()
    @Published var addCCTrayPipelineSheetConfig = PipelineSheetConfig()
    @Published var addGitHubPipelineSheetConfig = PipelineSheetConfig()
    @Published var editPipelineSheetConfig = PipelineSheetConfig()
    @Published var signInAtGitHubSheetSheetConfig = PipelineSheetConfig()
    @Published var isShowingImporter: Bool = false
    @Published var isShowingExporter: Bool = false
    @Published var errorMessage: String? = nil
}


struct PipelineListView: View {
    @ObservedObject var model: PipelineModel
    @AppStorage(.pollInterval) var pollInterval = 10
    @StateObject var viewState = ListViewState()
    @StateObject private var ghAuthenticator = GitHubAuthenticator()

    var body: some View {
        List(selection: $viewState.selection) {
            ForEach(model.pipelines) { p in
                PipelineRow(viewModel: PipelineRowViewModel(pipeline: p, pollInterval: Double(pollInterval)))
            }
            .onMove { (itemsToMove, destination) in
                withAnimation {
                    model.pipelines.move(fromOffsets: itemsToMove, toOffset: destination)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    model.pipelines.remove(atOffsets: indexSet)
                    viewState.selection.removeAll()
                }
            }
        }
        .frame(minWidth: 500)
        .toolbar {
            PipelineListToolbar(model: model, viewState: viewState)
        }
        .contextMenu(forSelectionType: String.self) { selection in
            PipelineListMenu(model: model, viewState: viewState, contextSelection: selection)
        } primaryAction: { selection in
            model.pipelines
                .filter({ selection.contains($0.id) })
                .forEach({ NSWorkspace.shared.openWebPage(pipeline: $0) })
        }
       .sheet(isPresented: $viewState.addCCTrayPipelineSheetConfig.isPresented) {
            if let p = viewState.addCCTrayPipelineSheetConfig.pipeline {
                model.add(pipeline: p)
            }
        } content: {
            AddCCTrayPipelineSheet(config: $viewState.addCCTrayPipelineSheetConfig)
        }
        .sheet(isPresented: $viewState.addGitHubPipelineSheetConfig.isPresented) {
            if let p = viewState.addGitHubPipelineSheetConfig.pipeline {
                model.add(pipeline: p)
            }
        } content: {
            AddGitHubPipelineSheet(config: $viewState.addGitHubPipelineSheetConfig)
        }
        .sheet(isPresented: $viewState.editPipelineSheetConfig.isPresented) {
            if let p = viewState.editPipelineSheetConfig.pipeline {
                model.update(pipeline: p)
            }
        } content: {
            EditPipelineSheet(config: $viewState.editPipelineSheetConfig)
        }
        .sheet(isPresented: $viewState.signInAtGitHubSheetSheetConfig.isPresented) {
        } content: {
            SignInAtGitHubSheet()
        }
        .fileImporter(isPresented: $viewState.isShowingImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let fileurl):
                if let error = model.importPipelinesFromFile(url: fileurl) {
                    self.viewState.errorMessage = error.localizedDescription
                }
            case .failure(let error):
                self.viewState.errorMessage = error.localizedDescription
            }
        }
        .fileExporter(isPresented: $viewState.isShowingExporter, document: model.exportPipelinesToDocument(selection: viewState.selection), contentType: .json, defaultFilename: "pipelines") { result in
            if case .failure(let error) = result {
                self.viewState.errorMessage = error.localizedDescription
            }
        }
        .alert("Error", isPresented: Binding(get: { viewState.errorMessage != nil }, set: { v in if !v { viewState.errorMessage = nil }})) {
            Button("OK") { }
        } message: {
            Text(viewState.errorMessage ?? "unknown error")
        }
        .environmentObject(ghAuthenticator)
    }

}


struct PipelineListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PipelineListView(model: makeViewModel())
        }
    }

    static func makeViewModel() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cc.xml", name: "connectfour"))
        p0.status.activity = .building
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "ccmenu2 (build-and-test)", feed: Pipeline.Feed(type: .github, url: "https://api.github.com/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs", name: nil))
        p1.status.activity = .sleeping
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"
        p1.status.lastBuild?.message = "Push ⋮ Made some refactorings."

        model.pipelines = [p0, p1]
        return model
    }

}
