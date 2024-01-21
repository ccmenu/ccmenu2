/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import UserNotifications


struct NotificationSettings: View {

    @AppStorage(.sendNotificationStarted) var notificationStarted = false
    @AppStorage(.sendNotificationSuccessful) var notificationSuccessful = true
    @AppStorage(.sendNotificationBroken) var notificationBroken = true
    @AppStorage(.sendNotificationFixed) var notificationFixed = true
    @AppStorage(.sendNotificationStillFailing) var notificationStillFailing = true

    var body: some View {
        VStack {
            Form {
                Toggle(isOn: $notificationStarted) {
                    Text("Build started")
                    Text("A build has started on the server.")
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                    .padding([ .top, .bottom ], 4)
                
                Toggle(isOn: $notificationSuccessful) {
                    Text("Build finished: successful")
                    Text("The previous build was successful, and the last build finished sucessfully, too.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                Toggle(isOn: $notificationBroken) {
                    Text("Build finished: broken")
                    Text("The previous build was successful, but the last build failed.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                Toggle(isOn: $notificationFixed) {
                    Text("Build finished: fixed")
                    Text("The build was broken, and the last build finished successfully.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                Toggle(isOn: $notificationStillFailing) {
                    Text("Build finished: still failing")
                    Text("The build was broken, and the last build failed, too.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Notifications")
        .padding()
        .onAppear() {
            let center = UNUserNotificationCenter.current()
            Task { try await center.requestAuthorization(options: [.alert]) }
        }
    }

}


struct NotificationSettings_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettings()
            .frame(width: 350)

    }

}



