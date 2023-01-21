/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


class WorkspaceController {

    func openPipeline(_ pipeline: Pipeline) {
        if let urlString = pipeline.webUrl, let url = URL(string: urlString), url.host != nil {
            NSWorkspace.shared.open(url)
        } else if (pipeline.webUrl ?? "").isEmpty {
            alertCannotOpenPipeline("The continuous integration server did not provide a link for this pipeline.")
        } else {
            alertCannotOpenPipeline("The continuous integration server provided a malformed link for this pipeline:\n\(pipeline.webUrl ?? "")")
        }
    }

    private func alertCannotOpenPipeline(_ informativeText: String) {
        let alert = NSAlert()
        alert.messageText = "Cannot open pipeline"
        alert.informativeText = informativeText + "\n\nPlease contact the server administrator."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }

}
