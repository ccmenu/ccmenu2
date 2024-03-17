/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

extension URLSession {

    public static var feedSession = makeFeedSession()

    private static func makeFeedSession() -> URLSession {
        let config = URLSessionConfiguration.default
        // TODO: Figure out why it uses permanent credential storage here
        // p credentialStorage?.allCredentials.values.first?.values.first?.persistence
        config.urlCache = URLCache(memoryCapacity: 10*1024*1024, diskCapacity: 0)
        let session = URLSession(configuration: config, delegate: FeedSessionDelegate(), delegateQueue: nil)
        return session
    }
}

class FeedSessionDelegate: NSObject, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:
            // TODO: figure out what to do if we end up here
            // We should only end up here if we didn't provide credentials but the server requires
            // authentication or if the credentials provided are not accepted. Note: Realistically
            // this is the only place to discover the authentication realm the server uses, should
            // we need to expose that to the user.
            debugPrint("received authentication challenge for \(challenge.protectionSpace)")
            completionHandler(.performDefaultHandling, nil)
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }

}
