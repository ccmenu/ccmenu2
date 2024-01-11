/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


final class PipelineModel: ObservableObject {

    @Published var pipelines: [Pipeline] { didSet { updateSettings() } }

    init() {
        pipelines = []
    }

    func update(pipeline: Pipeline) {
        guard let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) else {
            debugPrint("trying to update unknown pipeline \(pipelines.debugDescription)")
            return
        }
        pipelines[idx] = pipeline
    }
    
    @discardableResult
    func add(pipeline newPipeline: Pipeline) -> Bool {
        guard !pipelines.contains(where: {$0.id == newPipeline.id}) else {
            return false
        }
        pipelines.append(newPipeline)
        return true
    }

    private func updateSettings() {
        // TODO: this is called, too, every time the status gets updated...
        let list = pipelines.map({ $0.asDictionaryForPersisting() })
        UserDefaults.active?.set(list, forKey: DefaultsKey.pipelineList.rawValue)
    }


    func loadPipelinesFromUserDefaults() {
        if let list = UserDefaults.active?.array(forKey: DefaultsKey.pipelineList.rawValue) as? Array<Dictionary<String, String>>, !list.isEmpty  {
            pipelines = list.compactMap(Pipeline.fromPersistedDictionary)
        }
        else {
            loadPipelinesFromLegacyDefaults()
            addCCMenu2Pipeline()
        }
    }


    private func loadPipelinesFromLegacyDefaults() {
        guard  let legacyProjects = UserDefaults.standard.array(forKey: "Projects") as? Array<Dictionary<String, String>> else {
            return
        }
        for project in legacyProjects {
            if let projectName = project["projectName"], let serverUrl = project["serverUrl"] {
                let name = project["displayName"] ?? projectName
                pipelines.append(Pipeline(name: name, feed: Pipeline.Feed(type: .cctray, url: serverUrl, name: projectName)))
            }
        }
    }

    private func addCCMenu2Pipeline() {
        let p0 = Pipeline(name: "ccmenu2 (build-and-test)", feed: Pipeline.Feed(type: .github, url: "https://api.github.com/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs"))
        pipelines.append(p0)
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

