/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


final class ModelData: ObservableObject {
    @Published var pipelines: [Pipeline] = []

    
    init() {
        loadTestDataIfRequested()
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