import Foundation

// MARK: - Password Reset Response Models

struct PasswordResetResponse: Codable {
    let message: String
    let expiresIn: String
}

struct ResetPasswordResponse: Codable {
    let message: String
    let user: ResetUser
    let token: String
}

struct ResetUser: Codable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
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