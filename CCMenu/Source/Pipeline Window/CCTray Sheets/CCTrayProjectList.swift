/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

@MainActor
class CCTrayProjectList: ObservableObject {
    @Published private(set) var items = [CCTrayProject()] { didSet { selected = items[0] }}
    @Published var selected = CCTrayProject()

    func updateWorkflows(url urlBinding: Binding<String>) async {
        addSchemeIfNecessary(url: urlBinding)
        guard let baseUrl = URL(string: urlBinding.wrappedValue) else {
            items = [CCTrayProject(message: "The URL is invalid.")]
            return
        }
        items = [CCTrayProject(message: "updating")]
        items = await fetchProjects(urlList: makeUrlList(baseUrl: baseUrl), urlBinding: urlBinding)
    }

    private func addSchemeIfNecessary(url urlBinding: Binding<String>) {
        let userInput = urlBinding.wrappedValue
        if !userInput.hasPrefix("http://") && !userInput.hasPrefix("https://") {
            urlBinding.wrappedValue = "http://" + userInput
        }
    }

    private func makeUrlList(baseUrl: URL) -> [URL] {
        var list = [baseUrl]
        if baseUrl.pathExtension.isEmpty {
            let paths = ["/cctray.xml", "/dashboard/cctray.xml", "/go/cctray.xml", "/cc.xml", "/hudson/cc.xml", "/xml", "/XmlStatusReport.aspx", "/ccnet/XmlStatusReport.aspx"]
            list += paths.map({ var u = baseUrl; u.append(path: $0); return u })
        }
        return list
    }

    private func fetchProjects(urlList: [URL], urlBinding: Binding<String>) async -> [CCTrayProject] {
        var firstResponse: [CCTrayProject]? = nil
        for url in urlList {
            urlBinding.wrappedValue = url.absoluteString
            let projects: [CCTrayProject]
            do {
                let request = CCTrayAPI.requestForProjects(url: url)
                projects = try await fetchProjects(request: request)
            } catch {
                return [CCTrayProject(message: error.localizedDescription)]
            }
            if projects.count == 0 {
                return [CCTrayProject()]
            } else if projects[0].isValid {
                return projects
            } else if firstResponse == nil {
                firstResponse = projects
            }
        }
        urlBinding.wrappedValue = urlList[0].absoluteString
        // firstResponse can't be empty at this point
        return firstResponse ?? [CCTrayProject()]
    }

    func fetchProjects(request: URLRequest) async throws -> [CCTrayProject] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.unsupportedURL)
        }
        guard response.statusCode == 200 else {
            let httpError = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            return [CCTrayProject(message: "The server responded: \(httpError)")]
        }
        let parser = CCTrayResponseParser()
        do {
            try parser.parseResponse(data)
        } catch {
            return [CCTrayProject(message: "The feed is not a valid XML document.")]
        }
        var list = parser.projectList.compactMap({ $0["name"] }).map({ CCTrayProject(name: $0) })
        list.sort(by: { r1, r2 in r1.name.lowercased().compare(r2.name.lowercased()) == .orderedAscending })
        return list
    }

    func clearWorkflows() {
        items = [CCTrayProject()]
    }

}
