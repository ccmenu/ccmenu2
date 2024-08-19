/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import os

class CCTrayPipelineBuilder: ObservableObject {

    @Published var name: String = ""
    var feedUrl: String = ""
    var project: CCTrayProject? { didSet { setDefaultName() }}

    func setDefaultName() {
        var newName = ""
        if let project, project.isValid {
            newName = project.name
        }
        name = newName
    }
    
    var canMakePipeline: Bool {
        // We're not calling makePipeline, even though that would reduce some
        // duplication, because makePipeline interacts with the keychin.
        return (URL(string: feedUrl) != nil) && (project != nil)
    }


    func makePipeline(credential: HTTPCredential?) -> Pipeline? {
        guard var feedUrl = URL(string: feedUrl) else { return nil }
        feedUrl = Self.applyCredential(credential, toURL: feedUrl)
        guard let project else { return nil }
        let feed = PipelineFeed(type: .cctray, url: feedUrl, name: project.name)
        var p: Pipeline = Pipeline(name: name, feed: feed)
        p.status = PipelineStatus(activity: .sleeping)
        p.status.lastBuild = Build(result: .unknown)
        return p
    }


    static func applyCredential(_ credential: HTTPCredential?, toURL url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return url }
        if let credential, !credential.isEmpty {
            components.user = credential.user
            if !credential.password.isEmpty {
                do {
                    let newUrl = components.url?.absoluteURL ?? url
                    try Keychain.standard.setPassword(credential.password, forURL: newUrl.absoluteString)
                } catch {
                    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
                    logger.error("Error when storing password in keychain: \(error.localizedDescription, privacy: .public)")
                }
            }
        } else {
            components.user = nil
        }
        let newUrl = components.url?.absoluteURL ?? url
        return newUrl
    }

}
