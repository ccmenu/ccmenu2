/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AdvancedSettings: View {
    
    @State var pollIntervalOptions: [Int] = [5, 10, 30, 60, 300, 600]
    @AppStorage(.pollInterval) var pollInterval: Int = 10
    @AppStorage(.pollIntervalLowData) var pollIntervalLowData: Int = 300
    @AppStorage(.showAppIcon) var showAppIcon: AppIconVisibility = .sometimes
    @AppStorage(.openWindowAtLaunch) var openWindowAtLaunch: Bool = false
    @State var openAtLogin = NSApp.openAtLogin { didSet { NSApp.openAtLogin = openAtLogin } }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Poll interval:")
                Spacer()
                Picker("", selection: $pollInterval) {
                    ForEach(pollIntervalOptions, id: \.self) { v in
                        if let label = label(forDuration: v) {
                            Text(label).tag(v)
                        }
                    }
                }
                .frame(maxWidth: 150)
                .padding(.bottom, 4)
            }
            Text("How often CCMenu retrieves status information from the servers. Polling frequently can result in high network traffic, and on GitHub you may run into rate limiting if you have many busy workflows and aren't logged in.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .padding([ .top, .bottom ], 4)

            HStack(alignment: .firstTextBaseline) {
                Text("Low data poll interval:")
                Spacer()
                Picker("", selection: $pollIntervalLowData) {
                    Text("pause").tag(-1)
                    Divider()
                    ForEach(pollIntervalOptions, id: \.self) { v in
                        if let label = label(forDuration: v) {
                            Text(label).tag(v)
                        }
                    }
                }
                .frame(maxWidth: 150)
                .padding(.bottom, 4)
            }
            Text("Poll interval for network connections macOS considers expensive, e.g. mobile hotspots, and for connections that are marked explictly as low data.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .padding([ .top, .bottom ], 4)

            HStack(alignment: .firstTextBaseline) {
                Text("Show app icon:")
                Spacer()
                Picker("", selection: $showAppIcon) {
                    Text("never").tag(AppIconVisibility.never)
                    Text("always").tag(AppIconVisibility.always)
                    Text("sometimes").tag(AppIconVisibility.sometimes)
                }
                .frame(maxWidth: 150)
                .padding(.bottom, 4)
                .onChange(of: showAppIcon) { _ in
                    NSApp.hideApplicationIcon(showAppIcon != .always)
                    NSApp.activateThisApp()
                }
            }
            Text("If set to _sometimes_ the app icon is only shown when a pipeline sheet is open. This can help with switching in and out of CCMenu to copy information like feed URLs.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .padding([ .top, .bottom ], 4)

            // We can't use $openAtLogin. That results in didSet not being called. Why?
            Toggle(isOn: Binding(get: { openAtLogin }, set: { v in openAtLogin = v } )) {
                Text("Open at login")
            }
            .padding(.bottom, 4)
            Text("Whether CCMenu should open when you log in. This is the same as adding CCMenu in the Login Items section in the System Settings app.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .padding([ .top, .bottom ], 4)

            Toggle(isOn: $openWindowAtLaunch) {
                Text("Show pipelines when opened")
            }
            .padding(.bottom, 4)
            Text("Whether the pipelines window should be shown when CCMenu is opened.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom)
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
