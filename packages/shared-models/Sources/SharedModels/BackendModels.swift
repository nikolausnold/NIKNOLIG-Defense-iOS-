import Foundation

public enum HealthState: String, Codable, CaseIterable, Sendable {
    case live
    case ready
}

public struct HealthStatus: Codable, Equatable, Sendable {
    public let status: HealthState

    public init(status: HealthState) {
        self.status = status
    }
}

public enum APIErrorCode: String, Codable, CaseIterable, Sendable {
    case authenticationRequired = "AUTHENTICATION_REQUIRED"
    case authenticationInvalid = "AUTHENTICATION_INVALID"
    case authorizationDenied = "AUTHORIZATION_DENIED"
    case appAreaMismatch = "APP_AREA_MISMATCH"
    case deviceIdentityUnverified = "DEVICE_IDENTITY_UNVERIFIED"
    case pairingRequired = "PAIRING_REQUIRED"
    case pairingExpired = "PAIRING_EXPIRED"
    case replayDetected = "REPLAY_DETECTED"
    case validationFailed = "VALIDATION_FAILED"
    case rateLimited = "RATE_LIMITED"
    case conflict = "CONFLICT"
    case notFound = "NOT_FOUND"
    case serviceUnavailable = "SERVICE_UNAVAILABLE"
    case internalError = "INTERNAL_ERROR"
}

public struct APIError: Codable, Equatable, Sendable {
    public let code: APIErrorCode
    public let message: String
    public let requestId: UUID

    public init(code: APIErrorCode, message: String, requestId: UUID) {
        self.code = code
        self.message = message
        self.requestId = requestId
    }
}

public struct APIErrorEnvelope: Codable, Equatable, Sendable {
    public let error: APIError

    public init(error: APIError) {
        self.error = error
    }
}
