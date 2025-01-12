/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

// TODO: Refactor the list classes (repo, workflow, branch) to use some common code
@MainActor
class GitHubRepositoryList: ObservableObject {
    @Published private(set) var items = [GitHubRepository()]

    func updateRepositories(owner: String, token: String?) async {
        items = [GitHubRepository(message: "updating")]
        items = await fetchRepositories(owner: owner, token: token)
    }

    private func fetchRepositories(owner: String, token: String?) async -> [GitHubRepository] {
        let userRequest = GitHubAPI.requestForUser(user: owner, token: token)
        let (user, error) = await fetchUser(request: userRequest)
        guard let user else {
            return [GitHubRepository(message: error)]
        }

        let ownerRepoRequest: URLRequest
        if user.isOrganization {
            ownerRepoRequest = GitHubAPI.requestForAllRepositories(org: owner, token: token)
        } else {
            ownerRepoRequest = GitHubAPI.requestForAllPublicRepositories(user: owner, token: token)
        }
        var allRepos = await fetchRepositories(request: ownerRepoRequest)
        if allRepos.count > 0 && !allRepos[0].isValid {
            return allRepos
        }

        if !user.isOrganization, let token, !token.isEmpty {
            let privateRepoRequest = GitHubAPI.requestForAllPrivateRepositories(token: token)
            let privateRepos = await fetchRepositories(request: privateRepoRequest)
            if privateRepos.count > 0 && !privateRepos[0].isValid {
                return privateRepos
            }
            allRepos.append(contentsOf: privateRepos)
        }

        allRepos = allRepos.filter({ $0.owner?.login.lowercased() == owner.lowercased() })
        if allRepos.count == 0 {
            allRepos = [GitHubRepository()]
        }
        allRepos.sort(by: { r1, r2 in r1.name.lowercased().compare(r2.name.lowercased()) == .orderedAscending })
        
        return allRepos
    }

    private func fetchUser(request: URLRequest) async -> (GitHubUser?, String) {
        do {
            let (data, response) = try await URLSession.feedSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            // TODO: Somehow refactor this to use the same code as fetchRepositories
            if response.statusCode == 403 || response.statusCode == 429 {
                if let v = response.value(forHTTPHeaderField: "x-ratelimit-remaining"), Int(v) == 0  {
                    // HTTPURLResponse doesn't have a specific message for code 429
                    return (nil, "too many requests")
                } else {
                    return (nil, HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
                }
            }
            if response.statusCode != 200 {
                return (nil, HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
            }
            return (try JSONDecoder().decode(GitHubUser.self, from: data), "OK")
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    private func fetchRepositories(request: URLRequest) async -> [GitHubRepository] {
        do {
            let (data, response) = try await URLSession.feedSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            // TODO: Somehow refactor this to use the same code as feed reader
            if response.statusCode == 403 || response.statusCode == 429 {
                if let v = response.value(forHTTPHeaderField: "x-ratelimit-remaining"), Int(v) == 0  {
                    // HTTPURLResponse doesn't have a specific message for code 429
                    return [GitHubRepository(message: "too many requests")]
                } else {
                    return [GitHubRepository(message: HTTPURLResponse.localizedString(forStatusCode: response.statusCode))]
                }
            }
            if response.statusCode != 200 {
                return [GitHubRepository(message: HTTPURLResponse.localizedString(forStatusCode: response.statusCode))]
            }
            return try JSONDecoder().decode([GitHubRepository].self, from: data)
        } catch {
            return [GitHubRepository(message: error.localizedDescription)]
        }
    }

    func clearRepositories() {
        items = [GitHubRepository()]
    }
}
