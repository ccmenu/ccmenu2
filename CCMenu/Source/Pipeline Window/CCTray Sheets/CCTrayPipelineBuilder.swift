/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */


import Foundation

class CCTrayPipelineBuilder: ObservableObject {
    @Published var name: String = ""

    func updateName(project: CCTrayProject) {
        var newName = ""
        if project.isValid {
            newName.append(project.name)
        }
        name = newName
    }

    func makePipeline(feedUrl: String, name: String) -> Pipeline {
        // TODO: Consider what is the best place for this code and how much state it should be aware of
        // (and see same comment in GitHubPipelineBuilder)
        let feed = Pipeline.Feed(type:.cctray, url: feedUrl, name: name)
        var p: Pipeline = Pipeline(name: self.name, feed: feed)
        p.status = Pipeline.Status(activity: .sleeping)
        p.status.lastBuild = Build(result: .unknown)
        return p
    }


}
