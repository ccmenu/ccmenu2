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

    func start() {
        networkMonitor.start()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { await self.updateStatusIfPollTimeHasBeenReached() }
        }
        Timer.scheduledTimer(withTimeInterval: min(pollInterval, 5.0), repeats: true) { _ in
            Task { await self.updateStatusIfPollTimeHasBeenReached() }
        }
        model.$pipelines
            .sink(receiveValue: updateStatusIfPipelineWasAdded(pipelines:))
            .store(in: &subscribers)
    }

    func updateStatusIfPollTimeHasBeenReached() async {
        if Date().timeIntervalSince(lastPoll).rounded() < pollInterval {
            return
        }
        lastPoll = Date()
        await updateStatus(pipelines: model.pipelines)
    }

    func updateStatusIfPipelineWasAdded(pipelines: [Pipeline]) {
        if pipelines.count <= model.pipelines.count {
            return
        }
        let newPipelines = Set(pipelines).subtracting(Set(model.pipelines))
        Task { await updateStatus(pipelines: Array(newPipelines)) }
    }

    private func updateStatus(pipelines: [Pipeline]) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            self.updatePipelines_CCTray(pipelines.filter({ $0.feed.type == .cctray }), taskGroup: &taskGroup)
            self.updatePipelines_GitHub(pipelines.filter({ $0.feed.type == .github }), taskGroup: &taskGroup)
            await taskGroup.waitForAll()
        }
    }

    // TODO: Consider moving the following methods to the reader, with a protocol and base class
    // TODO: Consider adding a limit to the number of parallel requests (see https://stackoverflow.com/questions/70976323/)

    private func updatePipelines_CCTray(_ pipelines: [Pipeline], taskGroup: inout TaskGroup<Void>) {
        for pg in Dictionary(grouping: pipelines, by: { $0.feed.url }).values {
            taskGroup.addTask { await self.updateCCTrayPipelines(group: pg) }
        }
    }
    
    private func updateCCTrayPipelines(group: [Pipeline]) async {
        var group = group
        guard let pipeline = group.first else { return }
        if !networkMonitor.isConnected && pipelineIsRemote(pipeline) {
            group = group.filter({ !pipelineHasSomeStatus($0) })
            if group.isEmpty {
                return
            }
        }
        let reader = CCTrayFeedReader(for: group)
        await reader.updatePipelineStatus()
        reader.pipelines.forEach({ model.update(pipeline: $0) })
    }
    
    
    private func updatePipelines_GitHub(_ pipelines: [Pipeline], taskGroup: inout TaskGroup<Void>) {
        for p in pipelines {
            taskGroup.addTask { await self.updateGitHubPipeline(pipeline: p) }
        }
    }

    private func updateGitHubPipeline(pipeline: Pipeline) async {
        var pipeline = pipeline
        if !networkMonitor.isConnected && pipelineIsRemote(pipeline) && pipelineHasSomeStatus(pipeline) {
            return
        }
        if let pauseUntil = pipeline.feed.pauseUntil {
            if Date().timeIntervalSince1970 <= Double(pauseUntil) {
                return
            }
            pipeline.feed.clearPauseUntil()
        }
        let reader = GitHubFeedReader(for: pipeline)
        await reader.updatePipelineStatus()
        model.update(pipeline: reader.pipeline)
    }

    
    private func pipelineIsRemote(_ p: Pipeline) -> Bool {
        if p.feed.url.host() != "localhost" {
            return true
        }
        return false
    }

    private func pipelineHasSomeStatus(_ p: Pipeline) -> Bool {
        return (p.status.lastBuild != nil || p.connectionError != nil)
    }

}
