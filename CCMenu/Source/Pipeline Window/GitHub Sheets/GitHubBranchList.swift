/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

@MainActor
class GitHubBranchList: ObservableObject {
    @Published private(set) var items = [GitHubBranch()] { didSet { selected = items[0] }}
    @Published var selected = GitHubBranch()

    func updateBranches(owner: String, repository: String, token: String?) async {
        items = [GitHubBranch(message: "updating")]
        items = await fetchBranches(owner: owner, repository: repository, token: token)
    }

    private func fetchBranches(owner: String, repository: String, token: String?) async -> [GitHubBranch] {
        let request = GitHubAPI.requestForBranches(owner: owner, repository: repository, token: token)
        var branches = await fetchBranches(request: request)
        if branches.count > 0 && !branches[0].isValid {
            return branches
        }
        branches.insert(GitHubBranch(name: "all branches"), at: 0)
        return branches
    }

    private func fetchBranches(request: URLRequest) async -> [GitHubBranch] {
        let (repos, message): ([GitHubBranch]?, String) = await GitHubAPI.sendRequest(request: request)
        guard let repos else {
            return [GitHubBranch(message: message)]
        }
        return repos
    }
 
    func clearBranches() {
        items = [GitHubBranch()]
    }

}
