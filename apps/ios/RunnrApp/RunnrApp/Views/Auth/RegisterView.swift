//
//  RegisterView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: RunnerAuthState
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.largeTitle)
                .bold()
            
            TextField("Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            Button("Create Account") {
                auth.register(name: name, email: email, password: password)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
}
