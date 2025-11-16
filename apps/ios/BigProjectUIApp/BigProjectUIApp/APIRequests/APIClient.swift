//
//  APIClient.swift
//
//  Simple client for POST /api/storefront and auth endpoints on https://bibe.stream
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
*/
