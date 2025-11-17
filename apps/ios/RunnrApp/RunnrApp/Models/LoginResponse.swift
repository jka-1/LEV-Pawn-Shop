//
//  LoginResponse.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import Foundation

/// Decodes the response returned by the backend when a runner logs in.
struct LoginResponse: Codable {
    /// The runner ID or JWT token returned from the backend
    let id: String
}
