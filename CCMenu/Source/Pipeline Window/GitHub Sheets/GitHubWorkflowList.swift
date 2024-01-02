/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

@MainActor
class GitHubWorkflowList: ObservableObject {
    @Published private(set) var items = [GitHubWorkflow()] { didSet { selected = items[0] }}
    @Published var selected = GitHubWorkflow()

    func updateWorkflows(owner: String, repository: String, token: String?) async {
        items = [GitHubWorkflow(message: "updating")]
        items = await fetchWorkflows(owner: owner, repository: repository, token: token)
    }

    private func fetchWorkflows(owner: String, repository: String, token: String?) async -> [GitHubWorkflow] {
        let request = GitHubAPI.requestForWorkflows(owner: owner, repository: repository, token: token)
        var workflows = await fetchWorkflows(request: request)
        if workflows.count > 0 && !workflows[0].isValid {
            return workflows
        }

        if workflows.count == 0 {
            workflows = [GitHubWorkflow()]
        }
        return workflows
    }

    private func fetchWorkflows(request: URLRequest) async -> [GitHubWorkflow] {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            guard response.statusCode == 200 else {
                let httpError = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                return [GitHubWorkflow(message: String(httpError))]
            }
            let workflowResponse = try JSONDecoder().decode(WorflowResponse.self, from: data)
            return workflowResponse.workflows
        } catch {
            return [GitHubWorkflow(message: error.localizedDescription)]
        }
    }

    struct WorflowResponse: Decodable {
        var workflows: [GitHubWorkflow]
    }

    func clearWorkflows() {
        items = [GitHubWorkflow()]
    }

}
