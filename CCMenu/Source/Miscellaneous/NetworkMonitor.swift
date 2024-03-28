/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Network

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private(set) var isConnected = false
    private(set) var isLowDataConnection = false
    private(set) var isExpensiveConnection = false

    func start() {
        monitor.pathUpdateHandler = pathChanged(path:)
        monitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    deinit {
        monitor.cancel()
    }

    private func pathChanged(path: NWPath) {
        isConnected = (path.status == .satisfied)
        isLowDataConnection = path.isConstrained
        isExpensiveConnection = path.isExpensive
        debugPrint(Date(), "network path", path.debugDescription)
    }

}
