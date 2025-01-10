/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */


import SwiftUI

struct ComboBox: NSViewRepresentable {
    var items: [String]
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeNSView(context: Context) -> NSComboBox {
        let wrappedView = NSComboBox()
        wrappedView.usesDataSource = true
        wrappedView.completes = true
        wrappedView.hasVerticalScroller = true
        wrappedView.numberOfVisibleItems = 10
        wrappedView.intercellSpacing = NSSize(width: 0.0, height: 10.0)
        wrappedView.dataSource = context.coordinator
        wrappedView.delegate = context.coordinator
        return wrappedView
    }

    func updateNSView(_ wrappedView: NSComboBox, context: Context) {
        if items == context.coordinator.items {
            return
        }
        context.coordinator.items = items
        wrappedView.reloadData()
        if items.count > 0 {
            wrappedView.selectItem(at: 0)
        }
    }
}


extension ComboBox {

    class Coordinator: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
        var items: [String]
        var swiftView: ComboBox

        init(_ comboBox: ComboBox) {
            self.items = []
            self.swiftView = comboBox
        }

        func numberOfItems(in _: NSComboBox) -> Int {
            return items.count
        }

        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
            return items[index]
        }

        func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
            return items.firstIndex(where: { $0 == string }) ?? NSNotFound
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let wrappedBox = notification.object as? NSComboBox else {
                return
            }
            let index = wrappedBox.indexOfSelectedItem
            Task {
                swiftView.text = (index != -1) ? items[index] : ""
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else {
                return
            }
            swiftView.text = textField.stringValue
        }

    }
}
