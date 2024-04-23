/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class GitHubPipelineName: ObservableObject {
    @Published var value: String = ""

    func setDefaultName(repository: GitHubRepository, workflow: GitHubWorkflow) {
        var newName = ""
        if repository.isValid {
            newName.append(repository.name)
            if workflow.isValid {
                newName.append(String(format: " | %@", workflow.name))
            }
        }
        value = newName
    }

}

