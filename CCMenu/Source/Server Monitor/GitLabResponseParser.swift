/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class GitLabResponseParser {

    var pipelineList: [Dictionary<String, Any>] = []

    func parseResponse(_ data: Data) throws {
        if let response = try JSONSerialization.jsonObject(with: data, options: []) as? [Dictionary<String, Any>] {
            pipelineList = response
        } else {
            pipelineList = []
        }
    }

    func pipelineStatus(name: String) -> PipelineStatus? {
        guard let latest = pipelineList.first else { return nil }
        var status = PipelineStatus(activity: .other)
        status.webUrl = latest["web_url"] as? String
        if let pipelineStatus = latest["status"] as? String {
            status.activity = GitLabResponseParser.activityForString(pipelineStatus)
        }

        if status.activity == .building {
            status.currentBuild = GitLabResponseParser.build(pipeline: latest)
            if let completed = pipelineList.first(where: isCompletedSuccessful(pipeline:)) ??
                pipelineList.first(where: GitLabResponseParser.isCompleted(pipeline:)) {
                status.lastBuild = GitLabResponseParser.build(pipeline: completed)
            }
         } else {
             status.lastBuild = GitLabResponseParser.build(pipeline: latest)
        }

        return status
    }

    fileprivate static func build(pipeline: Dictionary<String, Any>) -> Build {
        let status = pipeline["status"] as? String
        var build = Build(result: resultForString(status))

        if let pipelineId = pipeline["id"] as? Int {
            build.id = String(pipelineId)
        }

        if let pipelineIid = pipeline["iid"] as? Int {
            build.label = String(pipelineIid)
        }

        if let createdAt = pipeline["created_at"] as? String, let createdAtDate = dateForString(createdAt) {
            build.timestamp = createdAtDate
            // This is only present when called with a response with the pipeline detail
            if let duration = pipeline["duration"] as? Int {
                build.duration = Double(duration)
            }
        }

        var messageParts: [String] = []
        if let source = pipeline["source"] as? String {
            let prettified = source.replacingOccurrences(of: "_", with: " ").capitalized
            messageParts.append(prettified)
        }
        if let sha = pipeline["sha"] as? String, sha.count >= 7 {
            let shortSha = String(sha.prefix(7))
            messageParts.append("Commit \(shortSha)")
        }
        if messageParts.count > 0 {
            build.message = messageParts.joined(separator: " \u{22EE} ")
        }

        // This is only present when called with a response with the pipeline detail
        if let user = pipeline["user"] as? Dictionary<String, Any> {
            build.user = user["name"] as? String
            if let avatar = user["avatar_url"] as? String {
                build.avatar = URL(string: avatar)
            }
        }

        return build
    }

    private static func isCompleted(pipeline: Dictionary<String, Any>) -> Bool {
        return GitLabResponseParser.activityForString(pipeline["status"] as? String) == .sleeping
    }

    private func isCompletedSuccessful(pipeline: Dictionary<String, Any>) -> Bool {
        return GitLabResponseParser.resultForString(pipeline["status"] as? String) == .success
    }

    static func activityForString(_ string: String?) -> PipelineStatus.Activity {
        switch string {
            case "running", "pending": return .building
            case "success", "failed", "canceled", "skipped", "manual", "scheduled": return .sleeping
            default: return .other
        }
    }

    static func resultForString(_ string: String?) -> BuildResult {
        switch string {
            case "success": return .success
            case "failed": return .failure
            case "canceled", "skipped", "manual", "scheduled": return .other
            default: return .unknown
        }
    }

    static func dateForString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}


class GitLabDetailResponseParser {

    var pipelineDetail: Dictionary<String, Any> = [:]

    func parseResponse(_ data: Data) throws {
        if let response = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> {
            pipelineDetail = response
        } else {
            pipelineDetail = [:]
        }
    }

    func build() -> Build {
        GitLabResponseParser.build(pipeline: pipelineDetail)
    }

}
