/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */


import Foundation

class CCTrayPipelineBuilder: ObservableObject {

    @Published var name: String = ""
    var project: CCTrayProject? { didSet { setDefaultName() }}

    func setDefaultName() {
        var newName = ""
        if let project, project.isValid {
            newName = project.name
        }
        name = newName
    }
    
    
    func makePipeline(feedUrl: String, credential: HTTPCredential?) -> Pipeline? {
        var feedUrl = feedUrl
        if let credential {
            feedUrl = setUser(credential.user, inURL: feedUrl)
            do {
                try Keychain().setPassword(credential.password, forURL: feedUrl)
            } catch {
                // TODO: Figure out what to do here – so many errors...
            }
        }
        guard let project else { return nil }
        guard let url = URL(string: feedUrl) else { return nil }
        let feed = Pipeline.Feed(type: .cctray, url: url, name: project.name)
        var p: Pipeline = Pipeline(name: name, feed: feed)
        p.status = Pipeline.Status(activity: .sleeping)
        p.status.lastBuild = Build(result: .unknown)
        return p
    }

    private func setUser(_ user: String?, inURL urlString: String) -> String {
        guard let user, !user.isEmpty else {
            return urlString
        }
        guard var url = URLComponents(string: urlString) else {
            return urlString
        }
        url.user = user
        guard let newUrlString = url.string else {
            return ""
        }
        return newUrlString
    }

}
