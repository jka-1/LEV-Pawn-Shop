//
//  StorefrontAPI.swift
//
//  Simple client for POST /api/storefront on https://bibe.stream
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

    // MARK: - Public API (completion handler)

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

    // MARK: - Async/await variant (iOS 15+)

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
}

// MARK: - Example usage (you can delete this in production)

// Completion-based
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
*/
