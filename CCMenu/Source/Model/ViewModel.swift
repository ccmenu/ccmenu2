/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import Combine


final class ViewModel: ObservableObject {

    @Published var pipelines: [Pipeline] { didSet { updateMenu(); updateMenuBar() } }
    @Published var avatars: Dictionary<URL, NSImage>

    @Published var pipelinesForMenu: [LabeledPipeline] = []

    @Published var imageForMenuBar: NSImage
    @Published var textForMenuBar: String

    var settings: UserSettings

    private var subscribers: [AnyCancellable] = []

    init() {
        imageForMenuBar = ImageManager().defaultImage
        textForMenuBar = ""
        pipelines = []
        avatars = Dictionary()
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

    func update(pipeline: Pipeline) {
        guard let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) else {
            debugPrint("trying to update unknown pipeline \(pipelines.debugDescription)")
            return
        }

        pipelines[idx] = pipeline

        if let avatarUrl = pipeline.avatar {
            if avatars[avatarUrl] == nil {
                retrieveAvatar(url: avatarUrl)
            }
        }

        updateMenuBar() // TODO: still needed now that we have a didSet on pipelines?
        updateMenu()
    }

    private func updateMenuBar() {
        if let pipeline = pipelineForMenuBar() {
            imageForMenuBar = ImageManager().image(forPipeline: pipeline, asTemplate: !settings.useColorInMenuBar)
            if pipeline.status.activity == .building {
                if let completionTime = pipeline.estimatedBuildComplete {
                    textForMenuBar = Date.now.formatted(.compactRelative(reference: completionTime))
                } else {
                    textForMenuBar = ""
                }
            } else {
                let failCount = pipelines.filter({ p in p.status.lastBuild?.result == .failure}).count
                textForMenuBar = (failCount == 0) ? "" : "\(failCount)"
            }
        } else {
            imageForMenuBar = ImageManager().defaultImage
            textForMenuBar = ""
        }
    }

    private func pipelineForMenuBar() -> Pipeline? {
        try! pipelines.sorted(by: compareMenuBarPriority(lhs:rhs:)).first
    }

    private func compareMenuBarPriority(lhs: Pipeline, rhs: Pipeline) throws -> Bool {

        let priorities = [
            priority(hasBuild:),
            priority(isBuilding:),
            priority(buildResult:),
            priority(estimatedComplete:)
        ]
        for p in priorities {
            if p(lhs) > p(rhs) {
                return true
            }
            if p(lhs) < p(rhs) {
                return false
            }
        }
        return false
    }

    private func priority(hasBuild pipeline: Pipeline) -> Int {
        return (pipeline.status.lastBuild != nil) ? 1 : 0
    }

    private func priority(isBuilding pipeline: Pipeline) -> Int {
        return (pipeline.status.activity == .building) ? 1 : 0
    }

    private func priority(buildResult pipeline: Pipeline) -> Int {
        switch pipeline.status.lastBuild?.result {
        case .failure:
            return 3
        case .success:
            return 2
        case .unknown, .other:
            return 1
        case nil:
            return 0
        }
    }

    private func priority(estimatedComplete pipeline: Pipeline) -> Int {
        let date = pipeline.estimatedBuildComplete ?? Date.distantFuture
        assert(Date.distantFuture.timeIntervalSinceReferenceDate < Double(Int.max))
        // Multiplying all intervals with -1 makes shorter intervals higher priority.
        return Int(date.timeIntervalSinceReferenceDate) * -1
    }


    private func updateMenu() {
        pipelinesForMenu = []
        for p in pipelines {
            var l = p.name
            if settings.showLabelsInMenu, let buildLabel = p.status.lastBuild?.label {
                l.append(" \u{2014} \(buildLabel)")
            }
            pipelinesForMenu.append(LabeledPipeline(pipeline: p, label: l))
        }
    }


    private func retrieveAvatar(url avatarUrl: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data.init(contentsOf: avatarUrl)
                DispatchQueue.main.async {
                    let avatarImage: NSImage? = NSImage(data: data)
                    debugPrint("did load avatar for \(avatarUrl)")
                    self.avatars[avatarUrl] = avatarImage
                    debugPrint("did set avatar for \(avatarUrl)")
                }
            }
            catch let errorLog {
                print(errorLog.localizedDescription)
            }
        }
    }


    func loadPipelinesFromUserDefaults() {
        if let legacyProjects = UserDefaults.standard.array(forKey: "Projects") as? Array<Dictionary<String, String>> {
            for project in legacyProjects {
                if let name = project["projectName"], let feedUrl = project["serverUrl"] {
                    if !name.hasPrefix("erikdoe/") {
                        pipelines.append(Pipeline(name: name, feedUrl: feedUrl))
                    }
                }
            }
        }
//        pipelines.append(Pipeline(name: "erikdoe/ccmenu2:CI", feedType: .github, feedUrl: "https://api.github.com/repos/erikdoe/ccmenu2/actions/runs"))
//        pipelines.append(Pipeline(name: "thoughtworks/epirust:cargo-audit", feedType: .github, feedUrl: "https://api.github.com/repos/thoughtworks/epirust/actions/runs"))
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

