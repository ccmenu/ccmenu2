/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


struct AddGitHubPipelineSheet: View {
    @ObservedObject var model: PipelineModel
    @Environment(\.presentationMode) @Binding var presentation
    @State private var owner = ""
    @StateObject private var repositoryList = GitHubRepositoryList()
    @StateObject private var workflowList = GitHubWorkflowList()
    @StateObject private var pipelineBuilder = GitHubPipelineBuilder()
    @StateObject private var authenticator = GitHubAuthenticator()

    var body: some View {
        VStack {
            Text("Add GitHub Actions workflow")
                .font(.headline)
                .padding(.bottom)
            Text("Press return in the owner field to fetch repositories and workflows. If there are many entries only the most recently updated will be shown. Sign into GitHub to access private repositories.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            Form {
                HStack {
                    TextField("Authentication:", text: $authenticator.tokenDescription)
                        .accessibilityIdentifier("Token field")
                        .truncationMode(.tail)
                        .disabled(true)
                    if authenticator.isWaitingForToken {
                        Button("Cancel") {
                            authenticator.cancelSignIn()
                        }
                    } else {
                        Button(authenticator.token == nil ? "Sign in" : "Refresh") {
                            Task { await authenticator.signInAtGitHub() }
                        }
                    }
                    Button("Review") {
                        authenticator.openApplicationsOnWebsite()
                    }
                }
                .padding(.bottom)

                TextField("Owner:", text: $owner, prompt: Text("user or organisation"))
                .accessibilityIdentifier("Owner field")
               // TODO: figure out why .prefersDefaultFocus(in:) doesn't work
                .autocorrectionDisabled(true)
                .onSubmit {
                    if !owner.isEmpty {
                        Task {
                            await repositoryList.updateRepositories(owner: owner, token: authenticator.token)
                        }
                    }
                }

                Picker("Repository", selection: $repositoryList.selected) {
                    ForEach(repositoryList.items) { r in
                        Text(r.name).tag(r)
                    }
                }
                .accessibilityIdentifier("Repository picker")
                .disabled(!repositoryList.selected.isValid)
                .onChange(of: repositoryList.selected) { _ in
                    pipelineBuilder.updateName(repository: repositoryList.selected, workflow: workflowList.selected)
                    if repositoryList.selected.isValid {
                        Task {
                            await workflowList.updateWorkflows(owner: owner, repository: repositoryList.selected.name, token: authenticator.token)
                        }
                    } else {
                        workflowList.clearWorkflows()
                    }
                }

                Picker("Workflow", selection: $workflowList.selected) {
                    ForEach(workflowList.items) { w in
                        Text(w.name).tag(w)
                    }
                }
                .accessibilityIdentifier("Workflow picker")
                .disabled(!workflowList.selected.isValid)
                .onChange(of: workflowList.selected) { _ in
                    pipelineBuilder.updateName(repository: repositoryList.selected, workflow: workflowList.selected)
                }
                .padding(.bottom)

                HStack {
                    TextField("Display name:", text: $pipelineBuilder.name)
                        .accessibilityIdentifier("Display name field")
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        pipelineBuilder.updateName(repository: repositoryList.selected, workflow: workflowList.selected)
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
                    let p = pipelineBuilder.makePipeline(owner: owner)
                    model.add(pipeline: p)
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pipelineBuilder.name.isEmpty || !repositoryList.selected.isValid || !workflowList.selected.isValid)
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
        .onAppear() {
            do {
                let token = try Keychain().getToken(forService: "GitHub")
                authenticator.token = token
                authenticator.tokenDescription = token ?? ""
            } catch {
            }
        }
        .onDisappear() {
            guard let token = authenticator.token else { return }
            do {
                try Keychain().setToken(token, forService: "GitHub")
            } catch {
                // TODO: Figure out what to do here – so many errors...
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

