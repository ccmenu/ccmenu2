/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct AddCCTrayPipelineSheet: View {
    @ObservedObject var model: ViewModel
    @Environment(\.presentationMode) @Binding var presentation
    @State var url: String = ""
    @State var projectName: String = ""
    @State var displayName: String = ""

    var body: some View {
        VStack {
            Text("Add project from CCTray feed")
                .font(.headline)
            Spacer()
            HStack {
                Text("Please enter the URL for a CCTray feed and the name of the project (pipeline). If you are unsure about the project name open the feed URL in a web browser and look for the project name in the XML document that's shown. If the browser does not show an XML document, the feed URL is incorrect.")
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            Form {
                HStack {
                    Text("URL:")
                    TextField("", text: $url)
                }
                HStack {
                    Text("Project name:")
                    TextField("", text: $projectName)
                }
                .onChange(of: projectName) { _ in displayName = projectName }
            }
            Divider()
                .padding()
            HStack {
                Text("Name to display this pipeline. Defaults to the project name given above but can be changed as needed. ")
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Form {
                HStack {
                    Text("Display name:")
                    TextField("", text: $displayName)
                    Button(action: { displayName = projectName }) {
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
                    var pipeline: Pipeline = Pipeline(name: displayName, feed:Pipeline.Feed(type:.cctray, url: url, name: projectName))
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
}


struct AddCCTrayPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddCCTrayPipelineSheet(model: ViewModel())
        }
    }
}

