/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

@MainActor
class GitHubRepositoryList: ObservableObject {
    @Published private(set) var items = [GitHubRepository()] { didSet { selected = items[0] }}
    @Published var selected = GitHubRepository()

    func updateRepositories(owner: String, token: String?) async {
        items = [GitHubRepository(message: "updating")]
        items = await fetchRepositories(owner: owner, token: token)
    }

    private func fetchRepositories(owner: String, token: String?) async -> [GitHubRepository] {
        let request1 = GitHubAPI.requestForRepositories(owner: owner, token: token)
        let publicRepos = await fetchRepositories(request: request1)
        if publicRepos.count > 0 && !publicRepos[0].isValid {
            return publicRepos
        }

        let request2 = GitHubAPI.requestForPrivateRepositories(token: token)
        let privateRepos = (token != nil) ? await fetchRepositories(request: request2) : []
        if privateRepos.count > 0 && !privateRepos[0].isValid {
            return privateRepos
        }

        var allRepos = (publicRepos + privateRepos).filter({ $0.owner?.login == owner })
        if allRepos.count == 0 {
            allRepos = [GitHubRepository()]
        }
        allRepos.sort(by: { r1, r2 in r1.name.lowercased().compare(r2.name.lowercased()) == .orderedAscending })
        return allRepos
    }

    private func fetchRepositories(request: URLRequest) async -> [GitHubRepository] {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            guard response.statusCode == 200 else {
                return [GitHubRepository(message: HTTPURLResponse.localizedString(forStatusCode: response.statusCode))]
            }
            return try JSONDecoder().decode([GitHubRepository].self, from: data)
        } catch {
            return [GitHubRepository(message: error.localizedDescription)]
        }
    }
}
