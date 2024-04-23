/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class GitHubPipelineBuilder {

    func makePipeline(name: String, owner: String, repository: GitHubRepository, workflow: GitHubWorkflow, branch: GitHubBranch) -> Pipeline {
        let branchName = branch.isAllBranchPlaceholder ? nil : branch.name
        let url = GitHubAPI.feedUrl(owner: owner, repository: repository.name, workflow: workflow.filename, branch: branchName)
        let feed = Pipeline.Feed(type: .github, url:url)
        let pipeline = Pipeline(name: name, feed: feed)
        return pipeline
    }

}

