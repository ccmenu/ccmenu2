/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

extension NSWorkspace {

    func activateThisApp() {
        // TODO: There must be a better way...
        if #available(macOS 14.0, *) {
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func openWebPage(pipeline: Pipeline) {
        if let error = pipeline.connectionError {
            // TODO: Consider adding a UI test for this case
            alertPipelineFeedError(error)
        } else {
            openPipelineWebPage(pipeline.status.webUrl)
        }
    }

    func openPipelineWebPage(_ urlStringOption: String?) {
        if let urlString = urlStringOption, let url = URL(string: urlString), url.host != nil {
            self.open(url)
        } else if (urlStringOption ?? "").isEmpty {
            alertPipelineLinkProblem("The continuous integration server did not provide a link for this pipeline.")
        } else {
            alertPipelineLinkProblem("The continuous integration server provided a malformed link for this pipeline:\n\(urlStringOption ?? "")")
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
        alert.messageText = "Can't open web page"
        alert.informativeText = informativeText + "\n\nPlease contact the server administrator."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }
    
}
