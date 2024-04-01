/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct EditPipelineSheet: View {
    @State var pipeline: Pipeline
    @State var useBasicAuth = false
    @State var credential = HTTPCredential(user: "", password: "")
    @State var name: String = ""
    @ObservedObject var model: PipelineModel
    @Environment(\.presentationMode) @Binding var presentation

    var body: some View {
        VStack {
            Text("Edit Pipeline")
                .font(.headline)
                .padding(.bottom)

            if pipeline.feed.type == .cctray {
                CCTrayAuthView(useBasicAuth: $useBasicAuth, credential: $credential)
                .padding(.bottom)
            }

            Form {
                TextField("Name:", text: $name)
                    .accessibilityIdentifier("Name field")
            }
            .padding(.bottom)
            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Apply") {
                    pipeline.name = name
                    model.update(pipeline: pipeline)
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pipeline.name.isEmpty)
            }
            .onAppear() {
                name = pipeline.name
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
    }
}
