//
//  APIClient.swift
//  BigProjectUIApp
//
//  Networking client for auth, storefront, and price estimate APIs.
//

import Foundation

// MARK: - Storefront create models

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

// MARK: - Storefront listing models

/// Single item used by the Browse screen.
struct StorefrontListItem: Identifiable, Decodable {
    let id: String
    let name: String
    let price: Double
    let description: String?
    let imageUrl: String?
    let tags: [String]
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case name
        case price
        case description
        case imageUrl
        case tags
        case active
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Server returns `_id` from Mongo; support either `id` or `_id`
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: ._id)

        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.active = try container.decodeIfPresent(Bool.self, forKey: .active) ?? true
    }
}

/// Exact shape of GET /api/storefront
struct StorefrontListResponse: Decodable {
    let ok: Bool
    let items: [StorefrontListItem]
    let nextCursor: String?
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
struct AuthUser: Decodable {
    let id: String
    let email: String
    let username: String
    let login: String
    let firstName: String
    let lastName: String
}

// MARK: - Email verification & password reset models

struct ResendVerificationPayload: Encodable {
    let email: String
}

struct ResendVerificationResponse: Decodable {
    let ok: Bool
    let message: String?
}

struct ForgotPasswordPayload: Encodable {
    let email: String
}

struct SimpleOKResponse: Decodable {
    let ok: Bool
}

struct ResetPasswordPayload: Encodable {
    let token: String
    let password: String
}

struct VerifyEmailCodePayload: Encodable {
    let email: String
    let code: String
}

// MARK: - Gemini Price Estimate Models

struct EstimateLocationPayload: Encodable {
    let city: String?
    let state: String?
    let country: String?
    let lat: Double?
    let lng: Double?
}

struct EstimateImageBase64Payload: Encodable {
    let mimeType: String?
    let data: String
}

struct EstimatePricePayload: Encodable {
    let name: String?
    let description: String?
    let imageUrl: String?
    let imageBase64: EstimateImageBase64Payload?
    let location: EstimateLocationPayload?
}

struct PriceComparable: Decodable {
    let title: String
    let source: String
    let link: String
    let price: Double
}

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

// MARK: - Errors

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
    // for /api/storefront POST and other iOS-protected endpoints.
    private let iosAPIKey = "REPLACE_WITH_REAL_IOS_API_KEY"

    private let urlSession: URLSession

    private init(session: URLSession = .shared) {
        self.urlSession = session
    }

    // MARK: - Storefront create (completion)

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
        request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")

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

    // MARK: - Storefront create (async)

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
        } else if let msg = decoded.error {
            throw StorefrontAPIError.serverError(message: msg)
        } else {
            throw StorefrontAPIError.missingID
        }
    }

    // MARK: - Storefront listing / browse (async, cursor-based)

    /// Matches server.js:
    /// GET /api/storefront?limit=24&afterId=<ObjectId>
    func fetchInventoryPage(
        afterId: String?,
        limit: Int
    ) async throws -> StorefrontListResponse {

        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.path = "/api/storefront"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let afterId = afterId {
            queryItems.append(URLQueryItem(name: "afterId", value: afterId))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw StorefrontAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // GET is public; header not required:
        // request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(StorefrontListResponse.self, from: data)
        return decoded
    }

    // MARK: - Auth (register)
    
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
    // MARK: - Runner Registration (async)
    func registerRunner(
        name: String,
        email: String,
        password: String,
        profileImage: Data? = nil,
        certificationPDF: Data? = nil,
        driversLicenseImage: Data? = nil
    ) async throws -> String {
        
        guard let url = URL(string: "/api/runner/register", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }
        
        // Create boundary for multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Helper to append a string field
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // Helper to append a file
        func appendFile(name: String, filename: String, data: Data, mimeType: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        // Add string fields
        appendField(name: "name", value: name)
        appendField(name: "email", value: email)
        appendField(name: "password", value: password)
        
        // Add files if present
        if let profileImage = profileImage {
            appendFile(name: "profileImage", filename: "profile.jpg", data: profileImage, mimeType: "image/jpeg")
        }
        if let certificationPDF = certificationPDF {
            appendFile(name: "certificationPDF", filename: "cert.pdf", data: certificationPDF, mimeType: "application/pdf")
        }
        if let driversLicenseImage = driversLicenseImage {
            appendFile(name: "driversLicenseImage", filename: "license.jpg", data: driversLicenseImage, mimeType: "image/jpeg")
        }
        
        // End boundary
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        // Send request
        let (data, response) = try await urlSession.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }
        
        // Decode response
        let decoded = try JSONDecoder().decode(RegisterResponse.self, from: data)
        return decoded.id
    }
    
    

    // MARK: Fetch the current runner's full user info using a JWT token
    func getCurrentRunner(token: String) async throws -> AuthUser {
        guard let url = URL(string: "/api/runner/me", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
    
    // MARK: Runner assignments fetching
    func getRunnerAssignments(runnerId: String) async throws -> [Assignment] {
        guard let url = URL(string: "/api/runners/\(runnerId)/assignments", relativeTo: baseURL) else {
            throw StorefrontAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Attach JWT token from Keychain for authorization
        if let token = KeychainHelper.read(key: "RUNNER_AUTH_TOKEN") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw StorefrontAPIError.httpStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StorefrontAPIError.httpStatus(http.statusCode)
        }

        // Decode array of assignments
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Assignment].self, from: data)

        //return try JSONDecoder().decode([Assignment].self, from: data)
    }


    // MARK: - Auth (login)

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

    // MARK: - Email verification & password reset (completion)

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

    // MARK: - Email verification & password reset (async)

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

        if data.isEmpty { return }

        let decoded = try JSONDecoder().decode(ResendVerificationResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(
                message: decoded.message ?? "Verification resend failed"
            )
        }
    }

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

        if data.isEmpty { return }

        let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(message: "Verify email code failed")
        }
    }

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

        if data.isEmpty { return }

        let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(message: "Forgot password failed")
        }
    }

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

        if data.isEmpty { return }

        let decoded = try JSONDecoder().decode(SimpleOKResponse.self, from: data)
        guard decoded.ok else {
            throw StorefrontAPIError.serverError(message: "Reset password failed")
        }
    }

    // MARK: - Gemini price estimate

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
        request.setValue(iosAPIKey, forHTTPHeaderField: "x-ios-key")

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
