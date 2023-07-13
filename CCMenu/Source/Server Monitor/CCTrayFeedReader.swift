/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class CCTrayFeedReader: NSObject, FeedReader, URLSessionDataDelegate, URLSessionDelegate {
    
    var pipelines: [Pipeline]
    var delegate: FeedReaderDelegate?
    var receivedData: Data?

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration,
                          delegate: self, delegateQueue: nil)
    }()
    
    public init(for pipeline: Pipeline) {
        self.pipelines = [pipeline]
    }
    
    public func updatePipelineStatus() {
        let url = URL(string: pipelines[0].feed.url)! // All pipelines have the same URL.
        receivedData = Data()
        let task = session.dataTask(with: url)
        task.resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode)
        else {
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }


    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData?.append(data)
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.handleClientError(error)
            } else if let receivedData = self.receivedData {
                let parser = CCTrayResponseParser()
                do {
                    try parser.parseResponse(receivedData)
                    for p in self.pipelines {
                        let status = parser.pipelineStatus(name: p.feed.name ?? "") // TODO: report an error? here?
                        self.updatePipeline(name: p.name, newStatus: status)
                    }
                } catch let error {
                    self.handleParserError(error)
                }
            }
        }
    }

    func handleClientError(_ error: Error) {
        print("client error \(error.localizedDescription)")
    }

    func handleParserError(_ error: Error) {
        print("parser error \(error.localizedDescription)")
    }

    func updatePipeline(name: String, newStatus: Pipeline.Status?) {
        guard let idx = pipelines.firstIndex(where: { p in p.name == name }) else {
            debugPrint("Attempt to update pipeline '\(name)', which reader for '\(pipelines[0].feed.url)' does not monitor.")
            return
        }
        guard let newStatus = newStatus else {
            pipelines[idx].connectionError = "The server did not provide a status for this pipeline."
            return
        }
        pipelines[idx].connectionError = nil

        let oldStatus = pipelines[idx].status
        pipelines[idx].status = newStatus
        pipelines[idx].status.currentBuild?.timestamp = oldStatus.currentBuild?.timestamp
        pipelines[idx].status.lastBuild?.duration = oldStatus.lastBuild?.duration

        if oldStatus.activity != .building && newStatus.activity == .building {
            pipelines[idx].status.currentBuild?.timestamp = Date.now
        }
        if oldStatus.activity == .building && newStatus.activity != .building {
            if let timestamp = oldStatus.currentBuild?.timestamp {
                pipelines[idx].status.lastBuild?.duration = DateInterval(start: timestamp, end: Date.now).duration
            }
        }

        self.delegate?.feedReader(self, didUpdate: pipelines[idx])
    }

}
