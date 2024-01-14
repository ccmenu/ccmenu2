/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import UserNotifications

class NotificationFactory {

    func notificationContent(change: StatusChange) -> UNNotificationContent? {
        if change.kind == .start {
            let content = makeContentObject(title: change.pipeline.name)
            content.body = "Build started."
            if let facts = factsAboutBuild(change.pipeline.status.lastBuild) {
                content.body.append("\n\(facts)")
            }
            return content
        } else if change.kind == .completion {
            let content = makeContentObject(title: change.pipeline.name)
            let status = change.pipeline.status
            let previous = change.previousStatus
            content.body = resultOfCompletedBuild(status.lastBuild, previousBuild: previous.lastBuild)
            if let build = status.lastBuild {
                if let duration = build.duration, let durationAsString = formattedDurationPrecise(duration) {
                    content.body.append("\nTime: \(durationAsString)")
                }
                attachImage(forBuild: build, to: content)
            }
            return content
       }
        return nil
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

    private func resultOfCompletedBuild(_ build: Build?, previousBuild previous: Build?) -> String {
        switch build?.result {
        case .success:
            if previous?.result == .failure {
                return "Recent changes fixed the build."
            }
            return "Build completed successfully."
        case .failure:
            if previous?.result != .failure {
                return "Recent changes broke the build."
            }
            return "The build is still broken."
        default:
            return "Build completed with an indeterminate result."
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
