/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import UserNotifications


public enum NotificationType: String {
    case // raw values for compatibility with legacy defaults
    started = "Starting",
    wasSuccessful = "Successful",
    wasBroken = "Broken",
    wasFixed = "Fixed",
    isStillBroken = "StillFailing",
    finished = "Finished"
}

class NotificationFactory {

    func notificationContent(change: StatusChange) -> UNNotificationContent? {
        switch change.kind {
        case .start:
            return notificationContentForStarted(change: change)
        case .completion:
            return notificationContentForFinished(change: change)
        default:
            return nil
        }
    }

    private func notificationContentForStarted(change: StatusChange) -> UNNotificationContent? {
        if !UserDefaults.active.bool(forKey: DefaultsKey.key(forNotification: .started)) {
            return nil
        }
        let content = makeContentObject(title: change.pipeline.name)
        content.body = "Build started."
        if let facts = factsAboutBuild(change.pipeline.status.lastBuild) {
            content.body.append("\n\(facts)")
        }
        if let webUrl = change.pipeline.status.webUrl {
            addWebUrl(webUrl, to: content)
        }
        return content
    }

    private func notificationContentForFinished(change: StatusChange) -> UNNotificationContent? {
        let status = change.pipeline.status
        let type = notificationTypeForBuild(status.lastBuild, previousBuild: change.previousStatus.lastBuild)
        if !UserDefaults.active.bool(forKey: DefaultsKey.key(forNotification: type)) {
            return nil
        }
        let content = makeContentObject(title: change.pipeline.name)
        switch type {
        case .wasSuccessful: content.body = "The build was successful.";       break
        case .wasBroken:     content.body = "Recent changes broke the build."; break
        case .wasFixed:      content.body = "Recent changes fixed the build."; break
        case .isStillBroken: content.body = "The build is still broken.";      break
        default:             content.body = "The build finished.";             break
        }
        if let build = status.lastBuild {
            if let duration = build.duration, let durationAsString = formattedDurationPrecise(duration) {
                content.body.append("\nTime: \(durationAsString)")
            }
            attachImage(forBuild: build, to: content)
        }
        if let webUrl = status.webUrl {
            addWebUrl(webUrl, to: content)
        }
        return content
    }

    private func makeContentObject(title: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(title)"
        return content
    }

    private func factsAboutBuild(_ build: Build?) -> String? {
        guard let build = build else {
            return nil
        }
        var facts: String? = nil
        if let duration = build.duration {
            if let durationAsString = formattedDuration(duration) {
                if build.result != .failure {
                    facts = "Last build took \(durationAsString)."
                } else {
                    facts = "Last build failed after \(durationAsString)."
                }
            }
        } else {
            if build.result == .success {
                facts = "Last build was successful."
            } else if build.result == .failure {
                facts = "Last build failed."
            }
        }
        return facts
    }

    private func notificationTypeForBuild(_ build: Build?, previousBuild previous: Build?) -> NotificationType {
        switch build?.result {
        case .success:
            return (previous?.result == .failure) ? .wasFixed : .wasSuccessful
        case .failure:
            return (previous?.result != .failure) ? .wasBroken : .isStillBroken
        default:
            return .finished
        }
    }
    
    private func attachImage(forBuild build: Build, to content: UNMutableNotificationContent) {
        do {
            guard let imageUrl = NSImage.urlOfImage(forResult: build.result) else {
                return
            }
            let attachment = try UNNotificationAttachment(identifier: build.result.rawValue, url: imageUrl, options: [:])
            content.attachments = [ attachment ]
        } catch {
            debugPrint(error)
        }
    }

    private func addWebUrl(_ webUrl: String, to content: UNMutableNotificationContent) {
        content.userInfo["webUrl"] = webUrl
    }

    private func formattedDuration(_ duration: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        formatter.collapsesLargestUnit = true
        return formatter.string(from: duration)
    }

    private func formattedDurationPrecise(_ duration: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 2
        return formatter.string(from: duration)
    }

}
