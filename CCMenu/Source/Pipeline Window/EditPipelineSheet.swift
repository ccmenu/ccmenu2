/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct EditPipelineSheet: View {
    var pipeline: Pipeline
    @ObservedObject var model: PipelineModel
    @Environment(\.presentationMode) @Binding var presentation

    var body: some View {
        VStack {
            Text("Edit Pipeline")
                .font(.headline)
            Text("missing")
            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                Button("Apply") {
//                    var p = Pipeline(name: "erikdoe/ocmock", feedUrl: "http://localhost:4567/cc.xml")
//                    p.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success))
//                    model.pipelines[editIndex] = p
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
//            AddPipelineSheet(model: makeViewModel())
        }
    }
    
    static func makeViewModel() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cctray.xml"))
        p0.status = Pipeline.Status(activity: .building, lastBuild: Build(result: .failure))
        model.pipelines = [p0]
        return model
    }

}

