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
    }

    func update(pipeline: Pipeline) {
        if let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) {
            pipelines[idx] = pipeline
        }
    }

    func loadPipelinesFromUserDefaults() {
        if let legacyProjects = UserDefaults.standard.array(forKey: "Projects") as? Array<Dictionary<String, String>> {
            for project in legacyProjects {
                if let name = project["projectName"], let feedUrl = project["serverUrl"] {
                    if !name.hasPrefix("erikdoe/") {
                        pipelines.append(Pipeline(name: name, feedUrl: feedUrl))
                    }
                }
            }
        }
    }

    func loadPipelinesFromFile(_ filename: String) {
        let data: Data

        do {
            data = try Data(contentsOf: URL(fileURLWithPath: filename))
        } catch {
            fatalError("Couldn't load test data from \(filename):\n\(error)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                if let date = ISO8601DateFormatter().date(from: string) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date string \(string)")
            }
            pipelines = try decoder.decode([Pipeline].self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename) as [Pipeline]:\n\(error)")
        }
    }

}

