/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


final class PipelineModel: ObservableObject {

    @Published var pipelines: [Pipeline] { didSet { updateSettings() } }
    @Published var lastStatusChange: StatusChange?
    private var timer: Timer? = nil

    init() {
        pipelines = []
    }

    func update(pipeline: Pipeline) {
        guard let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) else { return }
        let change = StatusChange(pipeline: pipeline, previousStatus: pipelines[idx].status)
        pipelines[idx] = pipeline
        pipelines[idx].lastUpdated = Date()
        if change.kind != .noChange {
            lastStatusChange = change
        }
        let buildingCount = pipelines.filter({ $0.status.activity == .building }).count
        if (buildingCount > 0) && (timer == nil) {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.objectWillChange.send()
            }
        }
        if (buildingCount == 0) && (timer != nil) {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @discardableResult
    func add(pipeline newPipeline: Pipeline) -> Bool {
        if pipelines.contains(where: { $0.id == newPipeline.id }) {
            return false
        }
        pipelines.append(newPipeline)
        return true
    }

    func remove(pipelineId: String) {
        guard let idx = pipelines.firstIndex(where: { $0.id == pipelineId }) else { return }
        pipelines.remove(at: idx)
    }

    private func updateSettings() {
        // TODO: this is called, too, every time the status gets updated...
        savePipelinesToUserDefaults()
    }


    func loadPipelinesFromUserDefaults() {
        if let references = UserDefaults.active.array(forKey: DefaultsKey.pipelineList.rawValue) as? [[String : String]] {
            pipelines = references.compactMap({ Pipeline(reference: $0) })
        }
        else if let references = UserDefaults.active.array(forKey: "Projects") as? [[String : String]]  {
            pipelines = references.compactMap({ Pipeline(legacyReference: $0) })
        }
        else {
            pipelines = [ Pipeline(name: "ccmenu2 | build-and-test", feed: Pipeline.Feed(type: .github, url: "https://api.github.com/repos/ccmenu/ccmenu2/actions/workflows/build-and-test.yaml/runs?branch=main")) ]
        }
        // TODO: Remove before App Store release
        UserDefaults.active.removeObject(forKey: "GitHubToken")
    }

    private func savePipelinesToUserDefaults() {
        let references = pipelines.map({ $0.reference() })
        UserDefaults.active.set(references, forKey: DefaultsKey.pipelineList.rawValue)
    }

    func loadPipelinesFromFile(_ filename: String) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filename))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            pipelines = try decoder.decode([Pipeline].self, from: data)
        } catch {
            fatalError("Couldn't load pipelines from \(filename): \(error)")
        }
    }
    
    func importPipelinesFromFile(url: URL) -> Error? {
        do {
            let document = try PipelineDocument(url: url)
            document.pipelines.forEach({ add(pipeline: $0) })
            return nil
        }
        catch {
            return error
        }
    }
    
    func exportPipelinesToDocument(selection: Set<String>) -> PipelineDocument {
        let pipelines = selection.isEmpty ? pipelines : pipelines.filter({ selection.contains($0.id )})
        return PipelineDocument(pipelines: pipelines)
    }

}

