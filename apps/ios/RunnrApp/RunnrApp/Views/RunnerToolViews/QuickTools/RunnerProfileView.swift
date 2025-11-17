//
//  RunnerProfileView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import SwiftUI

struct RunnerProfileView: View {
    @EnvironmentObject var auth: RunnerAuthState

    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)
    private let textGray = Color.gray.opacity(0.6)

    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()

            VStack(spacing: 20) {
                if let user = auth.currentUser {
                    VStack(spacing: 12) {
                        Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                            .font(.title.bold())
                            .foregroundColor(gold)

                        Text(user.email)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.subheadline)
                        
                        Divider().background(Color.gray)
                        
                        HStack {
                            Text("Completed Assignments:")
                                .foregroundColor(.white)
                                .bold()
                            Text("12") // placeholder, add api
                                .foregroundColor(gold)
                        }

                        HStack {
                            Text("Active Assignments:")
                                .foregroundColor(.white)
                                .bold()
                            Text("3") // placeholder, add api
                                .foregroundColor(gold)
                        }
                    }
                    .padding()
                    .background(cardDark)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.7), radius: 5, y: 2)
                } else {
                    Text("No user logged in")
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Runner Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
