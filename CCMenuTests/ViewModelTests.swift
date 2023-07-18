/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ViewModelTests: XCTestCase {

    private func makeModel() -> PipelineModel {
        let m = PipelineModel(settings: UserSettings())
        return m
    }


}

