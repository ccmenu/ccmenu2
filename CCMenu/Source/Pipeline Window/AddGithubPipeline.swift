/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine

typealias Repository = GitHubAPI.Repository
typealias Workflow = GitHubAPI.Workflow


struct AddGithubPipelineSheet: View {
    @ObservedObject var model: PipelineModel
    @ObservedObject var viewState: ListViewState
    @Environment(\.presentationMode) @Binding var presentation
    var authController: GithubAuthController
    @State var pipeline: Pipeline = Pipeline(name: "", feed:Pipeline.Feed(type:.github, url: ""))
    @State var owner: String = ""
    @State var repositoryList = [Repository()]
    @State var selectedRepository = Repository()
    @State var workflowList = [Workflow()]
    @State var selectedWorkflow = Workflow()
    
    var body: some View {
        VStack {
            Text("Add GitHub Actions workflow")
                .font(.headline)
            Spacer()
            HStack {
                Text("Please enter the owner (user or organisation). Press return in the owner field to fetch the repositories and workflows. If there are more than 100 entries only the 100 most recently updated will be shown. Sign into GitHub to access private repositories.")
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }

            Form {
                TextField("Owner:", text: $owner, onEditingChanged: { flag in
                    if flag == false && !owner.isEmpty {
                        repositoryList = [Repository(message: "updating list")]
                        GitHubAPI.fetchRepositories(owner: owner, token: viewState.accessToken) { newList in
                            // TODO: so much logic, this needs a test
                           let filteredNewList = newList.filter({ $0.owner?.login == owner })
                            if repositoryList.count == 1 && repositoryList[0].isMessage {
                                repositoryList = []
                            }
                            repositoryList.append(contentsOf: filteredNewList)
                            repositoryList.sort(by: { r1, r2 in r1.name.lowercased().compare(r2.name.lowercased()) == .orderedAscending })
                            if repositoryList.count == 0 {
                                repositoryList = [Repository()]
                            }
                            selectedRepository = repositoryList[0] // TODO: consider showing first response instead, i.e. newList[0]
                        }
                    }
                })
                .onChange(of: owner) { foo in
                    updatePipeline();
                }

                Picker("Repository", selection: $selectedRepository) {
                    ForEach(repositoryList) { r in
                        Text(r.name).tag(r)
                    }
                }
                .disabled(repositoryList.count == 1 && selectedRepository.isMessage)
                .onChange(of: selectedRepository) { _ in
                    updatePipeline()
                    if !selectedRepository.isMessage {
                        workflowList = [Workflow(message: "updating list")]
                        GitHubAPI.fetchWorkflows(owner: owner, repo:selectedRepository.name, token: viewState.accessToken) { newList in
                            workflowList = newList.count > 0 ? newList : [Workflow()]
                            workflowList.sort(by: { w1, w2 in w1.name.lowercased().compare(w2.name.lowercased()) == .orderedAscending })
                            selectedWorkflow = workflowList[0]
                        }
                    }
                }

                Picker("Workflow", selection: $selectedWorkflow) {
                    ForEach(workflowList) { w in
                        Text(w.name).tag(w)
                    }
                }
                .disabled(workflowList.count == 1 && selectedWorkflow.isMessage)
                .onChange(of: selectedWorkflow) { _ in
                    updatePipeline()
                }

                HStack {
                    TextField("Authentication:", text: $viewState.accessTokenDescription)
                        .disabled(true)
                    // TODO: Find out why state change doesn't trigger redraw
                    if viewState.isWaitingForToken {
                        Button("Cancel") {
                            authController.stopWaitingForToken()
                        }
                    } else {
                        Button(viewState.accessToken == nil ? "Sign in" : "Refresh") {
                            authController.signInAtGitHub()
                        }
                    }
                    Button("Review") {
                        authController.openReviewAccessPage()
                    }
                }
                .padding([.bottom])
                HStack {
                    TextField("Display name:", text: $pipeline.name)
                    Button(action: { pipeline.name = "\(selectedRepository.name) (\(selectedWorkflow.name))" }) {
                        Label("Reset", systemImage: "arrowshape.turn.up.backward")
                    }
                }
                .padding([.bottom])
            }

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
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = String(format: "/repos/%@/%@/actions/workflows/%@/runs", owner, selectedRepository.name, selectedWorkflow.filename)
        pipeline.feed.url = components.url!.absoluteString
        pipeline.name = "\(selectedRepository.name) (\(selectedWorkflow.name))"
    }

}


struct AddGithubPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AddGithubPipelineSheet(model: ViewModel())
        }
    }
}

