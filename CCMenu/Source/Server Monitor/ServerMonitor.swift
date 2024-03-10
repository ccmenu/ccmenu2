/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine

@MainActor
class ServerMonitor {

    private var model: PipelineModel
    private var subscribers: [AnyCancellable] = []

    init(model: PipelineModel) {
        self.model = model
    }
    
    public func start() {
        scheduleNextPoll(after: 0.1)
        model.$pipelines
            .sink(receiveValue: updateStatusIfPipelineWasAdded(pipelines:))
            .store(in: &subscribers)
    }

    private var pollInterval: Int {
        let v = UserDefaults.active.integer(forKey: DefaultsKey.pollInterval.rawValue)
        return (v > 0) ? v : 15
    }

    private func scheduleNextPoll(after seconds: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            Task { await self.updateStatus(pipelines: self.model.pipelines) }
        }
    }

    func updateStatusIfPipelineWasAdded(pipelines: [Pipeline]) {
        guard pipelines.count > model.pipelines.count else {
            return
        }
        let newPipelines = Set(pipelines).subtracting(Set(model.pipelines))
        Task { await self.updateStatus(pipelines: Array(newPipelines)) }
    }

    private func updateStatus(pipelines: [Pipeline]) async {
        scheduleNextPoll(after: Double(pollInterval))
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
