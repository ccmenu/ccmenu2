/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import UserNotifications

class NotificationFactory {

    func notificationContent(change: StatusChange) -> UNNotificationContent? {
        var content: UNMutableNotificationContent?
        if change.kind == .start {
            content = makeContentObject(title: change.pipeline.name)
            content?.body = "Build started."
            if let facts = factsAboutBuild(change.pipeline.status.lastBuild) {
                content?.body.append("\nLast build: \(facts)")
            }
        } else if change.kind == .completion {
            content = makeContentObject(title: change.pipeline.name)
            let previous = change.previousStatus.lastBuild
            content?.body = resultOfCompletedBuild(change.pipeline.status.lastBuild, previousBuild: previous)
            addTestImage(content: content!)
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
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .full
            formatter.collapsesLargestUnit = true
            if let durationAsString = formatter.string(from: duration) {
                if build.result != .failure {
                    facts = "took \(durationAsString)"
                } else {
                    facts = "failed after \(durationAsString)"
                }
            }
        } else {
            if build.result == .success {
                facts = "successful"
            } else if build.result == .failure {
                facts = "failed"
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

    private func addTestImage(content: UNMutableNotificationContent) {
        do {
            let image1 = try UNNotificationAttachment(identifier: "erik", url: URL(string: "file:///Users/erik/Pictures/erik.jpg")!, options: [:])
            content.attachments = [ image1 ]
        } catch {
            debugPrint(error)
        }
    }


}
