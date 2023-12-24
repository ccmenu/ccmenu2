/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineCommands: Commands {
    @ObservedObject var model: PipelineModel
    @State private var isShowingImporter = false
    @State private var isShowingExporter = false

    var body: some Commands {

        CommandGroup(replacing: .importExport) {
            Button("Import...") {
                isShowingImporter.toggle()
            }
            .fileImporter(isPresented: $isShowingImporter, allowedContentTypes: [.json]) { result in
               switch result {
               case .success(let fileurl):
                   print(fileurl)
               case .failure(let error):
                   print(error)
               }
            }
            Button("Export...") {
                isShowingExporter.toggle()
            }
            .keyboardShortcut("E", modifiers: [.command, .shift])
            // TODO: figure out how to implement Transferable on Pipeline
//            .fileExporter(isPresented: $isShowingExporter, item: model.pipelines, contentTypes: [.json]) { result in
//                switch result {
//                case .success(let fileurl):
//                    print(fileurl)
//                case .failure(let error):
//                    print(error)
//                }
//            }
        }
    }

 }
