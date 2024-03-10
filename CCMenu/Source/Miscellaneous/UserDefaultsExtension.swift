/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

public enum AppIconDefaultValue: String, CaseIterable, Identifiable {
    case
    never = "never",
    sometimes = "sometimes",
    always = "always"

    // TODO: Wasn't there a way to do without this?
    public var id: Self { self }
}


public enum DefaultsKey: String {
    case
    pipelineList = "pipelines",
    pollInterval = "PollInterval",
    useColorInMenuBar = "UseColorInMenuBar",
    useColorInMenuBarFailedOnly = "UseColorOnlyForFailedStateInMenuBar",
    showBuildTimerInMenuBar = "ShowTimerInMenu",
    showBuildTimesInMenu = "ShowLastBuildTimes",
    showBuildLabelsInMenu = "ShowLastBuildLabel",
    hideSuccessfulBuildsInMenu = "HideSuccessfulBuilds",
    showStatusInWindow = "ShowPipelineStatusInWindow",
    showAvatarsInWindow = "ShowAvatarsInWindow",
    showMessagesInWindow = "ShowPipelineMessagesInWindow",
    showAppIconInPrefs = "ShowAppIconWhenInPrefs", // to convert legacy defaults
    showAppIcon = "ShowAppIcon"

    public static func key(forNotification n: NotificationType) -> String {
        "SendNotification \(n.rawValue)"
    }

}

extension UserDefaults {
    public static var active = UserDefaults.standard

    public static var transient = {
        let d = UserDefaults(suiteName: "org.ccmenu.transient")!
        d.removePersistentDomain(forName: "org.ccmenu.transient")
        return d
    }()

}

extension AppStorage {

    public init(wrappedValue: Value, _ key: DefaultsKey) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    public init(wrappedValue: Value, _ key: DefaultsKey) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    public init(wrappedValue: Value, _ key: DefaultsKey) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    public init(wrappedValue: Value, _ key: DefaultsKey) where Value == AppIconDefaultValue {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }
    
}
