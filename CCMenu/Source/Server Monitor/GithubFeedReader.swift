/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum GithubResponseError: Error {
    case unexpectedResponseType
    case nonOkResponse(responseCode: Int)
}


class GithubFeedReader: NSObject, FeedReader {

    var pipeline: Pipeline
    var delegate: FeedReaderDelegate?

    public init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    public func updatePipelineStatus() {
        // TODO: consider making page size configurable to make sure to get a completed/successful
        var request = URLRequest(url: URL(string: pipeline.feed.url + "?per_page=5")!)
        if let token = pipeline.feed.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let task = URLSession.shared.dataTask(with: request, completionHandler: sessionCallback(data:response:error:))
        task.resume()
    }

    func sessionCallback(data: Data?, response: URLResponse?, error: Error?) {
        DispatchQueue.main.async {
            self.processRequestResult(data: data, response: response, error: error)
        }
    }

    func processRequestResult(data: Data?, response: URLResponse?, error: Error?) {
        do {
            if let error = error {
                throw error
            }
            guard let response = response as? HTTPURLResponse else {
                throw GithubResponseError.unexpectedResponseType
            }

            let rll = response.allHeaderFields["x-ratelimit-limit"] as! String
            let rlu = response.allHeaderFields["x-ratelimit-used"] as! String
            debugPrint("received response from Github; rate limit \(rlu)/\(rll)")

            if !(200...299).contains(response.statusCode) {
                throw GithubResponseError.nonOkResponse(responseCode: response.statusCode)
            }

            if let receivedData = data {
                let parser = GithubResponseParser()
                try parser.parseResponse(receivedData)
                let status = parser.pipelineStatus(name: pipeline.name)
                self.updatePipeline(name: pipeline.name, newStatus: status)
            }
        } catch (let error) {
            pipeline.connectionError = String(describing: error) // TODO: better description
            delegate?.feedReader(self, didUpdate: pipeline)
            // TODO: on 4xx errors we should probably stop polling to avoid rate limit issues
        }
    }

    func updatePipeline(name: String, newStatus: Pipeline.Status?) {
        guard let newStatus = newStatus else {
            pipeline.connectionError = "The server did not provide a status for this pipeline."
            return
        }
        pipeline.connectionError = nil

//        let oldStatus = pipeline.status
        pipeline.status = newStatus

        self.delegate?.feedReader(self, didUpdate: pipeline)
    }

}
