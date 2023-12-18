/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


final class GitHubWorkflowSelectionState: ObservableObject {
    @Published var owner: String = ""
    @Published var repositoryList = [GitHubRepository()] { didSet { repository = repositoryList[0] }}
    @Published var repository = GitHubRepository()
    @Published var workflowList = [GitHubWorkflow()] { didSet { workflow = workflowList[0] }}
    @Published var workflow = GitHubWorkflow()
}

final class GitHubAuthState: ObservableObject {
    @Published var accessToken: String?
    @Published var accessTokenDescription: String = ""
    @Published var isWaitingForToken: Bool = false
}


struct AddGithubPipelineSheet: View {
    var controller: GitHubSheetController
    @ObservedObject var selectionState: GitHubWorkflowSelectionState
    @ObservedObject var authState: GitHubAuthState
    @EnvironmentObject var settings: UserSettings
    @Environment(\.presentationMode) @Binding var presentation
    @State var pipelineName: String = ""

    var body: some View {
        VStack {
            Text("Add GitHub Actions workflow")
                .font(.headline)
            Spacer()
            HStack {
                Text("Please enter the owner (user or organisation). Press return in the owner field to fetch the repositories and workflows. If there are many entries only the most recently updated will be shown. Sign into GitHub to access private repositories.")
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }

            Form {
                HStack {
                    TextField("Authentication:", text: $authState.accessTokenDescription)
                        .truncationMode(.tail)
                        .disabled(true)
                    if authState.isWaitingForToken {
                        Button("Cancel") {
                            controller.stopWaitingForToken()
                        }
                    } else {
                        Button(authState.accessToken == nil ? "Sign in" : "Refresh") {
                            controller.signInAtGitHub()
                        }
                    }
                    Button("Review") {
                        controller.openReviewAccessPage()
                    }
                }
                .padding([.top, .bottom])

                TextField("Owner:", text: $selectionState.owner, onEditingChanged: { flag in
                    if flag == false && !selectionState.owner.isEmpty {
                        controller.fetchRepositories()
                    }
                })
                .onChange(of: selectionState.owner) { foo in
                    pipelineName = controller.defaultPipelineName()
                }

                Picker("Repository", selection: $selectionState.repository) {
                    ForEach(selectionState.repositoryList) { r in
                        Text(r.name).tag(r)
                    }
                }
                .disabled(!selectionState.repository.isValid)
                .onChange(of: selectionState.repository) { _ in
                    pipelineName = controller.defaultPipelineName()
                    if selectionState.repository.isValid {
                        controller.fetchWorkflows()
                    } else {
                        controller.clearWorkflows()
                    }
                }

                Picker("Workflow", selection: $selectionState.workflow) {
                    ForEach(selectionState.workflowList) { w in
                        Text(w.name).tag(w)
                    }
                }
                .disabled(!selectionState.workflow.isValid)
                .onChange(of: selectionState.workflow) { _ in
                    pipelineName = controller.defaultPipelineName()
                }

                HStack {
                    TextField("Display name:", text: $pipelineName)
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        pipelineName = controller.defaultPipelineName()
                    }
                }
                .padding([.bottom])
            }

            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                Button("Apply") {
                    // TODO: It's a bit inconsisten that we pass the name when everything else is in shared state
                    controller.addPipeline(name: pipelineName)
                    presentation.dismiss()
                }
                .disabled(pipelineName.isEmpty || !selectionState.repository.isValid || !selectionState.workflow.isValid)
            }
        }
        .frame(width: 500, height: 300)
        .padding()
        .onAppear() {
            if let token = settings.cachedGitHubToken {
                authState.accessToken = token
                authState.accessTokenDescription = token
            }
        }
        .onDisappear() {
            if let token = authState.accessToken {
                settings.cachedGitHubToken = token
            }
        }
    }
    
}


struct AddGithubPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AddGithubPipelineSheet(model: ViewModel())
        }
    }
}

