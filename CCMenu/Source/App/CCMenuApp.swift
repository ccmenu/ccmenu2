/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


@main
struct CCMenuApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var userSettings: UserSettings
    @ObservedObject private var pipelineModel: PipelineModel
    private var pipelineWindowController: PipelineWindowController
    private var serverMonitor: ServerMonitor

    init() {
        var userDefaults: UserDefaults? = nil
        if UserDefaults.standard.bool(forKey: "ignoreDefaults") {
            print("Ignoring user defaults from system")
        } else {
            userDefaults = UserDefaults.standard
        }

        let userSettings = UserSettings(userDefaults: userDefaults)
        let pipelineModel = PipelineModel(settings: userSettings)

        self.userSettings = userSettings
        self.pipelineModel = pipelineModel
        self.pipelineWindowController = PipelineWindowController(model: pipelineModel)
        self.serverMonitor = ServerMonitor(model: pipelineModel)

        if let filename = UserDefaults.standard.string(forKey: "loadPipelines") {
            print("Loading pipeline definitions from file \(filename)")
            pipelineModel.loadPipelinesFromFile(filename)
        } else {
            pipelineModel.loadPipelinesFromUserDefaults()
            serverMonitor.start()
        }

    }

    var body: some Scene {

        Window("Pipelines", id:"pipeline-list") {
            // TODO: Consider: pass only controller, and then view pulls out models?
            PipelineListView(controller: pipelineWindowController, model: pipelineModel, viewState: pipelineWindowController.listViewState)
                .environmentObject(userSettings)
        }
        .defaultSize(width: 550, height: 600)
        .keyboardShortcut("0", modifiers: [ .command ])
//        .commands {
//            PipelineCommands(model: viewModel)
//        }
        Settings {
            SettingsView(settings: userSettings)
        }
        MenuBarExtra() {
            MenuBarExtraMenu(model: pipelineModel, settings: userSettings)
        } label: {
            MenuBarExtraLabel(model: pipelineModel, settings: userSettings)
        }

    }

}
