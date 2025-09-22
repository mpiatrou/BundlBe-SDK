import Foundation

// MARK: - Universal Response

/// Main API response used by BundlBe.
/// Returned for both successful and error cases from `/login` and `/logout`.
public struct BundlBeResponse: Decodable {
    /// Whether paywall should be suppressed (hidden).
    public let paywallSuppress: Bool
    
    /// Optional error message returned by backend.
    public let error: String?

    enum CodingKeys: String, CodingKey {
        case paywallSuppress = "paywall_suppress"
        case error
    }
}


// MARK: - Duplicate Response

/// Response model for `/subscription-duplicate` requests.
public struct DuplicateResponse: Decodable {
    /// Indicates if duplicate notification was successful.
    public let success: Bool?
    
    /// Optional error message if request failed.
    public let error: String?
}


// MARK: - SDK Errors

/// SDK-level errors not directly returned by API.
public enum AuthError: Error {
    /// URL for request was invalid.
    case invalidURL
    /// Response was missing or could not be parsed.
    case invalidResponse
    /// Server returned a status code outside the 200–299 range.
    case serverError(status: Int, message: String?)
}

extension AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let status, let message):
            return "Status code: \(status), message: \(message ?? "Unknown error")"
        }
    }
}


// MARK: - Error Wrapper

/// Wraps BundlBe API error response with HTTP status code.
/// Used when API returns structured error JSON.
public struct ErrorResponse: Error {
    /// HTTP status code returned by backend.
    public let statusCode: Int
    /// Whether paywall should be suppressed according to response.
    public let paywallSuppress: Bool
    /// Optional error message.
    public let message: String?
}

extension ErrorResponse: LocalizedError {
    public var errorDescription: String? {
        return "Status code: \(statusCode), message: \(message ?? "Unknown error")"
    }
}
