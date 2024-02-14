/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct AddCCTrayPipelineSheet: View {
    @ObservedObject var model: PipelineModel
    @Environment(\.presentationMode) @Binding var presentation
    @State var credential = HTTPCredential(user: "", password: "")
    @State var url: String = ""
    @StateObject private var projectList = CCTrayProjectList()
    @StateObject private var pipelineBuilder = CCTrayPipelineBuilder()

    var body: some View {
        VStack {
            Text("Add project from CCTray feed")
                .font(.headline)
                .padding(.bottom)
            Text("Enter the URL of a CCTray feed, and press return to retrieve the project list. If you receive an error message try opening the URL in a web browser. If the browser doesn't show an XML document in [cctray format](https://cctray.org/v1/) then the feed URL is incorrect.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            Form {
                TextField("Authentication:", text: $credential.user, prompt: Text("user"))
                // TODO: figure out how to put user and password into same row without breaking the layout
                SecureField("", text: $credential.password, prompt: Text("password"))
                    .padding(.bottom)

                TextField("Server:", text: $url, prompt: Text("URL"))
                    .autocorrectionDisabled(true)
                    .onSubmit {
                        if !url.isEmpty {
                            Task {
                                let c = !credential.isEmpty ? credential : nil
                                await projectList.updateProjects(url: $url, credential: c)
                            }
                        }
                    }

                Picker("Project:", selection: $projectList.selected) {
                    ForEach(projectList.items) { p in
                        Text(p.name).tag(p)
                    }
                }
                .disabled(!projectList.selected.isValid)
                .onChange(of: projectList.selected) { _ in
                    pipelineBuilder.updateName(project: projectList.selected)
                }
                .padding(.bottom)

                HStack {
                    TextField("Display name:", text: $pipelineBuilder.name)
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        pipelineBuilder.updateName(project: projectList.selected)
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
                    let urlWithUser = CCTrayPipelineBuilder.setUser(credential.user, inURL: url)
                    let keychainHelper = KeychainHelper()
                    do {
                        try keychainHelper.setPassword(credential.password, forURL: urlWithUser)
                    } catch {
                        // TODO: Figure out what to do here – so many errors...
                    }
                    let p = pipelineBuilder.makePipeline(feedUrl: urlWithUser, name: projectList.selected.name)
                    model.add(pipeline: p)
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!projectList.selected.isValid)
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
    }
}


struct AddCCTrayPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddCCTrayPipelineSheet(model: PipelineModel())
        }
    }
}

