import Foundation

// MARK: - Password Reset Response Models

struct PasswordResetResponse: Codable {
    let message: String
    let expiresIn: String
}

struct ResetPasswordResponse: Codable {
    let message: String
    let success: Bool
}

struct VerifyTokenResponse: Codable {
    let message: String
    let valid: Bool
    let email: String
}

// MARK: - Error Response
struct PasswordResetErrorResponse: Codable {
    let error: String
    let errors: [ValidationError]?
}

struct ValidationError: Codable {
    let msg: String
    let param: String?
    let location: String?
}