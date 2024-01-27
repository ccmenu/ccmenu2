/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

extension NSColor
{
    static let statusGreen  = NSColor(webcolor: "#56932E")
    static let statusOrange = NSColor(webcolor: "#FF9900")
    static let statusRed    = NSColor(webcolor: "#DB2A2A")
    static let statusText   = NSColor(webcolor: "#F0F0F0")

    convenience init(webcolor: NSString)
    {
        var red:   Double = 0; Scanner(string: "0x"+webcolor.substring(with: NSMakeRange(1, 2))).scanHexDouble(&red)
        var green: Double = 0; Scanner(string: "0x"+webcolor.substring(with: NSMakeRange(3, 2))).scanHexDouble(&green)
        var blue:  Double = 0; Scanner(string: "0x"+webcolor.substring(with: NSMakeRange(5, 2))).scanHexDouble(&blue)
        self.init(red: CGFloat(red/256), green: CGFloat(green/256), blue: CGFloat(blue/256), alpha: 1)
    }

}
