//
//  AuthSelectionView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

struct AuthSelectionView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Runner App")
                .font(.largeTitle)
                .bold()
            
            NavigationLink(destination: LoginView()) {
                Text("Login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            NavigationLink(destination: RegisterView()) {
                Text("Register")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
