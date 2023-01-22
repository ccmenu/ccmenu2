/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class GithubResponseParser {

    var runList: [Dictionary<String, Any>] = []

    func parseResponse(_ data: Data) throws {
        if let response = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> {
            runList = response["workflow_runs"] as? [Dictionary<String, Any>] ?? []
        } else {
            runList = []
        }
    }

    func pipelineStatus(name: String) -> Pipeline.Status? {
        guard let latest = runList.first else {
            return nil
        }

        var status = Pipeline.Status(activity: .other)
        status.webUrl = latest["html_url"] as? String
        if let wfStatus = latest["status"] as? String {
            status.activity = activityForString(wfStatus)
        }

        if status.activity == .building {
            status.currentBuild = build(run: latest)
            if let completed = runList.first(where: isCompletedSuccessful(run:)) ??
                                runList.first(where: isCompleted(run:)) {
                status.lastBuild = build(run: completed)
            }
         } else {
            status.lastBuild = build(run: latest)
        }

        return status
    }

    private func build(run: Dictionary<String, Any>) -> Build {
        let conclusion = run["conclusion"] as? String
        var build = Build(result: resultForString(conclusion))

        if let runNumber = run["run_number"] as? Int {
            build.label = String(runNumber)
        }

        if let createdAt = run["created_at"] as? String , let createdAtDate = dateForString(createdAt) {
            build.timestamp = createdAtDate
            if let updatedAt = run["updated_at"] as? String, let updatedAtDate = dateForString(updatedAt) {
                build.duration = updatedAtDate.timeIntervalSince(createdAtDate)
            }
        }

        var messageParts: [String] = []
        if let event = run["event"] as? String {
            let prettified = event.replacingOccurrences(of: "_", with: " ").capitalized
            messageParts.append("\(prettified)")
//            messageParts.append("\u{3014}\(event.uppercased())\u{3015}")
        }
        if let displayTitle = run["display_title"] as? String {
            messageParts.append(displayTitle)
        }
        if messageParts.count > 0 {
            build.message = messageParts.joined(separator: " \u{279E} ")
        }

        if let actor = run["actor"] as? Dictionary<String, Any?> {
            if let actorLogin = actor["login"] as? String   {
                build.user = actorLogin
            }
            if let actorAvatarUrl = actor["avatar_url"] as? String   {
                build.avatar = URL(string: actorAvatarUrl)
            }
        }

        return build
    }

    private func isCompleted(run: Dictionary<String, Any>) -> Bool {
        return activityForString(run["status"] as? String) == .sleeping
    }

    private func isCompletedSuccessful(run: Dictionary<String, Any>) -> Bool {
        return isCompleted(run: run) && resultForString(run["conclusion"] as? String) == .success
    }

    func activityForString(_ string: String?) -> Pipeline.Activity {
        switch string {
            case "completed": return .sleeping
            case "in_progress": return .building
            default: return .other
        }
    }

    func resultForString(_ string: String?) -> BuildResult {
        switch string {
            case "success": return .success
            case "failure": return .failure
            default: return .unknown
        }
    }

    func dateForString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }


}

