//
//  APIClient.swift
//
//  Simple client for POST /api/storefront, auth endpoints, and /api/estimate-price on https://bibe.stream
//

import Foundation

// MARK: - Request / Response Models

struct StorefrontItemPayload: Encodable {
    let name: String
    let price: Double
    let description: String?
    let imageUrl: String
    let tags: [String]
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case price
        case description
        case imageUrl
        case tags
        case active
    }
}

struct StorefrontCreateResponse: Decodable {
    let ok: Bool
    let id: String?
    let error: String?
}

// MARK: - Auth Models

/// Request body for POST /api/register
struct RegisterPayload: Encodable {
    let login: String
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
}

/// Response body for POST /api/register
/// Example: { "message": "Registered", "id": "..." }
struct RegisterResponse: Decodable {
    let message: String
    let id: String
}

/// Request body for POST /api/login
struct LoginPayload: Encodable {
    let loginOrEmail: String
    let password: String
}

/// Successful response body for POST /api/login
/// Example:
/// {
///   "id": "...",
///   "email": "...",
///   "username": "...",
///   "login": "...",
///   "firstName": "",
///   "lastName": "",
///   "error": ""
/// }
struct AuthUser: Decodable {
    let id: String
    let email: String
    let username: String
    let login: String
    let firstName: String
    let lastName: String
}

// MARK: - Email verification & password reset models

/// Request body for POST /api/resend-verification
struct ResendVerificationPayload: Encodable {
    let email: String
}

/// Response from /api/resend-verification
/// Example: { "ok": true } or { "ok": true, "message": "AlreadyVerified" }
struct ResendVerificationResponse: Decodable {
    let ok: Bool
    let message: String?
}

/// Request body for POST /api/forgot-password
struct ForgotPasswordPayload: Encodable {
    let email: String
}

/// Simple `{ ok: true }` style response
struct SimpleOKResponse: Decodable {
    let ok: Bool
}

/// Request body for POST /api/reset-password
struct ResetPasswordPayload: Encodable {
    let token: String
    let password: String
}

/// Request body for POST /api/verify-email-code
struct VerifyEmailCodePayload: Encodable {
    let email: String
    let code: String
}

// MARK: - Gemini Price Estimate Models

/// Optional location payload, mirrors the `location` object the server expects.
struct EstimateLocationPayload: Encodable {
    let city: String?
    let state: String?
    let country: String?
    let lat: Double?
    let lng: Double?
}

/// Optional base64 image payload, matches `imageBase64` on the server.
struct EstimateImageBase64Payload: Encodable {
    let mimeType: String?
    let data: String
}

/// Request body for POST /api/estimate-price
struct EstimatePricePayload: Encodable {
    let name: String?
    let description: String?
    let imageUrl: String?
    let imageBase64: EstimateImageBase64Payload?
    let location: EstimateLocationPayload?
}

/// Comparable listing returned from Gemini
struct PriceComparable: Decodable {
    let title: String
    let source: String
    let link: String
    let price: Double
}

/// Successful response from POST /api/estimate-price
/// Server shape: { ok: true, price, low, high, currency, confidence, explanation, comparables? }
struct EstimatePriceResponse: Decodable {
    let ok: Bool
    let price: Double
    let low: Double
    let high: Double
    let currency: String
    let confidence: Double
    let explanation: String
    let comparables: [PriceComparable]?
}

enum StorefrontAPIError: Error {
    case invalidURL
    case httpStatus(Int)
    case serverError(message: String)
    case decodingFailed
    case missingID
    case underlying(Error)
}

// MARK: - API Client

final class StorefrontAPI {

    static let shared = StorefrontAPI()

    // Base URL of your API (matches your Express app)
    private let baseURL = URL(string: "https://bibe.stream")!

    // MUST match process.env.IOS_API_KEY on the server
    // Otherwise /api/storefront will reject with 401 via requireAuthOrIos.
    private let iosAPIKey = "REPLACE_WITH_REAL_IOS_API_KEY"

