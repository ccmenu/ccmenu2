/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

enum MenuSortOrder: Int, CaseIterable, Identifiable {
    case // Int raw values for compatibility with legacy defaults
    asArranged,
    sortedAlphabetically,
    sortedByBuildTime

    // TODO: Wasn't there a way to do without this?
    var id: Self { self }
}

enum AppIconVisibility: String, CaseIterable, Identifiable {
    case
    never,
    sometimes,
    always

    // TODO: Wasn't there a way to do without this?
    var id: Self { self }
}


enum DefaultsKey: String {
    case
    pipelineList = "pipelines",
    pollInterval = "PollInterval",
    pollIntervalLowData = "PollIntervalLowData",
    acceptInvalidCerts = "AcceptInvalidCerts",
    useColorInMenuBar = "UseColorInMenuBar",
    useColorInMenuBarFailedOnly = "UseColorOnlyForFailedStateInMenuBar",
    showBuildTimerInMenuBar = "ShowTimerInMenu",
    orderInMenu = "ProjectOrder",
    showBuildTimesInMenu = "ShowLastBuildTimes",
    showBuildLabelsInMenu = "ShowLastBuildLabel",
    hideSuccessfulBuildsInMenu = "HideSuccessfulBuilds",
    showStatusInWindow = "ShowPipelineStatusInWindow",
    showAvatarsInWindow = "ShowAvatarsInWindow",
    showMessagesInWindow = "ShowPipelineMessagesInWindow",
    showAppIconInPrefs = "ShowAppIconWhenInPrefs", // to convert legacy defaults
    showAppIcon = "ShowAppIcon"

    static func key(forNotification n: NotificationType) -> String {
        "SendNotification \(n.rawValue)"
    }

}

extension UserDefaults {
    static var active = UserDefaults.standard

    static var transient = {
        let d = UserDefaults(suiteName: "org.ccmenu.transient")!
        d.removePersistentDomain(forName: "org.ccmenu.transient")
        return d
    }()

    func stringRepresentable<T: RawRepresentable>(forKey key: String) -> T? where T.RawValue == String {
        guard let v = string(forKey: key) else { return nil }
        return T(rawValue: v)
    }
}

extension AppStorage {

    init(wrappedValue: Value, _ key: DefaultsKey) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    init(wrappedValue: Value, _ key: DefaultsKey) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    init(wrappedValue: Value, _ key: DefaultsKey) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    // TODO: Find out how to combine the following cases, which are all RawRepresentable

    init(wrappedValue: Value, _ key: DefaultsKey) where Value == MenuSortOrder {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

    init(wrappedValue: Value, _ key: DefaultsKey) where Value == AppIconVisibility {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: UserDefaults.active)
    }

}
