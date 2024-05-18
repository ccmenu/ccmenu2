/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct EditPipelineSheet: View {
    @Binding var config: PipelineSheetConfig
    @Environment(\.presentationMode) @Binding var presentation
    @State var name: String = ""

    var body: some View {
        VStack {
            Text("Edit Pipeline")
                .font(.headline)
                .padding(.bottom)
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
                    if var p = config.pipeline {
                        p.name = name
                        config.setPipeline(p)
                    }
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .onAppear() {
                name = config.pipeline?.name ?? ""
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
    }

}
