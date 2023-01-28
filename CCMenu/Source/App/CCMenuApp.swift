/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


@available(macOS 13.0, *)
struct CCMenuApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject public var userSettings: UserSettings
    @ObservedObject public var viewModel: ViewModel
    private var serverMonitor: ServerMonitor

    init() {
        var userDefaults: UserDefaults? = nil
        if UserDefaults.standard.bool(forKey: "ignoreDefaults") {
            print("Ignoring user defaults from system")
        } else {
            userDefaults = UserDefaults.standard
        }

        let userSettings = UserSettings(userDefaults: userDefaults)
        let viewModel = ViewModel(settings: userSettings)

        self.viewModel = viewModel
        self.userSettings = userSettings
        self.serverMonitor = ServerMonitor(model: viewModel)

        appDelegate.viewModel = viewModel
        appDelegate.userSettings = userSettings

        if let filename = UserDefaults.standard.string(forKey: "loadPipelines") {
            print("Loading pipeline definitions from file \(filename)")
            viewModel.loadPipelinesFromFile(filename)
        } else {
            viewModel.loadPipelinesFromUserDefaults()
            serverMonitor.start()
        }

    }

    var body: some Scene {

        WindowGroup("Pipelines") {
            PipelineListView(model: viewModel, settings: userSettings)
                .handlesExternalEvents(preferring: ["pipelines"], allowing: ["pipelines"])
        }
        .commands {
            AppCommands()
        }
        .handlesExternalEvents(matching: ["pipelines"])

        Settings {
            SettingsView(settings: userSettings)
        }
        MenuBarExtra() {
            MenuBarExtraContent(model: viewModel)
        } label: {
            MenuBarExtraLabel(model: viewModel)
        }

    }


}


/*
    EmptyApp and the Main wrapper below make it possible to build a (non-functioning) app on
    macOS 12. This in turn makes it possible to run the unit test suite on macOS 12. All of
    this is needed because Github Actions doesn't yet support macOS 13 runners. More details
    here: https://stackoverflow.com/questions/75263777
*/

struct EmptyApp: App {
    var body: some Scene {
        WindowGroup("Pipelines") {
        }
    }
}


@main
struct Main {
    static func main() {
        if #available(macOS 13.0, *) {
            CCMenuApp.main()
        } else {
            EmptyApp.main()
        }
    }
}
