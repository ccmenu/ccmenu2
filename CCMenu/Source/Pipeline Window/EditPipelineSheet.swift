/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct EditPipelineSheet: View {
    @ObservedObject var model: ViewModel
    @Environment(\.presentationMode) @Binding var presentation
    let editIndex: Int
    var pipeline: Pipeline

    init(model: ViewModel, editIndex: Int) {
        self.model = model
        self.editIndex = editIndex
        self.pipeline = model.pipelines[editIndex]
    }
    
    var body: some View {
        VStack {
            Text("Edit Pipeline")
                .font(.headline)
            Text("\(pipeline.name)")
            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                Button("Apply") {
                    var p = Pipeline(name: "erikdoe/ocmock", feedUrl: "http://localhost:4567/cc.xml")
                    p.activity = .sleeping
                    p.lastBuild = Pipeline.Build(result: .success)
                    model.pipelines[editIndex] = p
                    presentation.dismiss()
                }
                .buttonStyle(DefaultButtonStyle())
            }
        }
        .padding(EdgeInsets(top: 10, leading:10, bottom: 10, trailing: 10))
    }
}


struct EditPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddPipelineSheet(model: makeViewModel())
        }
    }
    
    static func makeViewModel() -> ViewModel {
        let model = ViewModel()

        var p0 = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cctray.xml")
        p0.activity = .building
        p0.lastBuild = Pipeline.Build(result: .failure)
        model.pipelines = [p0]
        return model
    }

}

