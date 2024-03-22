/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine
import UserNotifications

class NotificationSender {

    private var model: PipelineModel
    private var factory: NotificationFactory
    private var subscribers: [AnyCancellable] = []

    init(model: PipelineModel) {
        self.model = model
        self.factory = NotificationFactory()
    }

    func start() {
        model.$lastStatusChange
            .sink(receiveValue: statusChanged(change:))
            .store(in: &subscribers)
    }

    private func statusChanged(change: StatusChange?) {
        if let change = change, let content = factory.notificationContent(change: change) {
            Task { try await send(content: content) }
        }
    }

    private func send(content: UNNotificationContent) async throws {
        let center = UNUserNotificationCenter.current()
        try await center.requestAuthorization(options: [.alert])
        let settings = await center.notificationSettings()
        if settings.authorizationStatus != .authorized || settings.alertSetting != .enabled {
            return
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await center.add(request)
    }

}
