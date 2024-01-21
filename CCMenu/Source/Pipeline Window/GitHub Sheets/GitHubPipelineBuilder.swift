/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import SwiftUI

class GitHubPipelineBuilder: ObservableObject {
    private var repository = GitHubRepository()
    private var workflow = GitHubWorkflow()
    @Published var name: String = ""

    func updateName(repository: GitHubRepository, workflow: GitHubWorkflow) {
        var newName = ""
        if repository.isValid {
            newName.append(repository.name)
            if workflow.isValid {
                newName.append(String(format: " | %@", workflow.name))
            }
        }
        self.repository = repository
        self.workflow = workflow
        self.name = newName
    }

    func makePipeline(owner: String, authToken: String?) -> Pipeline {
        // TODO: Consider what is the best place for this code and how much state it should be aware of
        let url = GitHubAPI.feedUrl(owner: owner, repository: repository.name, workflow: workflow.filename)
        let feed = Pipeline.Feed(type: .github, url:url, authToken: authToken)
        let pipeline = Pipeline(name: name, feed: feed)
        return pipeline
    }

}

