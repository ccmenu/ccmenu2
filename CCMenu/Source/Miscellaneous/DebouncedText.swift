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

    private var subscriptions = Set<AnyCancellable>()

    init() {
        $input
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] t in
                self?.takeText(t)
            })
            .store(in: &subscriptions)
    }

    func takeText(_ val: String? = nil) {
        let newVal = val ?? input
        if newVal != text {
            text = newVal
        }
    }
}
