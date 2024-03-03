/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine

@MainActor
class ServerMonitor {

    @AppStorage(.pollInterval) var pollInterval: Int = 15
    private var model: PipelineModel
    private var subscribers: [AnyCancellable] = []

    init(model: PipelineModel) {
        self.model = model
    }
    
    public func start() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { await self.updateStatus(pipelines: self.model.pipelines) }
        }
        // TODO: Later changes to variable will not result in rescheduling of timer
        Timer.scheduledTimer(withTimeInterval: Double(pollInterval), repeats: true) { _ in
            Task { await self.updateStatus(pipelines: self.model.pipelines) }
        }
        model.$pipelines
            .sink(receiveValue: updateStatusIfPipelineWasAdded(pipelines:))
            .store(in: &subscribers)
    }

    func updateStatusIfPipelineWasAdded(pipelines: [Pipeline]) {
        guard pipelines.count > model.pipelines.count else {
            return
        }
        let newPipelines = Set(pipelines).subtracting(Set(model.pipelines))
        Task { await self.updateStatus(pipelines: Array(newPipelines)) }
    }

    private func updateStatus(pipelines: [Pipeline]) async {
        // TODO: Make sure that the request can happen in parallel (maybe they do already?)
        for p in pipelines {
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
