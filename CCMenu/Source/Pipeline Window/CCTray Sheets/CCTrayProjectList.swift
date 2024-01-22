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

    func updateWorkflows(url: Binding<String>) async {
        addSchemeIfNecessary(urlBinding: url)
        items = [CCTrayProject(message: "updating")]
        items = await fetchProjects(url: url)
    }

    private func addSchemeIfNecessary(urlBinding: Binding<String>) {
        let userInput = urlBinding.wrappedValue
        if !userInput.hasPrefix("http://") && !userInput.hasPrefix("https://") {
            urlBinding.wrappedValue = "http://" + userInput
        }
    }

    private func fetchProjects(url urlBinding: Binding<String>) async -> [CCTrayProject] {
        var firstResponse: [CCTrayProject]? = nil
        let userInput = urlBinding.wrappedValue
        let paths = ["", "/cctray.xml", "/dashboard/cctray.xml", "/go/cctray.xml", "/cc.xml", "/hudson/cc.xml", "/xml", "/XmlStatusReport.aspx", "/ccnet/XmlStatusReport.aspx" ]
        for p in paths {
            urlBinding.wrappedValue = userInput + p // TODO: Add handling for query params
            guard let request = CCTrayAPI.requestForProjects(url: urlBinding.wrappedValue) else {
                continue
            }
            let projects = await fetchProjects(request: request)
            if firstResponse == nil {
                firstResponse = projects
            }
            if projects.count > 0 && projects[0].isValid {
                return projects
            }
        }
        urlBinding.wrappedValue = userInput // assumes first entry in paths is ""
        if let projects = firstResponse, projects.count > 0 {
            return projects
        }
        return [CCTrayProject()]
    }

    private func fetchProjects(request: URLRequest) async -> [CCTrayProject] {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            guard response.statusCode == 200 else {
                let httpError = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                return [CCTrayProject(message: String(httpError))]
            }
            let parser = CCTrayResponseParser()
            try parser.parseResponse(data)
            var list: [CCTrayProject] = []
            for xml in parser.projectList {
                if let name = xml["name"] {
                    list.append(CCTrayProject(name: name))
                }
            }
            return list
        } catch {
            return [CCTrayProject(message: error.localizedDescription)]
        }
    }

    func clearWorkflows() {
        items = [CCTrayProject()]
    }

}
