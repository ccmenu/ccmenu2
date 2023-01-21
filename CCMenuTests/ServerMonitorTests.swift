/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ServerMonitorTests: XCTestCase {
    
    func testCreatesConnectionForPipeline() throws {
        let model = ViewModel()
        let p0 = Pipeline(name: "connectfour", feedUrl: "http://test/cctray.xml")
        model.pipelines.append(p0)

        let monitor = ServerMonitor(model: model)
        monitor.createReaders()
       
        XCTAssertEqual(1, monitor.readerList.count)
    }
}

