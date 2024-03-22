/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct CompactRelativeFormatStyle : FormatStyle, Sendable {

    typealias FormatInput = Date
    typealias FormatOutput = String

    private var reference: Date

    init(reference: Date) {
        self.reference = reference
    }

    func format(_ value: Date) -> String {
        let interval = value.timeIntervalSince(reference)
        let sign = (interval < 0) ? "-" : "+"
        let seconds = Int(abs(interval))

        if abs(interval) >= 3600 {
            return String(format:"%@%d:%02d:%02d", sign, seconds / 3600, (seconds / 60) % 60, seconds % 60)
        }
        if abs(interval) >= 60 {
            return String(format:"%@%02d:%02d", sign, seconds / 60, seconds % 60)
        }
        if abs(interval) > 0 {
            return String(format:"%@%02ds", sign, seconds)
        }
        return ""
    }

}

extension FormatStyle where Self == CompactRelativeFormatStyle {

    static func compactRelative(reference: Date = Date.now) -> Self {
        return CompactRelativeFormatStyle(reference: reference)
    }

}
