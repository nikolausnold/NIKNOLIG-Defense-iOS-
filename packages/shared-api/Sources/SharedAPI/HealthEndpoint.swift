import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import SharedModels

public enum HealthEndpoint: String, CaseIterable, Sendable {
    case live = "/health/live"
    case ready = "/health/ready"

    public var path: String { rawValue }

    public func request(baseURL: URL) throws -> URLRequest {
        guard
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
            components.scheme?.lowercased() == "https",
            let host = components.host,
            !host.isEmpty,
            components.user == nil,
            components.password == nil,
            components.query == nil,
            components.fragment == nil
        else {
            throw HealthRequestError.invalidBaseURL
        }

        components.path = path
        guard let url = components.url else {
            throw HealthRequestError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

public enum HealthRequestError: Error, Equatable, Sendable {
    case invalidBaseURL
}

public typealias HealthResponse = HealthStatus
