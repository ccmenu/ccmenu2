/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import Combine


final class UserSettings: ObservableObject  {

    private static let pipelineList = "pipelines"

    private static let pipelineShowStatus = "pipelineShowStatus"
    private static let pipelineShowMessages = "pipelineShowMessages"
    private static let pipelineShowAvatars = "pipelineShowAvatars"

    private static let menuBarUseColor = "menuBarUseColor"
    private static let menuShowLabels = "menuShowLabel"

    private var userDefaults: UserDefaults?


    @Published var pipelineList: Array<Dictionary<String, String>> {
        didSet {
            userDefaults?.setValue(pipelineList, forKey: Self.pipelineList)
        }
    }

    @Published var showStatusInPipelineWindow: Bool {
        didSet {
            userDefaults?.setValue(showStatusInPipelineWindow, forKey: Self.pipelineShowStatus)
        }
    }

    @Published var showMessagesInPipelineWindow: Bool {
        didSet {
            userDefaults?.setValue(showMessagesInPipelineWindow, forKey: Self.pipelineShowMessages)
        }
    }

    @Published var showAvatarsInPipelineWindow: Bool {
        didSet {
            userDefaults?.setValue(showAvatarsInPipelineWindow, forKey: Self.pipelineShowAvatars)
        }
    }

    @Published var useColorInMenuBar: Bool {
        didSet {
            userDefaults?.setValue(useColorInMenuBar, forKey: Self.menuBarUseColor)
        }
    }

    @Published var showLabelsInMenu: Bool {
        didSet {
            userDefaults?.setValue(showLabelsInMenu, forKey: Self.menuShowLabels)
        }
    }

    init() {
        pipelineList = []
        showStatusInPipelineWindow = false
        showMessagesInPipelineWindow = true
        showAvatarsInPipelineWindow = true
        useColorInMenuBar = false
        showLabelsInMenu = false
    }

    convenience init(userDefaults: UserDefaults?) {
        self.init()
        guard let userDefaults = userDefaults else {
            return
        }
        // TODO: better workaround/warning for unexpected list type
        if let list = userDefaults.array(forKey: Self.pipelineList) as? Array<Dictionary<String, String>> {
            pipelineList = list
        }
        showStatusInPipelineWindow = userDefaults.bool(forKey: Self.pipelineShowStatus)
        showMessagesInPipelineWindow = userDefaults.bool(forKey: Self.pipelineShowMessages)
        showAvatarsInPipelineWindow = userDefaults.bool(forKey: Self.pipelineShowAvatars)
        useColorInMenuBar = userDefaults.bool(forKey: Self.menuBarUseColor)
        showLabelsInMenu = userDefaults.bool(forKey: Self.menuShowLabels)
        self.userDefaults = userDefaults
    }
    
}
