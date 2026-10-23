import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Observation

public enum DefenseWebsite {
    public static let url = URL(string: "https://defense.niknolig.com/")!

    public static func isTrusted(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        return components.scheme?.lowercased() == "https"
            && components.host?.lowercased() == "defense.niknolig.com"
            && (components.port == nil || components.port == 443)
            && components.user == nil && components.password == nil
    }

    public static func check(
        configuration: URLSessionConfiguration = .ephemeral
    ) async throws {
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        let session = URLSession(
            configuration: configuration,
            delegate: WebsiteRedirectPolicy(),
            delegateQueue: nil
        )
        defer { session.invalidateAndCancel() }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        let (_, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              let finalURL = response.url, isTrusted(finalURL) else {
            throw WebsiteError.invalidResponse
        }
        guard (200...299).contains(response.statusCode) else {
            throw WebsiteError.http(response.statusCode)
        }
    }
}

private final class WebsiteRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(request.url.map(DefenseWebsite.isTrusted) == true ? request : nil)
    }
}

public enum WebsiteError: Error, Equatable, Sendable {
    case offline, dns, tls, timeout, invalidResponse, openFailed, network
    case http(Int)

    public init(_ error: Error) {
        if let error = error as? WebsiteError {
            self = error
            return
        }
        switch (error as? URLError)?.code {
        case .notConnectedToInternet, .networkConnectionLost: self = .offline
        case .cannotFindHost, .dnsLookupFailed: self = .dns
        case .secureConnectionFailed, .serverCertificateHasBadDate,
             .serverCertificateUntrusted, .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid, .clientCertificateRejected,
             .clientCertificateRequired, .appTransportSecurityRequiresSecureConnection:
            self = .tls
        case .timedOut: self = .timeout
        default: self = .network
        }
    }

    public var message: String {
        switch self {
        case .offline: "You appear to be offline. Check your internet connection and retry."
        case .dns: "The Defense website address could not be resolved. Please retry later."
        case .tls: "A secure connection could not be established. Please retry later."
        case .timeout: "The Defense website took too long to respond. Please retry."
        case .http(let status): "The Defense website returned HTTP \(status). Please retry later."
        case .invalidResponse: "The Defense website returned an unexpected response. Please retry later."
        case .openFailed: "iOS could not open the website in your browser. Please retry."
        case .network: "The Defense website could not be reached. Please retry."
        }
    }
}

@MainActor
@Observable
public final class WebsiteConnection {
    public enum State: Equatable {
        case idle, checking, opening
        case failed(WebsiteError)
    }

    public private(set) var state: State = .idle
    private let check: @Sendable () async throws -> Void

    public init(check: @escaping @Sendable () async throws -> Void = {
        try await DefenseWebsite.check()
    }) {
        self.check = check
    }

    public func prepareToOpen() async -> Bool {
        guard state != .checking && state != .opening else { return false }
        state = .checking
        do {
            try await check()
            try Task.checkCancellation()
            state = .opening
            return true
        } catch {
            if Task.isCancelled || error is CancellationError {
                state = .idle
            } else {
                state = .failed(WebsiteError(error))
            }
            return false
        }
    }

    public func finishedOpening(accepted: Bool) {
        state = accepted ? .idle : .failed(.openFailed)
    }
}
