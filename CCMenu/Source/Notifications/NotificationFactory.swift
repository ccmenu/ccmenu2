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
        var content = UNMutableNotificationContent()
        switch change.kind {
        case .start:
            if !shouldSendStartNotification(change: change) {
                return nil
            }
            addContentForStartedNotification(content, change: change)
        case .completion:
            if !shouldSendFinishedNotification(change: change) {
                return nil
            }
            addContentForFinishedNotification(content, change: change)
        default:
            return nil
        }
        if let webUrl = change.pipeline.status.webUrl {
            addWebUrl(webUrl, to: content)
        }
        return content
    }

    private func shouldSendStartNotification(change: StatusChange) -> Bool {
        UserDefaults.active.bool(forKey: DefaultsKey.key(forNotification: .started))
    }

    private func addContentForStartedNotification(_ content: UNMutableNotificationContent, change: StatusChange) {
        content.title = "Build started"
        content.body = change.pipeline.name
        if let build = change.pipeline.status.lastBuild, let facts = factsAboutBuild(build) {
            content.body.append("\n\(facts)")
        }
    }

    private func factsAboutBuild(_ build: Build) -> String? {
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

    private func shouldSendFinishedNotification(change: StatusChange) -> Bool {
        let type = notificationTypeForBuild(change.pipeline.status.lastBuild, previousBuild: change.previousStatus.lastBuild)
        return UserDefaults.active.bool(forKey: DefaultsKey.key(forNotification: type))

    }

    private func addContentForFinishedNotification(_ content: UNMutableNotificationContent, change: StatusChange) {
        content.title = "Build finished"
        let status = change.pipeline.status
        let type = notificationTypeForBuild(status.lastBuild, previousBuild: change.previousStatus.lastBuild)
        if let description = desciptionForType(type) {
            content.title.append(": \(description)")
        }
        content.body = change.pipeline.name
//        if let build = status.lastBuild {
//            attachImage(forBuild: build, to: content)
//        }
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
    
    private func desciptionForType(_ type: NotificationType) -> String? {
        switch type {
        case .wasSuccessful: return "success"
        case .wasBroken:     return "broken"
        case .wasFixed:      return "fixed"
        case .isStillBroken: return "still broken"
        default:             return nil
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

}
