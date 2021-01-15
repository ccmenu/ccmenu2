/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AppearanceSettings: View {

    @AppStorage("StatusItem.UseColorInMenuBar")
    private var useColorInMenuBar: Bool = false

    var body: some View {

            Toggle(isOn: $useColorInMenuBar) {
                Text("Use color in menu bar")
            }

        .frame(width: 300)

        .navigationTitle("Landmark Settings")

        .padding(80)

    }

}


struct LandmarkSettings_Previews: PreviewProvider {

    static var previews: some View {

        AppearanceSettings()

    }

}
