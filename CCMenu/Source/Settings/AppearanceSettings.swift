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
    @AppStorage(.orderInMenu) var orderInMenu = .asArranged
    @AppStorage(.showBuildTimesInMenu) var showBuildTimesInMenu = false
    @AppStorage(.showBuildLabelsInMenu) var showBuildLabelsInMenu = false
    @AppStorage(.hideSuccessfulBuildsInMenu) var hideSuccessfulBuildsInMenu = false
    @State var sortPipelineInMenu = 0

    var body: some View {
        VStack {
            Form {
                Toggle(isOn: $showBuildTimerInMenuBar) {
                    Text("Show build timer in menu bar")
                    Text("Negative values represent estimated time to complete based on previous build. Positive values are shown when the build is taking longer than the previous build.")
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                    .padding([ .top, .bottom ], 4)

                Toggle(isOn: $useColorInMenuBar) {
                    Text("Use colored icons in menu bar")
                }
                .onChange(of: useColorInMenuBar) { _, newValue in
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

                Text("Display pipelines in menu:")
                Picker("", selection: $orderInMenu) {
                    Text("as arranged in pipeline window").tag(MenuSortOrder.asArranged)
                        .accessibilityIdentifier("Order as arranged")
                    Text("alphabetically").tag(MenuSortOrder.sortedAlphabetically)
                        .accessibilityIdentifier("Order alphabetically")
                    Text("ordered by last build time").tag(MenuSortOrder.sortedByBuildTime)
                        .accessibilityIdentifier("Order last build time")
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .padding(.bottom, 8)
                
                Toggle(isOn: $showBuildTimesInMenu) {
                    Text("with time of last build")
                }
                .accessibilityIdentifier("Show time")
                Toggle(isOn: $showBuildLabelsInMenu) {
                    Text("with label of last build")
                }
                .accessibilityIdentifier("Show label")
                .padding(.bottom, 8)

                Toggle(isOn: $hideSuccessfulBuildsInMenu) {
                    Text("only when last build was not successful")
                }
                .accessibilityIdentifier("Hide successful builds")
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
