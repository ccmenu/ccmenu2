/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */


import SwiftUI

struct CCTrayAuthView: View {
    @Binding var useBasicAuth: Bool
    @Binding var credential: HTTPCredential
    
    var body: some View {
        GroupBox() {
            VStack(alignment: .leading) {
                Toggle(isOn: $useBasicAuth) {
                    Text("Use HTTP Basic Authentication")
                }
                .accessibilityIdentifier("Basic auth toggle")
                HStack {
                    TextField("", text: $credential.user, prompt: Text("user"))
                        .accessibilityIdentifier("User field")
                    SecureField("", text: $credential.password, prompt: Text("password"))
                        .accessibilityIdentifier("Password field")
                }
                .disabled(!useBasicAuth)
            }
            .padding(8)
        }
    }
}
