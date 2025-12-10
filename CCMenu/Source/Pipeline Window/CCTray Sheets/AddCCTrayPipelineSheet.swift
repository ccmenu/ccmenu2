/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

enum ImportMode: String, CaseIterable {
    case singleProject = "Single Project"
    case allProjects = "All Projects"
}

struct AddCCTrayPipelineSheet: View {
    @Binding var config: PipelineSheetConfig
    @Environment(\.presentationMode) @Binding var presentation
    @State var useBasicAuth = false
    @State var credential = HTTPCredential(user: "", password: "")
    @State var importMode: ImportMode = .singleProject
    @State var removeDeletedPipelines = true
    @StateObject private var projectList = CCTrayProjectList()
    @StateObject private var builder = CCTrayPipelineBuilder()
    @ObservedObject private var dynamicFeedSourceModel = DynamicFeedSourceModel.shared

    var body: some View {
        VStack {
            Text("Add project from CCTray feed")
                .font(.headline)
                .padding(.bottom)
            Text("Enter the URL of a CCTray feed, and press return to retrieve the project list. If you receive an error message try opening the URL in a web browser. If the browser doesn't show an XML document in [cctray format](https://cctray.org/v1/) then the feed URL is incorrect.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)

            CCTrayAuthView(useBasicAuth: $useBasicAuth, credential: $credential)
            .padding(.bottom)

            Form {
                TextField("Server:", text: $builder.feedUrl, prompt: Text("URL"))
                    .accessibilityIdentifier("Server URL field")
                    .autocorrectionDisabled(true)
                    .onSubmit {
                        if !builder.feedUrl.isEmpty {
                            Task { await projectList.updateProjects(url: $builder.feedUrl, credential: credentialOptional) }
                        }
                    }
                
                Picker("Import:", selection: $importMode) {
                    ForEach(ImportMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("Import mode picker")
                .padding(.bottom, 4)
                
                if importMode == .singleProject {
                    Picker("Project:", selection: $projectList.selected) {
                        ForEach(projectList.items) { p in
                            Text(p.name).tag(p)
                        }
                    }
                    .accessibilityIdentifier("Project picker")
                    .disabled(!projectList.selected.isValid)
                    .onChange(of: projectList.selected) { _ in
                        builder.project = projectList.selected
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
                } else {
                    Picker("On removal:", selection: $removeDeletedPipelines) {
                        Text("Keep pipelines").tag(false)
                        Text("Remove pipelines").tag(true)
                    }
                    .accessibilityIdentifier("Removal behavior picker")
                    .padding(.bottom)
                    
                    Text("All projects will be imported and kept in sync. When projects are removed from the feed, pipelines will be kept or removed based on your selection above.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom)
                }
            }

            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Apply") {
                    if importMode == .allProjects {
                        addDynamicFeedSource()
                    } else {
                        let p = builder.makePipeline(credential: credentialOptional)
                        config.setPipeline(p)
                    }
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(importMode == .allProjects ? !canAddDynamicFeed : !builder.canMakePipeline)
            }
        }
        .frame(minWidth: 450)
        .frame(idealWidth: 500)
        .padding()
    }

    private var credentialOptional: HTTPCredential? {
        (useBasicAuth && !credential.isEmpty) ? credential : nil
    }
    
    private var canAddDynamicFeed: Bool {
        guard !builder.feedUrl.isEmpty else { return false }
        var urlString = builder.feedUrl
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        return URL(string: urlString) != nil
    }
    
    private func addDynamicFeedSource() {
        var urlString = builder.feedUrl
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        guard let url = URL(string: urlString) else { return }
        
        var source = DynamicFeedSource(url: url)
        source.removeDeletedPipelines = removeDeletedPipelines
        dynamicFeedSourceModel.add(source: source)
        
        // Trigger an immediate sync
        NotificationCenter.default.post(name: .dynamicFeedSyncRequested, object: nil)
    }
    
}


struct AddCCTrayPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AddCCTrayPipelineSheet(model: PipelineModel())
        }
    }
}

