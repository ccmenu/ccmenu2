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
            status.activity = activityForString(pipelineStatus)
        }

        if status.activity == .building {
            status.currentBuild = build(pipeline: latest)
            if let completed = pipelineList.first(where: isCompletedSuccessful(pipeline:)) ??
                                pipelineList.first(where: isCompleted(pipeline:)) {
                status.lastBuild = build(pipeline: completed)
            }
         } else {
            status.lastBuild = build(pipeline: latest)
        }

        return status
    }

    private func build(pipeline: Dictionary<String, Any>) -> Build {
        let status = pipeline["status"] as? String
        var build = Build(result: resultForString(status))

        if let pipelineId = pipeline["iid"] as? Int {
            build.label = String(pipelineId)
        }

        // TODO: AI generated code - rework to get actual run start if possible
        if let createdAt = pipeline["created_at"] as? String, let createdAtDate = dateForString(createdAt) {
            build.timestamp = createdAtDate
            if let updatedAt = pipeline["updated_at"] as? String, let updatedAtDate = dateForString(updatedAt) {
                build.duration = updatedAtDate.timeIntervalSince(createdAtDate)
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

        // GitLab doesn't include user info directly in pipeline API response
        // We would need to make an additional API call to get user details
        // For now, we'll leave user and avatar empty

        return build
    }

    private func isCompleted(pipeline: Dictionary<String, Any>) -> Bool {
        return activityForString(pipeline["status"] as? String) == .sleeping
    }

    private func isCompletedSuccessful(pipeline: Dictionary<String, Any>) -> Bool {
        return resultForString(pipeline["status"] as? String) == .success
    }

    func activityForString(_ string: String?) -> PipelineStatus.Activity {
        switch string {
            case "running", "pending": return .building
            case "success", "failed", "canceled", "skipped", "manual", "scheduled": return .sleeping
            default: return .other
        }
    }

    func resultForString(_ string: String?) -> BuildResult {
        switch string {
            case "success": return .success
            case "failed": return .failure
            case "canceled", "skipped", "manual", "scheduled": return .other
            default: return .unknown
        }
    }

    func dateForString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}
