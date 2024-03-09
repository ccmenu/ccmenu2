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
    @AppStorage(.hideSuccessfulBuildsInMenu) var hideSuccessfulBuildsInMenu = false

    var body: some View {
        VStack {
            Form {
                Text("Menu bar")
                    .font(.headline)
                Toggle(isOn: $showBuildTimerInMenuBar) {
                    Text("Show build timer")
                    Text("Negative values represent estimated time to complete based on previous build. Positive values are shown when the build is taking longer than the previous build.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                Toggle(isOn: $useColorInMenuBar) {
                    Text("Use colored icons")
                }
                .onChange(of: useColorInMenuBar) { newValue in
                    if newValue == false {
                        useColorInMenuBarFailedOnly = false
                    }
                }
                Toggle(isOn: $useColorInMenuBarFailedOnly) {
                    Text("only when build is broken")
                }
                .padding(.leading, 20)
                .disabled(!useColorInMenuBar)

                Divider()
                    .padding([ .top, .bottom ], 4)

                Text("Menu items")
                    .font(.headline)
                Toggle(isOn: $showBuildTimesInMenu) {
                    Text("Show time of last build")
                }
                Toggle(isOn: $showBuildLabelsInMenu) {
                    Text("Show label of last build")
                }
                Toggle(isOn: $hideSuccessfulBuildsInMenu) {
                    Text("Hide pipelines with successful build")
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Appearance")
        .padding()
    }

}


struct AppearanceSettings_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettings()
            .frame(width: 350)
    }

}