    private let urlSession: URLSession

    private init(session: URLSession = .shared) {
        self.urlSession = session
    }

    // MARK: - Public API (Storefront - completion handler)

    /// Create a storefront item using completion handler style.
    func createItem(
        name: String,
        price: Double,
        description: String?,
        imageUrl: String,
        tags: [String] = [],
        active: Bool = true,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/storefront", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = StorefrontItemPayload(
            name: name,
            price: price,
            description: description,
            imageUrl: imageUrl,
            tags: tags,
            active: active
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // iOS auth path (bypasses cookie-based auth)
        request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")

        do {
            let bodyData = try JSONEncoder().encode(payload)
            request.httpBody = bodyData
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            // Network / transport error
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(StorefrontAPIError.decodingFailed))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(StorefrontCreateResponse.self, from: data)

                if decoded.ok, let id = decoded.id {
                    completion(.success(id))
                } else if let msg = decoded.error {
                    completion(.failure(StorefrontAPIError.serverError(message: msg)))
                } else {
                    completion(.failure(StorefrontAPIError.missingID))
                }
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - Public API (Storefront - async/await)

    @available(iOS 15.0, macOS 12.0, *)
    func createItem(
        name: String,
        price: Double,
        description: String?,
        imageUrl: String,
        tags: [String] = [],
        active: Bool = true
    ) async throws -> String {
        guard let url = URL(string: "/api/storefront", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = StorefrontItemPayload(
            name: name,
            price: price,
            description: description,
            imageUrl: imageUrl,
            tags: tags,
            active: active
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(StorefrontCreateResponse.self, from: data)

        if decoded.ok, let id = decoded.id {
            return id
        }

        if let msg = decoded.error {
            throw StorefrontAPIError.serverError(message: msg)
        }

        throw StorefrontAPIError.missingID
    }

    // MARK: - Public API (Auth - register, completion handler)

    /// Register a new user. On success returns the newly created user id.
    func register(
        login: String,
        email: String,
        password: String,
        firstName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/register", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = RegisterPayload(
            login: login,
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let body = try JSONEncoder().encode(payload)
            request.httpBody = body
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(StorefrontAPIError.decodingFailed))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(RegisterResponse.self, from: data)
                completion(.success(decoded.id))
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - Public API (Auth - register, async/await)

    @available(iOS 15.0, macOS 12.0, *)
    func register(
        login: String,
        email: String,
        password: String,
        firstName: String? = nil,
        lastName: String? = nil
    ) async throws -> String {
        guard let url = URL(string: "/api/register", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = RegisterPayload(
            login: login,
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(RegisterResponse.self, from: data)
        return decoded.id
    }

    // MARK: - Public API (Auth - login, completion handler)

    /// Log in with username or email. On success returns the AuthUser.
    /// Cookies set by the server (accessToken / refreshToken) are stored
    /// in the URLSession's shared cookie storage.
    func login(
        loginOrEmail: String,
        password: String,
        completion: @escaping (Result<AuthUser, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/login", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = LoginPayload(loginOrEmail: loginOrEmail, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let body = try JSONEncoder().encode(payload)
            request.httpBody = body
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(StorefrontAPIError.decodingFailed))
                return
            }

            do {
                let user = try JSONDecoder().decode(AuthUser.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - Public API (Auth - login, async/await)

    @available(iOS 15.0, macOS 12.0, *)
    func login(
        loginOrEmail: String,
        password: String
    ) async throws -> AuthUser {
        guard let url = URL(string: "/api/login", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = LoginPayload(loginOrEmail: loginOrEmail, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        let user = try JSONDecoder().decode(AuthUser.self, from: data)
        return user
    }

    // MARK: - Public API (Auth - email verification & password reset, completion handler)

    /// Resend verification email to a user.
    /// Mirrors POST /api/resend-verification
    func resendVerification(
        email: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/resend-verification", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = ResendVerificationPayload(email: email)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            // If server ever changes to 204 or empty body, treat as success.
            guard let data = data, !data.isEmpty else {
                completion(.success(()))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ResendVerificationResponse.self, from: data)
                if decoded.ok {
                    completion(.success(()))
                } else {
                    completion(.failure(
                        StorefrontAPIError.serverError(
                            message: decoded.message ?? "Verification resend failed"
                        )
                    ))
                }
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    /// Verify email using a 6-digit code instead of the link.
    /// Mirrors POST /api/verify-email-code
    func verifyEmailCode(
        email: String,
        code: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/verify-email-code", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = VerifyEmailCodePayload(email: email, code: code)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            guard let data = data, !data.isEmpty else {
                completion(.success(()))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
                if decoded.ok {
                    completion(.success(()))
                } else {
                    completion(.failure(
                        StorefrontAPIError.serverError(message: "Verify email code failed")
                    ))
                }
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    /// Start password reset flow (sends email if the account exists).
    /// Mirrors POST /api/forgot-password
    func forgotPassword(
        email: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/forgot-password", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = ForgotPasswordPayload(email: email)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            // This endpoint always returns 200 with an { ok: true } body in your server,
            // but treat empty as success too.
            guard let data = data, !data.isEmpty else {
                completion(.success(()))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
                if decoded.ok {
                    completion(.success(()))
                } else {
                    completion(.failure(
                        StorefrontAPIError.serverError(message: "Forgot password failed")
                    ))
                }
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    /// Complete password reset with a token from the email.
    /// Mirrors POST /api/reset-password
    func resetPassword(
        token: String,
        newPassword: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/reset-password", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let payload = ResetPasswordPayload(token: token, password: newPassword)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            guard let data = data, !data.isEmpty else {
                completion(.success(()))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
                if decoded.ok {
                    completion(.success(()))
                } else {
                    completion(.failure(
                        StorefrontAPIError.serverError(message: "Reset password failed")
                    ))
                }
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - Public API (Auth - email verification & password reset, async/await)

    @available(iOS 15.0, macOS 12.0, *)
    func resendVerification(email: String) async throws {
        guard let url = URL(string: "/api/resend-verification", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = ResendVerificationPayload(email: email)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        if data.isEmpty {
            return
        }

        let decoded = try JSONDecoder().decode(ResendVerificationResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(
                message: decoded.message ?? "Verification resend failed"
            )
        }
    }

    @available(iOS 15.0, macOS 12.0, *)
    func verifyEmailCode(email: String, code: String) async throws {
        guard let url = URL(string: "/api/verify-email-code", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = VerifyEmailCodePayload(email: email, code: code)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        if data.isEmpty {
            return
        }

        let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(message: "Verify email code failed")
        }
    }

    @available(iOS 15.0, macOS 12.0, *)
    func forgotPassword(email: String) async throws {
        guard let url = URL(string: "/api/forgot-password", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = ForgotPasswordPayload(email: email)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        if data.isEmpty {
            return
        }

        let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(message: "Forgot password failed")
        }
    }

    @available(iOS 15.0, macOS 12.0, *)
    func resetPassword(token: String, newPassword: String) async throws {
        guard let url = URL(string: "/api/reset-password", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let payload = ResetPasswordPayload(token: token, password: newPassword)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        if data.isEmpty {
            return
        }

        let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(message: "Reset password failed")
        }
    }

    // MARK: - Public API (Gemini price estimate - completion handler)

    /// Call the /api/estimate-price endpoint to get a cash offer + listing range.
    ///
    /// - Parameters:
    ///   - name: Optional item name.
    ///   - description: Optional item description.
    ///   - imageUrl: Optional public image URL.
    ///   - imageData: Optional raw image data; if provided it will be base64-encoded
    ///                and sent as `imageBase64.data`.
    ///   - imageMimeType: Optional MIME type for `imageData` (e.g. "image/jpeg").
    ///   - location: Optional location payload; pass `nil` to omit.
    func estimatePrice(
        name: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        imageData: Data? = nil,
        imageMimeType: String? = nil,
        location: EstimateLocationPayload? = nil,
        completion: @escaping (Result<EstimatePriceResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "/api/estimate-price", relativeTo: baseURL) else {
            completion(.failure(StorefrontAPIError.invalidURL))
            return
        }

        let imageBase64: EstimateImageBase64Payload?
        if let data = imageData {
            imageBase64 = EstimateImageBase64Payload(
                mimeType: imageMimeType,
                data: data.base64EncodedString()
            )
        } else {
            imageBase64 = nil
        }

        let payload = EstimatePricePayload(
            name: name,
            description: description,
            imageUrl: imageUrl,
            imageBase64: imageBase64,
            location: location
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // If you lock this endpoint down with requireAuthOrIos later,
        // this header will already be in place.
        request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")

        do {
            let body = try JSONEncoder().encode(payload)
            request.httpBody = body
        } catch {
            completion(.failure(StorefrontAPIError.underlying(error)))
            return
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(StorefrontAPIError.underlying(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(StorefrontAPIError.httpStatus(-1)))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(StorefrontAPIError.httpStatus(http.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(StorefrontAPIError.decodingFailed))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(EstimatePriceResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(StorefrontAPIError.decodingFailed))
            }
        }.resume()
    }

    // MARK: - Public API (Gemini price estimate - async/await)

    @available(iOS 15.0, macOS 12.0, *)
    func estimatePrice(
        name: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        imageData: Data? = nil,
        imageMimeType: String? = nil,
        location: EstimateLocationPayload? = nil
    ) async throws -> EstimatePriceResponse {
        guard let url = URL(string: "/api/estimate-price", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        let imageBase64: EstimateImageBase64Payload?
        if let data = imageData {
            imageBase64 = EstimateImageBase64Payload(
                mimeType: imageMimeType,
                data: data.base64EncodedString()
            )
        } else {
            imageBase64 = nil
        }

        let payload = EstimatePricePayload(
            name: name,
            description: description,
            imageUrl: imageUrl,
            imageBase64: imageBase64,
            location: location
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(EstimatePriceResponse.self, from: data)
        return decoded
    }
}

// MARK: - Example usage (you can delete this in production)

// Completion-based storefront create
func exampleCreateWithCompletion() {
    StorefrontAPI.shared.createItem(
        name: "Test Item",
        price: 19.99,
        description: "A nice test item",
        imageUrl: "https://example.com/image.jpg",
        tags: ["test", "pawn"],
        active: true
    ) { result in
        switch result {
        case .success(let id):
            print("Created storefront item with id:", id)
        case .failure(let error):
            print("Storefront create failed:", error)
        }
    }
}

// Completion-based register
func exampleRegisterWithCompletion() {
    StorefrontAPI.shared.register(
        login: "testuser",
        email: "test@example.com",
        password: "s3cret!",
        firstName: "Test",
        lastName: "User"
    ) { result in
        switch result {
        case .success(let id):
            print("Registered user with id:", id)
        case .failure(let error):
            print("Register failed:", error)
        }
    }
}

// Completion-based login
func exampleLoginWithCompletion() {
    StorefrontAPI.shared.login(
        loginOrEmail: "testuser",
        password: "s3cret!"
    ) { result in
        switch result {
        case .success(let user):
            print("Logged in as:", user.username)
        case .failure(let error):
            print("Login failed:", error)
        }
    }
}

// Completion-based price estimate
func exampleEstimatePriceWithCompletion() {
    StorefrontAPI.shared.estimatePrice(
        name: "MacBook Pro 14\" 2023",
        description: "M2 Pro, 16GB RAM, 512GB SSD, good condition",
        imageUrl: "https://example.com/macbook.jpg"
    ) { result in
        switch result {
        case .success(let response):
            print("Cash offer:", response.price,
                  "range:", response.low, "-", response.high,
                  "confidence:", response.confidence)
        case .failure(let error):
            print("Estimate failed:", error)
        }
    }
}

// Completion-based forgot password
func exampleForgotPasswordWithCompletion() {
    StorefrontAPI.shared.forgotPassword(email: "test@example.com") { result in
        switch result {
        case .success:
            print("Forgot password email sent (if account exists).")
        case .failure(let error):
            print("Forgot password failed:", error)
        }
    }
}

// Completion-based resend verification
func exampleResendVerificationWithCompletion() {
    StorefrontAPI.shared.resendVerification(email: "test@example.com") { result in
        switch result {
        case .success:
            print("Verification email re-sent.")
        case .failure(let error):
            print("Resend verification failed:", error)
        }
    }
}

// Completion-based verify email code
func exampleVerifyEmailCodeWithCompletion() {
    StorefrontAPI.shared.verifyEmailCode(
        email: "test@example.com",
        code: "123456"
    ) { result in
        switch result {
        case .success:
            print("Email verified via code.")
        case .failure(let error):
            print("Verify email code failed:", error)
        }
    }
}

// Completion-based reset password
func exampleResetPasswordWithCompletion(token: String, newPassword: String) {
    StorefrontAPI.shared.resetPassword(token: token, newPassword: newPassword) { result in
        switch result {
        case .success:
            print("Password reset OK")
        case .failure(let error):
            print("Reset password failed:", error)
        }
    }
}

// Async/await (in an async context)
/*
@available(iOS 15.0, *)
func exampleCreateAsync() async {
    do {
        let id = try await StorefrontAPI.shared.createItem(
            name: "Async Item",
            price: 29.99,
            description: "Created with async/await",
            imageUrl: "https://example.com/async-image.jpg",
            tags: ["async", "pawn"],
            active: true
        )
        print("Created storefront item with id:", id)
    } catch {
        print("Storefront create failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleRegisterAsync() async {
    do {
        let id = try await StorefrontAPI.shared.register(
            login: "asyncuser",
            email: "async@example.com",
            password: "s3cret!"
        )
        print("Registered user with id:", id)
    } catch {
        print("Register failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleLoginAsync() async {
    do {
        let user = try await StorefrontAPI.shared.login(
            loginOrEmail: "asyncuser",
            password: "s3cret!"
        )
        print("Logged in as:", user.username)
    } catch {
        print("Login failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleEstimatePriceAsync() async {
    do {
        let estimate = try await StorefrontAPI.shared.estimatePrice(
            name: "PlayStation 5",
            description: "Disc edition, 2 controllers, great condition",
            imageUrl: "https://example.com/ps5.jpg"
        )
        print("Cash offer:", estimate.price,
              "range:", estimate.low, "-", estimate.high,
              "confidence:", estimate.confidence)
    } catch {
        print("Estimate failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleForgotPasswordAsync() async {
    do {
        try await StorefrontAPI.shared.forgotPassword(email: "async@example.com")
        print("Forgot password email sent (if account exists).")
    } catch {
        print("Forgot password failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleResendVerificationAsync() async {
    do {
        try await StorefrontAPI.shared.resendVerification(email: "async@example.com")
        print("Verification email re-sent.")
    } catch {
        print("Resend verification failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleVerifyEmailCodeAsync() async {
    do {
        try await StorefrontAPI.shared.verifyEmailCode(
            email: "async@example.com",
            code: "123456"
        )
        print("Email verified via code.")
    } catch {
        print("Verify email code failed:", error)
    }
}

@available(iOS 15.0, *)
func exampleResetPasswordAsync(token: String, newPassword: String) async {
    do {
        try await StorefrontAPI.shared.resetPassword(token: token, newPassword: newPassword)
        print("Password reset OK")
    } catch {
        print("Reset password failed:", error)
    }
}
*/
