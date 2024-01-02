/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


struct AddGithubPipelineSheet: View {
    var controller: GitHubSheetController
    @ObservedObject var selectionState: GitHubWorkflowState
    @ObservedObject var authState: GitHubAuthState
    @EnvironmentObject var settings: UserSettings
    @Environment(\.presentationMode) @Binding var presentation

    var body: some View {
        VStack {
            Text("Add GitHub Actions workflow")
                .font(.headline)
                .padding(.bottom)
            Text("Press return in the owner field to fetch repositories and workflows. If there are many entries only the most recently updated will be shown. Sign into GitHub to access private repositories.")
                .lineLimit(3...10)
                .multilineTextAlignment(.leading)
                .frame(idealWidth: 400)
                .padding(.bottom)

            Form {
                HStack {
                    TextField("Authentication:", text: $authState.tokenDescription)
                        .truncationMode(.tail)
                        .disabled(true)
                    if authState.isWaitingForToken {
                        Button("Cancel") {
                            controller.stopWaitingForToken()
                        }
                    } else {
                        Button(authState.token == nil ? "Sign in" : "Refresh") {
                            controller.signInAtGitHub()
                        }
                    }
                    Button("Review") {
                        controller.openReviewAccessPage()
                    }
                }
                .padding(.bottom)

                TextField("Owner:", text: $selectionState.owner, prompt: Text("user or organisation"))
                // TODO: figure out why .prefersDefaultFocus(in:) doesn't work
                .autocorrectionDisabled(true)
                .onChange(of: selectionState.owner) { _ in
                    controller.resetName()
                }
                .onSubmit {
                    if !selectionState.owner.isEmpty {
                        controller.fetchRepositories()
                    }
                }

                Picker("Repository", selection: $selectionState.repository) {
                    ForEach(selectionState.repositoryList) { r in
                        Text(r.name).tag(r)
                    }
                }
                .disabled(!selectionState.repository.isValid)
                .onChange(of: selectionState.repository) { _ in
                    controller.resetName()
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
                    controller.resetName()
                }
                .padding(.bottom)

                HStack {
                    TextField("Display name:", text: $selectionState.name)
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        controller.resetName()
                    }
                }
                .padding(.bottom)
            }

            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Apply") {
                    controller.addPipeline()
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectionState.name.isEmpty || !selectionState.repository.isValid || !selectionState.workflow.isValid)
            }
        }
        .frame(minWidth: 405)
        .padding()
        .onAppear() {
            if let token = settings.cachedGitHubToken {
                authState.token = token
                authState.tokenDescription = token
            }
        }
        .onDisappear() {
            if let token = authState.token {
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

