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
    private var networkMonitor: NetworkMonitor
    private var subscribers: [AnyCancellable] = []
    private var lastPoll = Date.distantPast

    init(model: PipelineModel) {
        self.model = model
        self.networkMonitor = NetworkMonitor()
    }
    
    private var pollInterval: Double {
        if networkMonitor.isExpensiveConnection || networkMonitor.isLowDataConnection {
            let v = UserDefaults.active.integer(forKey: DefaultsKey.pollIntervalLowData.rawValue)
            return (v != 0) ? Double(v) : 300
        } else {
            let v = UserDefaults.active.integer(forKey: DefaultsKey.pollInterval.rawValue)
            return (v > 0) ? Double(v) : 10
        }
    }

    public func start() {
        networkMonitor.start()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { await self.updateStatus(pipelines: self.model.pipelines) }
        }
        Timer.scheduledTimer(withTimeInterval: min(pollInterval, 5.0), repeats: true) { _ in
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
        newPipelines.forEach({ p in Task { await updateStatus(pipeline: p) } })
    }

    func updateStatus(pipelines: [Pipeline]) async {
        if Date().timeIntervalSince(lastPoll).rounded() < pollInterval {
            return
        }
        lastPoll = Date()
        for p in pipelines {
            await updateStatus(pipeline: p)
        }
    }

    private func updateStatus(pipeline p: Pipeline) async {
        if !networkMonitor.isConnected && pipelineIsRemote(p) && pipelineHasSomeStatus(p) {
            return
        }
        var p = p
        if let pauseUntil = p.feed.pauseUntil {
            if Date().timeIntervalSince1970 <= Double(pauseUntil) {
                return
            }
            p.feed.clearPauseUntil()
        }
        // TODO: Multiple request will pile up if requests take longer than poll intervall
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

    private func pipelineIsRemote(_ p: Pipeline) -> Bool {
        if let url = URL(string: p.feed.url), url.host() != "localhost" {
            return true
        }
        return false
    }

    private func pipelineHasSomeStatus(_ p: Pipeline) -> Bool {
        return (p.status.lastBuild != nil || p.connectionError != nil)
    }

}
