/*
 *  Copyright (c) ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine

@main
struct CCMenuApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject public var userSettings: UserSettings
    @ObservedObject public var viewModel: ViewModel
    private var serverMonitor: ServerMonitor
    private var subscribers: [AnyCancellable] = []

    @State private var menuLabel: String = ""
    @State private var menuImage: NSImage = ImageManager().image(forResult: .other, activity: .other)

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
