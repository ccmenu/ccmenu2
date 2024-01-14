/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct NotificationSettings: View {

    var body: some View {
            Text("missing")
                .frame(width: 300, height: 400)
            .navigationTitle("Notifications")
            .padding(80)
    }

}


struct NotificationSettings_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettings()
    }

}


//         Task { try await center.requestAuthorization(options: [.alert]) }

