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
    
    // MARK: - Color Theme
    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)   // #1A1A1A
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)       // #D6A645
    private let textGray = Color.gray.opacity(0.6)
    
    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // MARK: - Title
                Text("Login")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                // MARK: - Card with Inputs
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    
                    Button {
                        auth.login(email: email, password: password)
                    } label: {
                        GoldButtonContent(title: "Login", icon: "lock.fill", gold: gold)
                    }
                }
                .padding(25)
                .background(cardDark)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.7), radius: 10, y: 3)
                .padding(.horizontal)
                
                Spacer()
                
                // MARK: - Footer
                Text("Runnr • Powered by LEV")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.vertical, 60)
            .padding(.horizontal, 20)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
                .environmentObject(RunnerAuthState())
        }
    }
}

