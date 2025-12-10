/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct DynamicFeedSettings: View {
    
    @ObservedObject var sourceModel: DynamicFeedSourceModel
    @State private var showAddSheet = false
    @State private var selectedSourceId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Dynamic feeds automatically import all pipelines from a CCTray XML URL and keep them synchronized.")
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
            
            List(selection: $selectedSourceId) {
                ForEach(sourceModel.sources) { source in
                    DynamicFeedRow(source: source, sourceModel: sourceModel)
                        .tag(source.id)
                }
            }
            .listStyle(.bordered)
            .frame(minHeight: 120)
            
            HStack {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
                Button(action: removeSelectedSource) {
                    Image(systemName: "minus")
                }
                .disabled(selectedSourceId == nil)
                Spacer()
                Button("Sync Now") {
                    Task {
                        await syncAllSources()
                    }
                }
                .disabled(sourceModel.sources.isEmpty)
            }
            .padding(.top, 8)
        }
        .navigationTitle("Dynamic Feeds")
        .padding()
        .sheet(isPresented: $showAddSheet) {
            AddDynamicFeedSheet(sourceModel: sourceModel, isPresented: $showAddSheet)
        }
    }
    
    private func removeSelectedSource() {
        guard let id = selectedSourceId else { return }
        sourceModel.remove(sourceId: id)
        selectedSourceId = nil
    }
    
    @MainActor
    private func syncAllSources() async {
        // This will be called from the UI, we need access to PipelineModel
        // For now, we'll just post a notification that the ServerMonitor can observe
        NotificationCenter.default.post(name: .dynamicFeedSyncRequested, object: nil)
    }
}


struct DynamicFeedRow: View {
    let source: DynamicFeedSource
    @ObservedObject var sourceModel: DynamicFeedSourceModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(source.url.absoluteString)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 8) {
                    if let lastSync = source.lastSyncTime {
                        Text("Last sync: \(lastSync, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let error = source.lastSyncError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { source.isEnabled },
                set: { newValue in
                    var updated = source
                    updated.isEnabled = newValue
                    sourceModel.update(source: updated)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}


struct AddDynamicFeedSheet: View {
    @ObservedObject var sourceModel: DynamicFeedSourceModel
    @Binding var isPresented: Bool
    
    @State private var feedURL = ""
    @State private var removeDeletedPipelines = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Dynamic Feed")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Feed URL:")
                TextField("https://example.com/cctray.xml", text: $feedURL)
                    .textFieldStyle(.roundedBorder)
            }
            
            Toggle("Remove pipelines when deleted from feed", isOn: $removeDeletedPipelines)
            
            Text("When enabled, pipelines that are no longer present in the feed will be automatically removed. Manually added pipelines are never removed.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add") {
                    addFeed()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(feedURL.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func addFeed() {
        var urlString = feedURL
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        var source = DynamicFeedSource(url: url)
        source.removeDeletedPipelines = removeDeletedPipelines
        sourceModel.add(source: source)
        isPresented = false
    }
}


extension Notification.Name {
    static let dynamicFeedSyncRequested = Notification.Name("dynamicFeedSyncRequested")
}


struct DynamicFeedSettings_Previews: PreviewProvider {
    static var previews: some View {
        DynamicFeedSettings(sourceModel: DynamicFeedSourceModel())
    }
}

