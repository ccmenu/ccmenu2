/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AppearanceSettings: View {

    @ObservedObject var settings: UserSettings

    var body: some View {
        VStack {
            Toggle(isOn: $settings.showBuildTimerInMenuBar) {
                Text("Show build timer in menu bar")
            }
            Toggle(isOn: $settings.useColorInMenuBar) {
                Text("Use color in menu bar")
            }
            Toggle(isOn: $settings.useColorInMenuBarFailedOnly) {
                Text("Use color for failed builds only ")
            }
            Toggle(isOn: $settings.showBuildLabelsInMenu) {
                Text("Show build labels in menu")
            }
            Toggle(isOn: $settings.showBuildTimesInMenu) {
                Text("Show build times in menu")
            }
        }
        .frame(width: 300)
        .navigationTitle("Appearance")
        .padding(80)
    }

}


struct AppearanceSettings_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettings(settings: settingsForPreview())
    }

    private static func settingsForPreview() -> UserSettings {
        let s = UserSettings()
        s.useColorInMenuBar = true
        return s
    }

}
