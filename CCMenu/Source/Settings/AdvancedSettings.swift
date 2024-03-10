/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AdvancedSettings: View {

    @State var showBuildTimerInMenuBar = false
    @State var pollIntervalOptions: [Int] = [5, 10, 30, 60, 300, 600]
    @AppStorage(.pollInterval) var pollInterval: Int = 10
    @AppStorage(.showAppIcon) var showAppIcon: AppIconDefaultValue = .sometimes


    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Picker("Poll interval:", selection: $pollInterval) {
                    ForEach(pollIntervalOptions, id: \.self) { v in
                        if let label = label(forDuration: v) {
                            Text(label).tag(v)
                        }
                    }
                }
                Text("How often CCMenu retrieves status information from the servers. Polling frequently can result in high network traffic, and on GitHub you may run into rate limiting if you have many busy workflows and aren't logged in.")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.footnote)
                Divider()
                    .padding([ .top, .bottom ], 4)
                Picker("Show app icon:", selection: $showAppIcon) {
                    ForEach(AppIconDefaultValue.allCases) { v in
                        Text(v.rawValue).tag(v)
                    }
                }
                // TODO: Show/hide icon when selection changes
                Text("If set to sometimes the app icon is only shown when a pipeline sheet is open. This can help with switching in and out of CCMenu to copy information like feed URLs.")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.footnote)
               }

        }
        .navigationTitle("Advanced")
        .padding()
    }

    private func label(forDuration seconds: Int) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        return formatter.string(from: Double(seconds))
    }

}


struct AdvancedSettings_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettings()
    }

}
