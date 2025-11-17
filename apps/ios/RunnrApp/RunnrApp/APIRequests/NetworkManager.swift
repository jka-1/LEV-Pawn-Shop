import Foundation
import UIKit

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data returned from server"
        case .decodingError: return "Failed to decode server response"
        case .serverError(let message): return message
        case .badResponse(let code): return "Server returned status code \(code)"
        }
    }
}

enum FileType: String {
    case profileImage = "profile_image"
    case pdf = "pdf"
    case driverLicense = "driver_license"
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://your-api-url.com"  // <- Update to real backend

    private init() {}

    // MARK: - Login (async)
    func login(email: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw NetworkError.invalidURL
        }

        let payload: [String: Any] = ["email": email, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: payload, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateResponse(response)

        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // MARK: - Register (async w/ multipart)
    func register(
        name: String,
        email: String,
        password: String,
        profileImage: Data?,
        pdf: Data?,
        dlImage: Data?
    ) async throws -> User {

        guard let url = URL(string: "\(baseURL)/register") else {
            throw NetworkError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = try await createMultipartRequestBody(
            boundary: boundary,
            params: ["name": name, "email": email, "password": password],
            profileImage: profileImage,
            pdf: pdf,
            dlImage: dlImage
        )

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateResponse(response)

        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // MARK: - Logout
    func logout() async -> Bool {
        guard let url = URL(string: "\(baseURL)/logout") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            _ = try await URLSession.shared.data(for: request)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Get Assignments
    func getAssignments() async throws -> [Assignment] {
        guard let url = URL(string: "\(baseURL)/assignments") else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode([Assignment].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // MARK: - Update Assignment
    func updateAssignmentStatus(id: String, status: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/assignments/\(id)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])

        do {
            _ = try await URLSession.shared.data(for: request)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Multipart Helper
    private func createMultipartRequestBody(
        boundary: String,
        params: [String: String],
        profileImage: Data?,
        pdf: Data?,
        dlImage: Data?
    ) async throws -> Data {

        var body = Data()

        // Text fields
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // File fields
        if let profileImage {
            body.append(filePart(field: FileType.profileImage.rawValue, fileName: "profile.jpg", mimeType: "image/jpeg", data: profileImage, boundary: boundary))
        }

        if let pdf {
            body.append(filePart(field: FileType.pdf.rawValue, fileName: "resume.pdf", mimeType: "application/pdf", data: pdf, boundary: boundary))
        }

        if let dlImage {
            body.append(filePart(field: FileType.driverLicense.rawValue, fileName: "dl.jpg", mimeType: "image/jpeg", data: dlImage, boundary: boundary))
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func filePart(field: String, fileName: String, mimeType: String, data: Data, boundary: String) -> Data {
        var part = Data()
        part.append("--\(boundary)\r\n".data(using: .utf8)!)
        part.append("Content-Disposition: form-data; name=\"\(field)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        part.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        part.append(data)
        part.append("\r\n".data(using: .utf8)!)
        return part
    }

    // MARK: - Response Validator
    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.badResponse(http.statusCode)
        }
    }
}
