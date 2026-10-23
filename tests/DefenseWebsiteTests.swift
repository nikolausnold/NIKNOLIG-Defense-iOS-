import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import SharedAPI

final class DefenseWebsiteTests: XCTestCase {
    func testCanonicalURLAndRedirectTrust() {
        XCTAssertEqual(DefenseWebsite.url.absoluteString, "https://defense.niknolig.com/")
        XCTAssertTrue(DefenseWebsite.isTrusted(URL(string: "https://defense.niknolig.com/about")!))
        for value in [
            "http://defense.niknolig.com/", "https://defense.niknolig.com.evil.test/",
            "https://niknolig.com/", "https://user@defense.niknolig.com/",
            "https://defense.niknolig.com:8443/", "file:///tmp/website",
            "javascript:alert(1)"
        ] {
            XCTAssertFalse(DefenseWebsite.isTrusted(URL(string: value)!), value)
        }
    }

    func testHTTPSRequestIsNotSatisfiedByConfigurationAlone() async throws {
        try await DefenseWebsite.check(configuration: configuration(WebsiteStubProtocol.self))
        let failures: [(URLProtocol.Type, Int)] = [
            (RedirectProtocol.self, 301), (ForbiddenProtocol.self, 403),
            (NotFoundProtocol.self, 404), (ServerErrorProtocol.self, 500),
            (UnavailableProtocol.self, 503)
        ]
        for (protocolClass, status) in failures {
            do {
                try await DefenseWebsite.check(configuration: configuration(protocolClass))
                XCTFail("HTTP \(status) must fail")
            } catch {
                XCTAssertEqual(error as? WebsiteError, .http(status))
            }
        }
    }

    func testTransportFailures() async {
        let failures: [(URLError.Code, WebsiteError)] = [
            (.notConnectedToInternet, .offline), (.networkConnectionLost, .offline),
            (.cannotFindHost, .dns), (.dnsLookupFailed, .dns),
            (.secureConnectionFailed, .tls), (.serverCertificateUntrusted, .tls),
            (.serverCertificateHasBadDate, .tls),
            (.appTransportSecurityRequiresSecureConnection, .tls),
            (.timedOut, .timeout), (.cannotConnectToHost, .network)
        ]
        for (code, expected) in failures {
            XCTAssertEqual(WebsiteError(URLError(code)), expected)
            XCTAssertFalse(expected.message.isEmpty)
        }
        do {
            try await DefenseWebsite.check(configuration: configuration(OfflineProtocol.self))
            XCTFail("Transport failure must not report success")
        } catch {
            XCTAssertEqual(WebsiteError(error), .offline)
        }
    }

    @MainActor
    func testErrorRetryAndBrowserRejection() async {
        let attempts = WebsiteAttempts()
        let connection = WebsiteConnection { try await attempts.check() }
        XCTAssertEqual(connection.state, .idle)
        let first = await connection.prepareToOpen()
        XCTAssertFalse(first)
        XCTAssertEqual(connection.state, .failed(.offline))
        let retry = await connection.prepareToOpen()
        XCTAssertTrue(retry)
        XCTAssertEqual(connection.state, .opening)
        let duplicate = await connection.prepareToOpen()
        XCTAssertFalse(duplicate)
        connection.finishedOpening(accepted: false)
        XCTAssertEqual(connection.state, .failed(.openFailed))
        let browserRetry = await connection.prepareToOpen()
        XCTAssertTrue(browserRetry)
        connection.finishedOpening(accepted: true)
        XCTAssertEqual(connection.state, .idle)
    }

    @MainActor
    func testLoadingAndCancellationNeverOpenBrowser() async {
        let connection = WebsiteConnection {
            try await Task.sleep(for: .seconds(60))
        }
        let task = Task { await connection.prepareToOpen() }
        while connection.state == .idle { await Task.yield() }
        XCTAssertEqual(connection.state, .checking)
        let duplicate = await connection.prepareToOpen()
        XCTAssertFalse(duplicate)
        task.cancel()
        let opened = await task.value
        XCTAssertFalse(opened)
        XCTAssertEqual(connection.state, .idle)
    }

    private func configuration(_ protocolClass: URLProtocol.Type) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        return configuration
    }
}

private actor WebsiteAttempts {
    private var count = 0

    func check() throws {
        count += 1
        if count == 1 { throw URLError(.notConnectedToInternet) }
    }
}

private class WebsiteStubProtocol: URLProtocol {
    class var scenario: Int { 200 }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard request.url == DefenseWebsite.url, request.httpMethod == "GET",
              request.value(forHTTPHeaderField: "Accept") == "text/html" else {
            client?.urlProtocol(self, didFailWithError: WebsiteError.invalidResponse)
            return
        }
        let value = Self.scenario
        if value < 0 {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        } else {
            let response = HTTPURLResponse(
                url: DefenseWebsite.url, statusCode: value,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("<html>Defense</html>".utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

private final class RedirectProtocol: WebsiteStubProtocol {
    override class var scenario: Int { 301 }
}

private final class ForbiddenProtocol: WebsiteStubProtocol {
    override class var scenario: Int { 403 }
}

private final class NotFoundProtocol: WebsiteStubProtocol {
    override class var scenario: Int { 404 }
}

private final class ServerErrorProtocol: WebsiteStubProtocol {
    override class var scenario: Int { 500 }
}

private final class UnavailableProtocol: WebsiteStubProtocol {
    override class var scenario: Int { 503 }
}

private final class OfflineProtocol: WebsiteStubProtocol {
    override class var scenario: Int { URLError.notConnectedToInternet.rawValue }
}
