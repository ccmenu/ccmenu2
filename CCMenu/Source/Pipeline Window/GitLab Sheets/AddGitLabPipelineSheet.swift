/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct AddGitLabPipelineSheet: View {
    @Binding var config: PipelineSheetConfig
    @Environment(\.presentationMode) @Binding var presentation
    @StateObject private var owner = DebouncedText()
    @StateObject private var project = DebouncedText()
    @StateObject private var projectList = GitLabProjectList()
    @StateObject private var branch = DebouncedText()
    @StateObject private var branchList = GitLabBranchList()
    @StateObject private var builder = GitLabPipelineBuilder()
    @State private var selectedProjectId: Int? = nil
    
    var body: some View {
        VStack {
            Text("Add GitLab pipeline")
                .font(.headline)
                .padding(.bottom)
            Text("Enter a GitLab user or group name to fetch projects. If there are many projects only the most recently updated will be shown.\n\nAuthentication is not required for public projects.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            Form {
                TextField("User or Group:", text: $owner.input, prompt: Text("user or group name"))
                    .accessibilityIdentifier("Owner field")
                    .autocorrectionDisabled(true)
                    .onReceive(owner.$text) { t in
                        if t.isEmpty {
                            projectList.clearProjects()
                        } else {
                            Task {
                                await projectList.updateProjects(name: t, token: nil)
                            }
                        }
                    }
                    .onSubmit {
                        owner.takeInput()
                    }
                
                LabeledContent("Project:") {
                    ComboBox(items: projectList.items.map({ $0.displayName }), text: $project.input)
                        .accessibilityIdentifier("Project combo box")
                        .disabled(owner.text.isEmpty || projectList.items.isEmpty || !projectList.items[0].isValid)
                        .onReceive(project.$text) { t in
                            if let selectedProject = projectList.items.first(where: { $0.displayName == t }) {
                                builder.project = selectedProject
                                builder.setDefaultName()
                                
                                if selectedProject.isValid {
                                    selectedProjectId = selectedProject.id
                                    Task {
                                        await branchList.updateBranches(projectId: String(selectedProject.id), token: nil)
                                    }
                                } else {
                                    selectedProjectId = nil
                                    branchList.clearBranches()
                                }
                            }
                        }
                        .onSubmit {
                            project.takeInput()
                            if let selectedProject = projectList.items.first(where: { $0.displayName == project.text }) {
                                if selectedProject.isValid {
                                    Task {
                                        await branchList.updateBranches(projectId: String(selectedProject.id), token: nil)
                                    }
                                }
                            }
                        }
                        .onReceive(projectList.$items) { items in
                            if let firstValidProject = items.first(where: { $0.isValid }) {
                                project.text = firstValidProject.displayName
                                builder.project = firstValidProject
                                builder.setDefaultName()
                                
                                // Load branches for the automatically selected project
                                Task {
                                    await branchList.updateBranches(projectId: String(firstValidProject.id), token: nil)
                                }
                            }
                        }
                        .onSubmit {
                            project.takeInput()
                        }
                }
                
                LabeledContent("Branch:") {
                    ComboBox(items: branchList.items.map({ $0.name }), text: $branch.input)
                        .accessibilityIdentifier("Branch combo box")
                        .disabled(builder.project == nil || !builder.project!.isValid)
                        .onReceive(branch.$text) { t in
                            builder.branch = t
                        }
                        .onReceive(branchList.$items) { items in
                            if !items.isEmpty && items[0].isValid {
                                branch.text = items.first?.name ?? ""
                            }
                        }
                        .onSubmit {
                            branch.takeInput()
                        }
                }
                .padding(.bottom)
                
                HStack {
                    TextField("Display name:", text: $builder.name)
                        .accessibilityIdentifier("Display name field")
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        builder.setDefaultName()
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
                    Task {
                        if let p = await builder.makePipeline(token: nil) {
                            config.setPipeline(p)
                            presentation.dismiss()
                        }
                        // TODO: show error
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!builder.canMakePipeline)
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
    }
}

struct AddGitLabPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AddGitLabPipelineSheet(config: $config)
        }
    }
}
