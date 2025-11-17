//
//  ForgotPasswordView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var message: String?
    
    // Use the same gold color as your app theme
    let goldColor = Color(red: 0.84, green: 0.65, blue: 0.27)
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Forgot Password")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(goldColor)
                .padding(.top, 60)
            
            Text("Enter your email to receive a reset link. If your email is unverified, please verify it on desktop first.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal)
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)
            
            if let message = message {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: sendResetEmail) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: goldColor))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                } else {
                    Text("Send Reset Link")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(goldColor)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .disabled(isLoading || email.isEmpty)
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    func sendResetEmail() {
        guard !email.isEmpty else {
            message = "Please enter your email."
            return
        }
        
        isLoading = true
        message = nil
        
        Task {
            do {
                try await StorefrontAPI.shared.forgotPassword(email: email)
                
                DispatchQueue.main.async {
                    message = "Reset email sent! Check your inbox."
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    if let apiError = error as? StorefrontAPIError {
                        switch apiError {
                        case .serverError(let msg):
                            message = msg
                        default:
                            message = "Failed to send reset email. Please try again."
                        }
                    } else {
                        message = "Network error. Please try again."
                    }
                    isLoading = false
                }
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
