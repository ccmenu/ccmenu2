/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct EditPipelineSheet: View {
    @Binding var config: PipelineSheetConfig
    @Environment(\.presentationMode) @Binding var presentation
    @State var useBasicAuth = false
    @State var credential = HTTPCredential(user: "", password: "")
    @State var name: String = ""

    var body: some View {
        VStack {
            Text("Edit Pipeline")
                .font(.headline)
                .padding(.bottom)

            if let p = config.pipeline, p.feed.type == .cctray {
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
                    config.setPipeline(nil)
                    presentation.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Apply") {
                    config.pipeline?.name = name
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .onAppear() {
                name = config.pipeline?.name ?? ""
//                if pipeline.feed.type == .cctray {
//                    if let url = URLComponents(string: pipeline.feed.url) {
//                        if let user = url.user {
//                            useBasicAuth = true
//                            credential.user = user
//                            do {
//                                if let url = url.url, let password = try Keychain().getPassword(forURL: url) {
//                                    credential.password = password
//                                }
//                            }
//                            catch {
//                                // TODO: What to do here?
//                            }
//                        }
//                    }
//                }
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
    }
}
