import Foundation
import XCTest
import SharedAPI
import SharedModels
import SharedSecurity

final class FoundationContractTests: XCTestCase {
    func testHealthContractUsesOnlyDefinedPathsAndHTTPS() throws {
        XCTAssertEqual(Set(HealthEndpoint.allCases.map(\.path)), ["/health/live", "/health/ready"])

        let request = try HealthEndpoint.ready.request(baseURL: URL(string: "https://api.example.test")!)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.test/health/ready")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testHealthRequestRejectsNonHTTPSAndQueryParametersInBaseURL() {
        XCTAssertThrowsError(
            try HealthEndpoint.live.request(baseURL: URL(string: "http://api.example.test")!)
        )
        let invalidBaseURLs = ["https://api.example.test?x=1"]
        for value in invalidBaseURLs {
            XCTAssertThrowsError(
                try HealthEndpoint.live.request(baseURL: URL(string: value)!)
            )
        }
    }

    func testHealthAndErrorModelsMatchBackendContract() throws {
        XCTAssertEqual(
            try JSONDecoder().decode(HealthStatus.self, from: Data(#"{"status":"live"}"#.utf8)),
            HealthStatus(status: .live)
        )

        let envelope = try JSONDecoder().decode(
            APIErrorEnvelope.self,
            from: Data(#"{"error":{"code":"SERVICE_UNAVAILABLE","message":"Service is temporarily unavailable.","requestId":"00000000-0000-4000-8000-000000000000"}}"#.utf8)
        )
        XCTAssertEqual(envelope.error.code, .serviceUnavailable)
        XCTAssertEqual(envelope.error.requestId.uuidString.lowercased(), "00000000-0000-4000-8000-000000000000")
        XCTAssertEqual(
            Set(APIErrorCode.allCases.map(\.rawValue)),
            [
                "AUTHENTICATION_REQUIRED", "AUTHENTICATION_INVALID", "AUTHORIZATION_DENIED",
                "APP_AREA_MISMATCH", "DEVICE_IDENTITY_UNVERIFIED", "PAIRING_REQUIRED",
                "PAIRING_EXPIRED", "REPLAY_DETECTED", "VALIDATION_FAILED", "RATE_LIMITED",
                "CONFLICT", "NOT_FOUND", "SERVICE_UNAVAILABLE", "INTERNAL_ERROR"
            ]
        )
    }

    func testUnknownBackendErrorCodeFailsClosed() {
        let data = Data(#"{"error":{"code":"NEW_UNREVIEWED_CODE","message":"Unavailable","requestId":"00000000-0000-4000-8000-000000000000"}}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(APIErrorEnvelope.self, from: data))
    }

    func testSecurityChainP0RemainsBlocked() {
        XCTAssertEqual(SecurityReadiness.securityChainP0, .blocked)
    }

    #if !canImport(Security)
    func testKeychainStoreDoesNotPretendToBeAvailableOffApplePlatforms() {
        let store = KeychainSecureStore(service: "test")
        XCTAssertThrowsError(try store.read(forKey: "item")) { error in
            XCTAssertEqual(error as? SecureStoreError, .platformUnavailable)
        }
    }
    #endif
}
