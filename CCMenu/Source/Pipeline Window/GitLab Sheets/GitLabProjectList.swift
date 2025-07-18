/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

@MainActor
class GitLabProjectList: ObservableObject {
    @Published private(set) var items = [GitLabProject()]
    
    func updateProjects(name: String, token: String?) async {
        items = [GitLabProject(message: "updating")]
        items = await fetchProjects(name: name, token: token)
    }
    
    private func fetchProjects(name: String, token: String?) async -> [GitLabProject] {
        // First try as user
        let userProjectsRequest = GitLabAPI.requestForUserProjects(user: name, token: token)
        var projects = await fetchProjects(request: userProjectsRequest)
        
        // If user projects request failed or returned no valid projects, try as group
        if projects.isEmpty || !projects[0].isValid {
            let groupProjectsRequest = GitLabAPI.requestForGroupProjects(group: name, token: token)
            projects = await fetchProjects(request: groupProjectsRequest)
        }
        
        // If both failed, return empty result with appropriate message
        if projects.isEmpty || !projects[0].isValid {
            return [GitLabProject(message: "No projects found")]
        }
        
        // Sort projects by name
        projects.sort(by: { p1, p2 in p1.name.lowercased().compare(p2.name.lowercased()) == .orderedAscending })
        
        return projects
    }
    
    private func fetchProjects(request: URLRequest) async -> [GitLabProject] {
        let (projects, message): ([GitLabProject]?, String) = await GitLabAPI.sendRequest(request: request)
        guard let projects else {
            return [GitLabProject(message: message)]
        }
        return projects
    }
    
    func clearProjects() {
        items = [GitLabProject()]
    }
}
