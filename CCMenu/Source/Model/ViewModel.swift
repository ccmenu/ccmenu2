/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import Combine


final class ViewModel: ObservableObject {

    @Published var pipelines: [Pipeline] { didSet { updateSettings(); updateMenu(); updateMenuBar() } }

    @Published var menuBarInformation: MenuBarInformation
    @Published var pipelinesForMenu: [LabeledPipeline] = []

    var settings: UserSettings

    private var subscribers: [AnyCancellable] = []

    init() {
        menuBarInformation = MenuBarInformation(pipelines: [], settings: UserSettings())
        pipelines = []
        settings = UserSettings()
    }

    convenience init(settings: UserSettings) {
        self.init()
        self.settings = settings
        settings.$useColorInMenuBar
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in self.updateMenuBar() } )
            .store(in: &subscribers)
        settings.$showLabelsInMenu
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in self.updateMenu() } )
            .store(in: &subscribers)
    }

    func reloadPipelineStatus() {
        print("Should reload status for all pipelines")
    }

    func update(pipeline: Pipeline) {
        guard let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) else {
            debugPrint("trying to update unknown pipeline \(pipelines.debugDescription)")
            return
        }

        pipelines[idx] = pipeline
    }


    private func updateMenuBar() {
        menuBarInformation = MenuBarInformation.init(pipelines: pipelines, settings: settings)
    }

    private func updateMenu() {
        pipelinesForMenu = []
        for p in pipelines {
            var l = p.displayName
            if settings.showLabelsInMenu, let buildLabel = p.status.lastBuild?.label {
                l.append(" \u{2014} \(buildLabel)")
            }
            pipelinesForMenu.append(LabeledPipeline(pipeline: p, label: l))
        }
    }


    private func updateSettings() {
        // TODO: this is called, too, every time the status gets updated...
        settings.pipelineList = pipelines.map({ $0.asDictionaryForPersisting() })
    }


    func loadPipelinesFromUserDefaults() {
        if settings.pipelineList.isEmpty {
            loadPipelinesFromLegacyDefaults()
            addCCMenu2Pipeline()
        } else {
            pipelines = settings.pipelineList.compactMap(Pipeline.fromPersistedDictionary)
        }
    }


    private func loadPipelinesFromLegacyDefaults() {
        guard  let legacyProjects = UserDefaults.standard.array(forKey: "Projects") as? Array<Dictionary<String, String>> else {
            return
        }
        for project in legacyProjects {
            if let name = project["projectName"], let feedUrl = project["serverUrl"] {
                pipelines.append(Pipeline(name: name, feedUrl: feedUrl))
            }
        }
    }

    private func addCCMenu2Pipeline() {
        var p0 = Pipeline(name: "build-and-test.yaml", feedType: .github, feedUrl: "https://api.github.com/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs")
        p0.displayName = "ccmenu2 (build-and-test)"
        pipelines.append(p0)
    }

    func loadPipelinesFromFile(_ filename: String) {
        let data: Data

        do {
            data = try Data(contentsOf: URL(fileURLWithPath: filename))
        } catch {
            fatalError("Couldn't load test data from \(filename):\n\(error)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                if let date = ISO8601DateFormatter().date(from: string) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date string \(string)")
            }
            pipelines = try decoder.decode([Pipeline].self, from: data)
            updateMenuBar()
            updateMenu()
        } catch {
            fatalError("Couldn't parse \(filename) as [Pipeline]:\n\(error)")
        }
    }

}

