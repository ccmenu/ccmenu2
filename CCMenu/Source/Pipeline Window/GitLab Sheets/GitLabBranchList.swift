/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

@MainActor
class GitLabBranchList: ObservableObject {
    @Published private(set) var items = [GitLabBranch()] { didSet { selected = items[0] }}
    @Published var selected = GitLabBranch()
    
    func updateBranches(projectId: String, token: String?) async {
        items = [GitLabBranch(message: "updating")]
        items = await fetchBranches(projectId: projectId, token: token)
    }
    
    private func fetchBranches(projectId: String, token: String?) async -> [GitLabBranch] {
        let request = GitLabAPI.requestForBranches(projectId: projectId, token: token)
        var branches = await fetchBranches(request: request)
        
        if branches.count > 0 && !branches[0].isValid {
            return branches
        }
        
        // Add empty string branch as the first item (represents "all branches")
        branches.insert(GitLabBranch(name: ""), at: 0)
        
        if branches.count == 1 {
            branches = [GitLabBranch()]
        }
        
        return branches
    }
    
    private func fetchBranches(request: URLRequest) async -> [GitLabBranch] {
        let (branches, message): ([GitLabBranch]?, String) = await GitLabAPI.sendRequest(request: request)
        guard let branches else {
            return [GitLabBranch(message: message)]
        }
        return branches
    }
    
    func clearBranches() {
        items = [GitLabBranch()]
    }
}
