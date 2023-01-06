/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum GithubResponseError: Error {
    case unexpectedResponseType
    case nonOkResponse(responseCode: Int)
}


class GithubFeedReader: NSObject, FeedReader, URLSessionDataDelegate, URLSessionDelegate {

    var pipeline: Pipeline
    var delegate: FeedReaderDelegate?

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    public init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    public func updatePipelineStatus() {
        let url = URL(string: pipeline.connectionDetails.feedUrl)!
        let task = session.dataTask(with: url, completionHandler: sessionCallback(data:response:error:))
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
                if let p = parser.updatePipeline(pipeline) {
                    delegate?.feedReader(self, didUpdate: p)
                }
            }
        } catch (let error) {
            pipeline.connectionError = String(describing: error) // TODO: better description
            delegate?.feedReader(self, didUpdate: pipeline)
            // TODO: on 4xx errors we should probably stop polling to avoid rate limit issues
        }
    }


}
