/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import SwiftUI

class GitHubPipelineBuilder: ObservableObject {
    @Published var name: String = ""

    func setDefaultName(repository: GitHubRepository, workflow: GitHubWorkflow) {
        var newName = ""
        if repository.isValid {
            newName.append(repository.name)
            if workflow.isValid {
                newName.append(String(format: " | %@", workflow.name))
            }
        }
        self.name = newName
    }

    func makePipeline(owner: String, repository: GitHubRepository, workflow: GitHubWorkflow) -> Pipeline {
        let url = GitHubAPI.feedUrl(owner: owner, repository: repository.name, workflow: workflow.filename)
        let feed = Pipeline.Feed(type: .github, url:url)
        let pipeline = Pipeline(name: name, feed: feed)
        return pipeline
    }

}

