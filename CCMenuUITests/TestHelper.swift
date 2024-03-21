/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import Hummingbird

class TestHelper {
    static func launchApp(pipelines: String = "DefaultPipelines.json", pauseMonitor: Bool = true, token: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ignoreDefaults", "true",
            "-loadPipelines", pathForResource(pipelines),
            "-pauseMonitor", String(pauseMonitor),
            "-PollInterval", "1",
            "-ShowAppIcon", "always",
            "-GitHubBaseURL", "http://localhost:8086",
        ]
        if let token {
            app.launchArguments.append(contentsOf: [ "-GitHubToken", token ])
        }
        app.launch()
        return app
    }

    @discardableResult
    static func openMenu(app: XCUIApplication) -> XCUIElementQuery {
        // If this drops you into the debugger see https://stackoverflow.com/a/64375512/409663
        let statusItem = app.menuBars.statusItems.element // TODO: workaround because line below doesn't work anymore
        // let statusItem = app.menuBars.statusItems["CCMenuMenuExtra"]
        statusItem.click()
        return statusItem.children(matching: .menu)
    }

    @discardableResult
    static func startEmbeddedServer() throws -> HBApplication {
        let webapp = HBApplication(configuration: .init(address: .hostname("localhost", port: 8086), logLevel: .info))
        // If the following fails with "operation not permitted" see: https://developer.apple.com/forums/thread/114907
        try webapp.start()
        return webapp
    }

    static func pathForResource(_ name: String) -> String {
        let myBundle = Bundle(for: TestHelper.self)
        guard let fileUrl = myBundle.url(forResource: name, withExtension:nil) else {
            fatalError("Couldn't find \(name) in UI test bundle.")
        }
        return fileUrl.path
    }

    static func contentsOfFile(_ name: String) throws -> String {
        try String(contentsOfFile: self.pathForResource(name))
    }
}
