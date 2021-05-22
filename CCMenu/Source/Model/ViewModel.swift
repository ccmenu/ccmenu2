/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


final class ViewModel: ObservableObject {
    
    @Published var pipelines: [Pipeline] = []
    
    init() {
        if let filename = UserDefaults.standard.string(forKey: "loadTestData") {
            pipelines = load(filename)
        }
        
//        if let legacyProjects = UserDefaults.standard.array(forKey: "Projects") as? Array<Dictionary<String, String>> {
//            for project in legacyProjects {
//                if let name = project["projectName"], let feedUrl = project["serverUrl"] {
//                    pipelines.append(Pipeline(name: name, feedUrl: feedUrl))
//                }
//            }
//        }
    }
    
    func update(pipeline: Pipeline) {
        if let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) {
            pipelines[idx] = pipeline
        }
    }
    
    private func load<T: Decodable>(_ filename: String) -> T {
        let data: Data

        do {
            data = try Data(contentsOf: URL(fileURLWithPath: filename))
        } catch {
            fatalError("Couldn't load test data from \(filename):\n\(error)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
        }
    }

}
