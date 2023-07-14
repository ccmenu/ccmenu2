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

    private static let menuBarShowBuildTimer = "ShowTimerInMenu"
    private static let menuBarUseColor = "UseColorInMenuBar"
    private static let menuShowBuildLabels = "ShowLastBuildLabel"
    private static let menuShowBuildTimes = "ShowLastBuildTimes"

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

    @Published var showBuildTimerInMenuBar: Bool {
        didSet {
            userDefaults?.setValue(showBuildTimerInMenuBar, forKey: Self.menuBarShowBuildTimer)
        }
    }

    @Published var useColorInMenuBar: Bool {
        didSet {
            userDefaults?.setValue(useColorInMenuBar, forKey: Self.menuBarUseColor)
        }
    }

    @Published var showBuildLabelsInMenu: Bool {
        didSet {
            userDefaults?.setValue(showBuildLabelsInMenu, forKey: Self.menuShowBuildLabels)
        }
    }

    @Published var showBuildTimesInMenu: Bool {
        didSet {
            userDefaults?.setValue(showBuildTimesInMenu, forKey: Self.menuShowBuildTimes)
        }
    }

    init() {
        pipelineList = []
        showStatusInPipelineWindow = false
        showMessagesInPipelineWindow = true
        showAvatarsInPipelineWindow = true
        showBuildTimerInMenuBar = true
        useColorInMenuBar = false
        showBuildLabelsInMenu = false
        showBuildTimesInMenu = false
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
        showBuildTimerInMenuBar = userDefaults.bool(forKey: Self.menuBarShowBuildTimer)
        useColorInMenuBar = userDefaults.bool(forKey: Self.menuBarUseColor)
        showBuildLabelsInMenu = userDefaults.bool(forKey: Self.menuShowBuildLabels)
        showBuildTimesInMenu = userDefaults.bool(forKey: Self.menuShowBuildTimes)
        self.userDefaults = userDefaults
    }
    
}
