/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class CCTrayResponseParser {

    var projectList: [Dictionary<String, String>]?

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
                projectList!.append(info)
            }
        }
    }

    func updatePipeline(_ pipeline: Pipeline) -> Pipeline? {
        guard let project = projectList?.first(where: { $0["name"] == pipeline.name }) else {
            return nil
        }

        var newPipeline = pipeline
        newPipeline.webUrl = project["webUrl"]

        newPipeline.activity = activityForString(project["activity"])
        newPipeline.lastBuild = Pipeline.Build(result: resultForString(project["lastBuildStatus"]))
        newPipeline.status = "(not implemented yet)"

        return newPipeline
    }

    func activityForString(_ string: String?) -> PipelineActivity {
        switch string {
            case "Sleeping": return PipelineActivity.sleeping
            case "Building": return PipelineActivity.building
            default: return PipelineActivity.other
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

}
