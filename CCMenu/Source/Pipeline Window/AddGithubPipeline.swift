/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AddGithubPipelineSheet: View {
    @ObservedObject var model: PipelineModel
    @ObservedObject var viewState: ListViewState
    @Environment(\.presentationMode) @Binding var presentation
    var authController: GithubAuthController
    @State var pipeline: Pipeline = Pipeline(name: "", feed:Pipeline.Feed(type:.github, url: ""))
    @State var owner: String = ""
    @State var repository: String = ""
    @State var workflow: String = ""
    @State var permanentlyFalse: Bool = false

    var body: some View {
        VStack {
            Text("Add Github Actions workflow")
            .font(.headline)
            Spacer()
            HStack {
                Text("Please enter the owner (user or organisation), the name of the repository, and the workflow. The workflow is given as the name of the file in the .github/workflows directory.")
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            }
            Form {
                HStack {
                    Text("Owner:")
                    TextField("", text: $owner)
                }
                .onChange(of: owner) { _ in updatePipeline() }
                HStack {
                    Text("Repository:")
                    TextField("", text: $repository)
                }
                .onChange(of: repository) { _ in updatePipeline() }
                HStack {
                    Text("Workflow:")
                    TextField("", text: $workflow)
                }
                .onChange(of: workflow) { _ in updatePipeline() }
                HStack {
                    Text("Authentication:")
                    TextField("", text: $viewState.accessTokenDescription)
                    .disabled(true)
                    // TODO: Find out why state change doesn't trigger redraw
                    if viewState.isWaitingForToken {
                        Button("Cancel") {
                            authController.stopWaitingForToken()
                        }
                    } else {
                        Button(viewState.accessToken == nil ? "Sign in..." : "Refresh...") {
                            authController.signInAtGitHub()
                        }
                    }
                    Button("Review") {
                        authController.openReviewAccessPage()
                    }
                }
            }
            Divider()
            .padding()
            Form {
                HStack {
                    Text("Display name:")
                    TextField("", text: $pipeline.name)
                    Button(action: { pipeline.name = "\(repository) (\(workflow))" }) {
                        Label("Reset", systemImage: "arrowshape.turn.up.backward")
                    }
                }
            }
            Spacer()
            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                Button("Apply") {
                    // TODO: check for empty display name
                    // TODO: check whether workflow exists
                    pipeline.feed.type = .github
                    pipeline.feed.authToken = viewState.accessToken
                    pipeline.status = Pipeline.Status(activity: .other)
                    pipeline.status.lastBuild = Build(result: .unknown)
                    // TODO: should trigger first poll of status
                    model.pipelines.append(pipeline)
                    presentation.dismiss()
                }
            }
        }
        .frame(width: 500)
        .padding()
    }


    private func updatePipeline() {
        pipeline.feed.url = String(format: "https://api.github.com/repos/%@/%@/actions/workflows/%@/runs", owner, repository, workflow)
        pipeline.name = "\(repository) (\(workflow))"
    }

}


struct AddGithubPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AddGithubPipelineSheet(model: ViewModel())
        }
    }
}

