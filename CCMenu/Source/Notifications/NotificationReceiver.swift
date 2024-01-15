/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import UserNotifications

class NotificationReceiver: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationReceiver()

    func start() {
        UNUserNotificationCenter.current().delegate = self
    }

    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let webUrl = response.notification.request.content.userInfo["webUrl"] as? String
        NSWorkspace.shared.openPipelineWebPage(webUrl)
    }

}

