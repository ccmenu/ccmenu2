/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import UniformTypeIdentifiers

struct PipelineDocument: FileDocument {
    static var readableContentTypes: [UTType] = [ .json ]
    
    private(set) var pipelines: [Pipeline] = []
    
    init(pipelines: [Pipeline]) {
        self.pipelines = pipelines
    }
    
    init(url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else { throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError) }
        defer { url.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let references = try decoder.decode([[String : String]].self, from: data)
        pipelines = references.compactMap({ Pipeline(reference: $0) })
    }
    
    init(configuration: ReadConfiguration) throws {
        // can't use this because it seems impossible to create a ReadConfiguration
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let references = pipelines.map({ $0.reference() })
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(references)
        let wrapper = FileWrapper(regularFileWithContents: data)
        return wrapper
    }
    
}
