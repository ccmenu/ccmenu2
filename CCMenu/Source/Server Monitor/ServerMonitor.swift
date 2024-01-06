/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine

@MainActor
class ServerMonitor {

    private var model: PipelineModel
    private var lastPipelineCount = 0
    private var subscribers: [AnyCancellable] = []

    init(model: PipelineModel) {
        self.model = model
    }
    
    public func start() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { await self.updateStatus() }
        }
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task { await self.updateStatus() }
        }
        model.$pipelines
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateStatusIfPipelineWasAdded(pipelines:))
            .store(in: &subscribers)
    }

    func updateStatusIfPipelineWasAdded(pipelines: [Pipeline]) {
        guard pipelines.count > lastPipelineCount else {
            lastPipelineCount = pipelines.count
            return
        }
        lastPipelineCount = pipelines.count
        Task { await self.updateStatus() }
    }

    func updateStatus() async {
        // TODO: Make sure that the request can happen in parallel (maybe they do already?)
        for p in model.pipelines {
            switch(p.feed.type) {
            case .cctray:
                let reader = CCTrayFeedReader(for: p)
                await reader.updatePipelineStatus()
                reader.pipelines.forEach({ model.update(pipeline: $0) })
            case .github:
                let reader = GitHubFeedReader(for: p)
                await reader.updatePipelineStatus()
                model.update(pipeline: reader.pipeline)
            }
        }
    }

}
