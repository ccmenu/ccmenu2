/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import AppKit

struct SettingsView: View {
    
    private enum Tab: Hashable {
        case appearance
        case notifications
        case dynamicFeeds
        case advanced
    }

    @State private var selectedTab: Tab = .appearance
    @StateObject private var dynamicFeedSourceModel = DynamicFeedSourceModel.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AppearanceSettings()
            .tag(Tab.appearance)
            .tabItem {
                Image(systemName: "filemenu.and.selection")
                Text("Appearance")
            }
            NotificationSettings()
            .tag(Tab.notifications)
            .tabItem {
                Image(systemName: "bell.badge")
                Text("Notifications")
            }
            DynamicFeedSettings(sourceModel: dynamicFeedSourceModel)
            .tag(Tab.dynamicFeeds)
            .tabItem {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Dynamic Feeds")
            }
            AdvancedSettings()
            .tag(Tab.advanced)
            .tabItem {
                Image(systemName: "gearshape")
                Text("Advanced")
            }
        }
        .frame(width: 400)
    }
}
