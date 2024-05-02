/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class GitHubPipelineBuilder: ObservableObject {
    @Published var name: String = ""
    var owner: String?
    var repository: GitHubRepository? { didSet { setDefaultName() } }
    var workflow: GitHubWorkflow? { didSet { setDefaultName() } }
    var branch: GitHubBranch? { didSet { setDefaultName() } }

    func setDefaultName() {
        var newName = ""
        if let repository, repository.isValid {
            newName.append(repository.name)
            if let workflow, workflow.isValid {
                newName.append(String(format: " | %@", workflow.name))
            }
        }
        name = newName
    }

    var canMakePipeline: Bool {
       return makePipeline() != nil
    }

    func makePipeline() -> Pipeline? {
        guard !name.isEmpty else { return nil }
        guard let owner else { return nil }
        guard let repository, repository.isValid else { return nil }
        guard let workflow, workflow.isValid else { return nil }
        guard let branch, branch.isValid else { return nil }
        let branchName = branch.isAllBranchPlaceholder ? nil : branch.name
        let url = GitHubAPI.feedUrl(owner: owner, repository: repository.name, workflow: workflow.filename, branch: branchName)
        let feed = Pipeline.Feed(type: .github, url:url)
        let pipeline = Pipeline(name: name, feed: feed)
        return pipeline
    }

}

