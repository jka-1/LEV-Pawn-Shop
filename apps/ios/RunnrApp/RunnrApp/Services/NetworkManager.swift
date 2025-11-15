//
import Foundation
import UIKit

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

enum FileType: String {
    case profileImage = "profile_image"
    case pdf = "pdf"
    case driverLicense = "driver_license"
}

class NetworkManager {
    
    static let shared = NetworkManager()
    private let baseURL = "http://your-api-url.com"
    
    private init() {}
    
    // MARK: - Authentication
    
    func login(email: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let body: [String: Any] = ["email": email, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.serverError(error.localizedDescription)))
                return
            }
            guard let data = data else { completion(.failure(.noData)); return }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func register(name: String, email: String, password: String,
                  profileImage: Data?, pdf: Data?, dlImage: Data?,
                  completion: @escaping (Result<User, NetworkError>) -> Void) {
        
        guard let url = URL(string: "\(baseURL)/register") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construct multipart body
        var body = Data()
        
        // Text fields
        let params: [String: String] = ["name": name, "email": email, "password": password]
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Files
        if let profileImage = profileImage {
            body.append(multipartData(fieldName: FileType.profileImage.rawValue, fileName: "profile.jpg", mimeType: "image/jpeg", fileData: profileImage, boundary: boundary))
        }
        if let pdf = pdf {
            body.append(multipartData(fieldName: FileType.pdf.rawValue, fileName: "resume.pdf", mimeType: "application/pdf", fileData: pdf, boundary: boundary))
        }
        if let dlImage = dlImage {
            body.append(multipartData(fieldName: FileType.driverLicense.rawValue, fileName: "dl.jpg", mimeType: "image/jpeg", fileData: dlImage, boundary: boundary))
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.serverError(error.localizedDescription)))
                return
            }
            guard let data = data else { completion(.failure(.noData)); return }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func logout(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/logout") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            completion(true)
        }.resume()
    }
    
    // MARK: - Assignments
    
    func getAssignments(completion: @escaping (Result<[Assignment], NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/assignments") else { completion(.failure(.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(.serverError(error.localizedDescription)))
                return
            }
            guard let data = data else { completion(.failure(.noData)); return }
            do {
                let assignments = try JSONDecoder().decode([Assignment].self, from: data)
                completion(.success(assignments))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func updateAssignmentStatus(id: String, status: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/assignments/\(id)") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            completion(true)
        }.resume()
    }
    
    // MARK: - Helper for Multipart
    private func multipartData(fieldName: String, fileName: String, mimeType: String, fileData: Data, boundary: String) -> Data {
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        return data
    }
    
    // MARK: - Optional: File Download
    func downloadFile(from url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data)
        }.resume()
    }
    
    // MARK: - Optional: Runner Location
    func sendRunnerLocation(runnerId: String, latitude: Double, longitude: Double, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/runner/\(runnerId)/location") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["latitude": latitude, "longitude": longitude]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            completion(true)
        }.resume()
    }
}