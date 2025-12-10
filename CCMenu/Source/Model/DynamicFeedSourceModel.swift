/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine

final class DynamicFeedSourceModel: ObservableObject {
    
    static let shared: DynamicFeedSourceModel = {
        let model = DynamicFeedSourceModel()
        model.loadFromUserDefaults()
        return model
    }()
    
    @Published var sources: [DynamicFeedSource] { didSet { saveToUserDefaults() } }
    
    init() {
        sources = []
    }
    
    func add(source: DynamicFeedSource) {
        guard !sources.contains(where: { $0.id == source.id }) else { return }
        sources.append(source)
    }
    
    func remove(sourceId: String) {
        sources.removeAll { $0.id == sourceId }
    }
    
    func update(source: DynamicFeedSource) {
        guard let idx = sources.firstIndex(where: { $0.id == source.id }) else { return }
        sources[idx] = source
    }
    
    var enabledSources: [DynamicFeedSource] {
        sources.filter { $0.isEnabled }
    }
    
    func loadFromUserDefaults() {
        guard let dicts = UserDefaults.active.array(forKey: DefaultsKey.dynamicFeedSources.rawValue) as? [[String: String]] else {
            return
        }
        sources = dicts.compactMap { DynamicFeedSource(dictionary: $0) }
    }
    
    private func saveToUserDefaults() {
        let dicts = sources.map { $0.toDictionary() }
        UserDefaults.active.set(dicts, forKey: DefaultsKey.dynamicFeedSources.rawValue)
    }
    
}

