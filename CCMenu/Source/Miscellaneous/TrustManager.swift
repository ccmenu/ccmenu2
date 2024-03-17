/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import SecurityInterface

public class TrustManager {

    public static func shouldContinueWithServerTrust(_ trust: SecTrust, forURL url: URL) -> Bool {
        if SecTrustEvaluateWithError(trust, nil) {
            return true
        }
        var result: SecTrustResultType = .invalid
        SecTrustGetTrustResult(trust, &result)
        switch result {
        case .proceed:
            return true
        case .recoverableTrustFailure:
            let certHandling: CertHandling = UserDefaults.active.stringRepresentable(forKey: DefaultsKey.acceptInvalidCerts.rawValue) ?? .never
            return (certHandling == .localhost) && (url.host(percentEncoded: false) == "localhost")
        default:
            return false
        }
    }

    public static func includedSSLPeerTrust(forError error: Error) -> SecTrust? {
        let error = error as NSError
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorServerCertificateUntrusted {
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                if let trust = underlyingError.userInfo[kCFStreamPropertySSLPeerTrust as String] as? AnyObject {
                    return (trust as! SecTrust)
                }
            }
        }
        return nil
    }

    public static func showCertificateTrustPanel(forTrust trust: SecTrust) -> Bool {
        let panel: SFCertificateTrustPanel = SFCertificateTrustPanel.shared()
        panel.setInformativeText("The certificate used by the server is not trusted. You can inspect it below.\n\nIf you want to connect anyway, click the \"Show Certificate\" button and then tick the \"Always trust\" checkbox before continuing.")
        panel.setAlternateButtonTitle("Cancel")
        // Running the panel will result in a "purple" warning, but that's not avoidable at the moment
        // https://developer.apple.com/forums/thread/714467?answerId=734799022#734799022
        let result = panel.runModal(for: trust, message: "Error while establishing HTTPS connection")
        return result == NSApplication.ModalResponse.OK.rawValue
    }

}
