/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

@main
struct CCMenuApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject public var viewModel: ViewModel
    @ObservedObject public var userSettings: UserSettings
    var serverMonitor: ServerMonitor

    @State private var command: String = "a"

    init() {
        var userDefaults: UserDefaults? = nil
        if UserDefaults.standard.bool(forKey: "ignoreDefaults") {
            print("Ignoring user defaults from system")
        } else {
            userDefaults = UserDefaults.standard
        }

        let viewModel = ViewModel()
        let userSettings = UserSettings(userDefaults: userDefaults)

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
            StatusItemMenu(model: viewModel, settings: userSettings)
        } label: {
            Label(title: { Text(command) }, icon: { Image(nsImage: menuBarImage(useColor: userSettings.useColorInStatusItem)) })
            .labelStyle(.titleAndIcon)
            .accessibilityIdentifier("CCMenuStatusItem")
        }

    }

    private func menuBarImage(useColor: Bool) -> NSImage {
        guard let pipeline = viewModel.pipelineForItem else {
            return ImageManager().image(forResult: .other, activity: .other)
        }
        return ImageManager().image(forPipeline: pipeline, asTemplate: !useColor)
    }

}
