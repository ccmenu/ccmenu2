/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class ServerMonitor: FeedReaderDelegate {
    
    var model: ViewModel
    var readerList: [FeedReader] = []

    init(model: ViewModel) {
        self.model = model
    }
    
    public func start() {
        createReaders()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: pollServers)
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: pollServers)
    }

    public func createReaders() {
        for p in model.pipelines {
            var r: FeedReader
            switch(p.connectionDetails.feedType) {
            case .cctray: r = CCTrayFeedReader(for: p)
            case .github: r = GithubFeedReader(for: p)
            }
          
            r.delegate = self
            readerList.append(r)
        }
    }
    
    func pollServers(t: Timer) {
        for r in readerList {
            r.updatePipelineStatus()
        }
    }
    
    func feedReader(_ reader: FeedReader, didUpdate pipeline: Pipeline) {
//        NSLog("Received update for pipeline \(pipeline)")
        model.update(pipeline: pipeline)
    }
    
}
