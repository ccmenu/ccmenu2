/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


final class ViewModel: ObservableObject {
    @Published var pipelines: [Pipeline] = []
    @Published var selectionIds: Set<String> = Set()

    
    init() {
        loadTestDataIfRequested()
    }
    
    init(withPreviewData: Bool) {
        if withPreviewData {
            setupPreviewData()
        }
    }
    
    private func loadTestDataIfRequested() {
        let argv = ProcessInfo.init().arguments
        if let idx = argv.firstIndex(of: "-loadTestData") {
            guard argv.count > idx + 1 else {
                fatalError("Missing filename for -loadTestData")
            }
            pipelines = load(argv[idx + 1])
        }
    }
    
    private func setupPreviewData() {
        let p0 = Pipeline(
            name: "connectfour",
            feedUrl: "http://localhost:4567/cc.xml",
            status: Pipeline.Status(buildResult: .failure, pipelineActivity: .building))
        pipelines.append(p0)
        let p1 = Pipeline(
            name: "erikdoe/ccmenu",
            feedUrl: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml",
            status: Pipeline.Status(buildResult: .success, pipelineActivity: .sleeping))
        pipelines.append(p1)
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
