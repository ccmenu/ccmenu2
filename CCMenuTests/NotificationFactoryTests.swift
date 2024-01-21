/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class NotificationFactoryTests: XCTestCase {

    private var factory: NotificationFactory!
    private var pipeline: Pipeline!
    private var defaults: UserDefaults!

    override func setUp() {
        factory = NotificationFactory()
        pipeline = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: ""))
        UserDefaults.active = UserDefaults.transient
        defaults = UserDefaults.active
    }

    // MARK: - start

    func testDoesntCreateStartNotificationIfDefaultIsFalse() throws {
        defaults.set(false, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status.activity = .building
        let previous = Pipeline.Status(activity: .sleeping)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        defaults.set(false, forKey: DefaultsKey.sendNotificationStarted.rawValue)

        let notification = factory.notificationContent(change: change)

        XCTAssertNil(notification)
    }

    func testCreatesBasicStartNotification() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status.activity = .building
        let previous = Pipeline.Status(activity: .sleeping)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertNotNil(notification)
        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Build started.", notification?.body)
    }

    func testCreatesStartNotificationWithSuccessfulLastBuild() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status.activity = .building
        pipeline.status.lastBuild = Build(result: .success)
        let previous = Pipeline.Status(activity: .sleeping)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Build started.\nLast build was successful.", notification?.body)
    }

    func testCreatesStartNotificationWithSuccessfulLastBuildWithDurationThatNeedsRounding() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status = Pipeline.Status(activity: .building, lastBuild: Build(result: .success, duration: 65))
        let previous = Pipeline.Status(activity: .sleeping)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Build started.\nLast build took 1 minute.", notification?.body)
    }

    func testCreatesStartNotificationWithFailedLastBuildWithDurationThatCanBeCollapsed() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status = Pipeline.Status(activity: .building, lastBuild: Build(result: .failure, duration: 62*60))
        let previous = Pipeline.Status(activity: .sleeping)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Build started.\nLast build failed after 62 minutes.", notification?.body)
    }

    func testCreatesStartNotificationWithUnknownLastBuildWithDurationThatNeedsHoursAndMinutes() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status = Pipeline.Status(activity: .building, lastBuild: Build(result: .unknown, duration: 7500))
        let previous = Pipeline.Status(activity: .sleeping)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Build started.\nLast build took 2 hours, 5 minutes.", notification?.body)
    }

    func testAddsWebUrlToUserInfoToStartNotification() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStarted.rawValue)
        pipeline.status = Pipeline.Status(activity: .building, lastBuild: Build(result: .success), webUrl: "http://localhost/connectfour")
        let previous = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .other))
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("http://localhost/connectfour", notification?.userInfo["webUrl"] as? String)
    }

    // MARK: - completion

    func testDoesntCreateCompletionNotificationIfDefaultIsFalse() throws {
        defaults.set(false, forKey: DefaultsKey.sendNotificationSuccessful.rawValue)
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success))
        let previous = Pipeline.Status(activity: .building)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertNil(notification)
    }

    func testCreatesCompletionNotificationForSuccessfulBuildWithDuration() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationSuccessful.rawValue)
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success, duration: 300))
        let previous = Pipeline.Status(activity: .building)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("The build was successful.\nTime: 5m", notification?.body)
    }

    func testCreatesCompletionNotificationForSuccessfulBuildFollowingFailedBuild() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationFixed.rawValue)
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success))
        let previous = Pipeline.Status(activity: .building, lastBuild: Build(result: .failure))
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Recent changes fixed the build.", notification?.body)
    }

    func testCreatesCompletionNotificationForFailedBuildWithTime() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationBroken.rawValue)
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .failure, duration: 300))
        let previous = Pipeline.Status(activity: .building)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("Recent changes broke the build.\nTime: 5m", notification?.body)
    }

    func testCreatesCompletionNotificationForFailedBuildFollowingFailedBuild() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationStillFailing.rawValue)
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .failure))
        let previous = Pipeline.Status(activity: .building, lastBuild: Build(result: .failure))
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("The build is still broken.", notification?.body)
    }

    func testCreatesCompletionNotificationForOtherBuildResult() throws {
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .other))
        let previous = Pipeline.Status(activity: .building)
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("connectfour", notification?.title)
        XCTAssertEqual("The build finished with an indeterminate result.", notification?.body)
    }

    func testAddsWebUrlToUserInfoToCompletionNotification() throws {
        defaults.set(true, forKey: DefaultsKey.sendNotificationSuccessful.rawValue)
        pipeline.status = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success), webUrl: "http://localhost/connectfour")
        let previous = Pipeline.Status(activity: .building, lastBuild: Build(result: .other))
        let change = StatusChange(pipeline: pipeline, previousStatus: previous)

        let notification = factory.notificationContent(change: change)

        XCTAssertEqual("http://localhost/connectfour", notification?.userInfo["webUrl"] as? String)
    }

}
