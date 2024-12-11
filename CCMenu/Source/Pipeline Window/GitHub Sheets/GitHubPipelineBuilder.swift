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
        guard !name.isEmpty else { return false }
        guard let owner else { return false }
        guard let repository, repository.isValid else { return false }
        guard let workflow, workflow.isValid else { return false }
        guard let branch, branch.isValid else { return false }
        return true
    }

    func makePipeline() async -> Pipeline? {
        guard !name.isEmpty else { return nil }
        guard let owner else { return nil }
        guard let repository, repository.isValid else { return nil }
        guard let workflow, workflow.isValid else { return nil }
        guard let branch, branch.isValid else { return nil }
        let branchName = branch.isAllBranchPlaceholder ? nil : branch.name

        var url: URL? = nil
        let workflowPathComponents = [ workflow.filename, String(workflow.id) ]
        for wfid in workflowPathComponents {
            url = GitHubAPI.feedUrl(owner: owner, repository: repository.name, workflow: wfid, branch: branchName)
            if let url, let result = await fetchRuns(url: url), result == 200 {
                break
            }
            url = nil
        }
        guard let url else {
            return nil
        }

        let feed = PipelineFeed(type: .github, url:url)
        let pipeline = Pipeline(name: name, feed: feed)
        return pipeline
    }

    private func fetchRuns(url: URL) async -> Int? {
        let feed = PipelineFeed(type: .github, url:url)
        guard let request = GitHubAPI.requestForFeed(feed: feed, token: nil) else {
            return nil
        }
        let result = await fetchRuns(request: request)
        return result
    }

    private func fetchRuns(request: URLRequest) async -> Int? {
        do {
            let (data, response) = try await URLSession.feedSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            return response.statusCode
        } catch {
            return nil
        }
    }
}

