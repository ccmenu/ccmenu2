/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class CCTrayResponseParser {

    var projectList: [Dictionary<String, String>] = []

    func parseResponse(_ data: Data) throws {
        projectList = []
        let doc = try XMLDocument(data: data, options: [])
        for node in try doc.nodes(forXPath: "//Project") {
            if let element = node as? XMLElement {
                var info = [String: String]()
                if let attributes = element.attributes {
                    for attribute in attributes {
                        if let name = attribute.name, let value = attribute.stringValue {
                            info[name] = value
                        }
                    }
                }
                projectList.append(info)
            }
        }
    }

    func pipelineStatus(name: String) -> PipelineStatus? {
        guard let project = projectList.first(where: { $0["name"] == name }) else { return nil }
        var status = PipelineStatus(activity: activityForString(project["activity"]))
        status.webUrl = project["webUrl"]

        var build = Build(result: resultForString(project["lastBuildStatus"]))
        build.label = project["lastBuildLabel"]
        if let lastBuildTime = project["lastBuildTime"], let date = dateForString(lastBuildTime) {
            build.timestamp = date
        }
        status.lastBuild = build

        if status.activity == .building {
            status.currentBuild = Build(result: .unknown)
        }

        return status
    }

    func activityForString(_ string: String?) -> PipelineStatus.Activity {
        switch string {
            case "Sleeping": return .sleeping
            case "Building": return .building
            default: return .other
        }
    }

    func resultForString(_ string: String?) -> BuildResult {
        switch string {
            case "Success": return BuildResult.success
            case "Failure": return BuildResult.failure
            case "Exception": return BuildResult.failure
            case "Unknown": return BuildResult.unknown
            default: return BuildResult.unknown
        }
    }

    func dateForString(_ string: String) -> Date? {
        if string.count <= 19 {
            // assume old-style CruiseControl timestamp without timezone, assume local time
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
            return formatter.date(from: string)
        } else {
            // assume some kind of ISO8601 date format
            let formatter = ISO8601DateFormatter()
            // Apple's parser doesn't seem to like fractional components; so we remove them
            var cleaned = string
            if let range = string.range(of: "[.,][0-9]+", options: .regularExpression) {
                cleaned.removeSubrange(range)
            }
            return formatter.date(from: cleaned)
        }
    }

}
