/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

extension NSWorkspace {

    func activateThisApp() {
        // TODO: There must be a better way...
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openUrl(url: URL) {
        self.open(url)
    }
    
    func openWebPage(pipeline: Pipeline) {
        if let error = pipeline.connectionError {
            // TODO: Consider adding a UI test for this case
           alertPipelineFeedError(error)
        } else {
            if let urlString = pipeline.status.webUrl, let url = URL(string: urlString), url.host != nil {
                self.open(url)
            } else if (pipeline.status.webUrl ?? "").isEmpty {
                alertPipelineLinkProblem("The continuous integration server did not provide a link for this pipeline.")
            } else {
                alertPipelineLinkProblem("The continuous integration server provided a malformed link for this pipeline:\n\(pipeline.status.webUrl ?? "")")
            }
        }
    }

    private func alertPipelineFeedError(_ errorString: String) {
        let alert = NSAlert()
        alert.messageText = "No pipeline status"
        alert.informativeText = errorString + "\n\nPlease check the URL, make sure you're logged in if neccessary. Otherwise contact the server administrator."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }

    private func alertPipelineLinkProblem(_ informativeText: String) {
        let alert = NSAlert()
        alert.messageText = "Cannot open pipeline"
        alert.informativeText = informativeText + "\n\nPlease contact the server administrator."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }
    
}
