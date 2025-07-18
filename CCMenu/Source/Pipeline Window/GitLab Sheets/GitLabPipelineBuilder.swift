/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class GitLabPipelineBuilder: ObservableObject {
    @Published var name: String = ""
    var project: GitLabProject?
    var branch: String? { didSet { setDefaultName() } }
    
    func setDefaultName() {
        var newName = ""
        if let project = project, project.isValid {
            newName = project.displayName
            if let branch = branch, !branch.isEmpty, branch != "all branches" {
                newName.append(String(format: " | %@", branch))
            }
        }
        name = newName
    }
    
    var canMakePipeline: Bool {
        guard !name.isEmpty else { return false }
        guard let project = project, project.isValid else { return false }
        return true
    }
    
    func makePipeline(token: String?) async -> Pipeline? {
        guard !name.isEmpty else { return nil }
        guard let project = project, project.isValid else { return nil }
        
        // Convert project ID to string
        let projectId = String(project.id)
        
        // Get branch name if specified, otherwise nil for all branches
        let branchName = branch == "all branches" || branch?.isEmpty == true ? nil : branch
        
        // Create URL for GitLab pipeline feed
        let url = GitLabAPI.feedUrl(projectId: projectId, branch: branchName)
        
        // Verify the URL works by fetching pipelines
        if let request = GitLabAPI.requestForFeed(feed: PipelineFeed(type: .gitlab, url: url), token: token),
           let result = await fetchPipelines(request: request), result == 200 {
            
            // Create pipeline feed and pipeline
            let feed = PipelineFeed(type: .gitlab, url: url)
            let pipeline = Pipeline(name: name, feed: feed)
            return pipeline
        }
        
        return nil
    }
    
    private func fetchPipelines(request: URLRequest) async -> Int? {
        do {
            let (_, response) = try await URLSession.feedSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            return response.statusCode
        } catch {
            return nil
        }
    }
}
