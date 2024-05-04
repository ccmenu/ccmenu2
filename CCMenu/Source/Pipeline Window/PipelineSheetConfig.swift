/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineSheetConfig {
    @AppStorage(.showAppIcon) var showAppIcon: AppIconVisibility = .sometimes
    var isPresented: Bool = false { didSet { setAppIconVisibility() } }
    var pipelines: [Pipeline] = []


    var pipeline: Pipeline? {
        return (pipelines.count == 1) ? pipelines[0] : nil
    }

    mutating func setPipeline(_ pipeline: Pipeline?) {
        self.pipelines.removeAll()
        if let pipeline {
            self.pipelines.append(pipeline)
        }
    }

    func setAppIconVisibility() {
        guard showAppIcon == .sometimes else { return }
        NSApp.hideApplicationIcon(!isPresented)
        NSApp.activateThisApp()
    }
}
