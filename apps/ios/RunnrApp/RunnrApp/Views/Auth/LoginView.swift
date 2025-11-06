//
//  LoginView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: RunnerAuthState
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            Button("Login") {
                auth.login(email: email, password: password)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
}
