/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AppearanceSettings: View {

    @AppStorage(.useColorInMenuBar) var useColorInMenuBar = true
    @AppStorage(.useColorInMenuBarFailedOnly) var useColorInMenuBarFailedOnly = true
    @AppStorage(.showBuildTimerInMenuBar) var showBuildTimerInMenuBar = true
    @AppStorage(.showBuildTimesInMenu) var showBuildTimesInMenu = false
    @AppStorage(.showBuildLabelsInMenu) var showBuildLabelsInMenu = false

    var body: some View {
        VStack {
            Toggle(isOn: $useColorInMenuBar) {
                Text("Use color in menu bar")
            }
            .onChange(of: useColorInMenuBar) { newValue in
                if newValue == false {
                    useColorInMenuBarFailedOnly = false
                }
            }
            Toggle(isOn: $useColorInMenuBarFailedOnly) {
                Text("Use color for failed builds only ")
            }
            .disabled(!useColorInMenuBar)
            Toggle(isOn: $showBuildTimerInMenuBar) {
                Text("Show build timer in menu bar")
            }
            Toggle(isOn: $showBuildTimesInMenu) {
                Text("Show build times in menu")
            }
            Toggle(isOn: $showBuildLabelsInMenu) {
                Text("Show build labels in menu")
            }

        }
        .frame(width: 300)
        .navigationTitle("Appearance")
        .padding(80)
    }

}


struct AppearanceSettings_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettings()
    }

}
