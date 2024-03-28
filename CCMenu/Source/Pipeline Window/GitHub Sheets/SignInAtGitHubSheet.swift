/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


struct SignInAtGitHubSheet: View {
    @EnvironmentObject private var authenticator: GitHubAuthenticator
    @Environment(\.presentationMode) @Binding var presentation

    var body: some View {
        VStack {
            Text("Sign in at GitHub")
                .font(.headline)
                .padding(.bottom)
            Text("The token you set here will be used for all GitHub pipelines.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            Form {
                HStack {
                    TextField("", text: $authenticator.tokenDescription)
                        .accessibilityIdentifier("Token field")
                        .labelsHidden()
                        .truncationMode(.tail)
                        .disabled(true)
                }
                .padding(.bottom)
            }

            VStack {
                Button() {
                    authenticator.storeTokenInKeychain()
                    presentation.dismiss()
                } label: {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(authenticator.isWaitingForToken || authenticator.token == nil)
                .frame(idealWidth: 250)
                Button(role: .cancel) {
                    if authenticator.isWaitingForToken {
                        authenticator.cancelSignIn()
                    }
                    presentation.dismiss()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.cancelAction)
           }
        }
        .frame(minWidth: 250)
        .frame(idealWidth: 250)
        .padding()
    }

}



struct SignInAtGitHubSheet_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var ghAuthenticator = GitHubAuthenticator()
        SignInAtGitHubSheet()
            .environmentObject(ghAuthenticator)
    }
}
