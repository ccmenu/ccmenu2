/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct AddGithubPipelineSheet: View {
    @ObservedObject var model: ViewModel
    @Environment(\.presentationMode) @Binding var presentation
    @State var pipeline: Pipeline = Pipeline(name: "", feedUrl: "")
    @State var owner: String = ""
    @State var repository: String = ""
    @State var workflow: String = ""

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
            }
            Divider()
                .padding()
            Form {
                HStack {
                    Text("Display name:")
                    TextField("", text: $pipeline.displayName)
                    Button(action: { pipeline.displayName = "" }) {
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
                    pipeline.feed.type = .github
                    pipeline.status = Pipeline.Status(activity: .sleeping)
                    pipeline.status.lastBuild = Build(result: .unknown)
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
        pipeline.name = String(format:"%@/%@:%@", owner, repository, workflow)
    }

}


struct AddGithubPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddGithubPipelineSheet(model: ViewModel())
        }
    }
}

