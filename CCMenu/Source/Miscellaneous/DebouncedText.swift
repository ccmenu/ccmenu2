/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Combine
import SwiftUI

class DebouncedText : ObservableObject {
    @Published var input = ""
    @Published var text = ""

    private var subscriber = Set<AnyCancellable>()

    init() {
        $input
            .debounce(for: .milliseconds(750), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] val in
                self?.takeInput(val)
            })
            .store(in: &subscriber)
    }

    func takeInput(_ val: String? = nil) {
        let val = val ?? input
        if val != text {
            text = val
        }
    }
}
