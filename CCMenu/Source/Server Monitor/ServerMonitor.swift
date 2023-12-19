/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine

class ServerMonitor: FeedReaderDelegate {
    
    @Published var model: PipelineModel
    private var lastPipelineCount = 0
    private var subscribers: [AnyCancellable] = []


    init(model: PipelineModel) {
        self.model = model
        model.$pipelines
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: pollIfPipelineWasAdded(pipelines:))
            .store(in: &subscribers)
    }
    
    public func start() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in self.pollServers() }
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in self.pollServers()}
    }

    func pollIfPipelineWasAdded(pipelines: [Pipeline]) {
        if pipelines.count > lastPipelineCount {
            lastPipelineCount = pipelines.count
            pollServers()
        }
        lastPipelineCount = pipelines.count
    }

    func pollServers() {
        model.pipelines.forEach({ updateStatus(pipeline: $0) })
    }

    func updateStatus(pipeline p: Pipeline) {
        var r: FeedReader
        switch(p.feed.type) {
        case .cctray: r = CCTrayFeedReader(for: p)
        case .github: r = GithubFeedReader(for: p)
        }
        r.delegate = self
        r.updatePipelineStatus()
    }

    func feedReader(_ reader: FeedReader, didUpdate pipeline: Pipeline) {
//        print("Received update for pipeline \(pipeline)")
        model.update(pipeline: pipeline)
    }
    
}
