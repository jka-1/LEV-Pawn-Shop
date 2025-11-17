//
//  ChatView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import SwiftUI

struct ChatView: View {
    @State private var messages: [String] = [
        "Hi, I'm on my way to pickup the item.",
        "Thanks, please verify the packaging on arrival."
    ]
    @State private var newMessage = ""
    
    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)

    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()

            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(messages.indices, id: \.self) { i in
                                HStack {
                                    if i % 2 == 0 {
                                        Spacer()
                                        Text(messages[i])
                                            .padding()
                                            .background(gold)
                                            .foregroundColor(.black)
                                            .cornerRadius(12)
                                    } else {
                                        Text(messages[i])
                                            .padding()
                                            .background(cardDark)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .onChange(of: messages.count) { _ in
                            if let last = messages.indices.last {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }

                HStack {
                    TextField("Type a message...", text: $newMessage)
                        .padding()
                        .background(cardDark)
                        .foregroundColor(.white)
                        .cornerRadius(12)

                    Button {
                        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        messages.append(newMessage)
                        newMessage = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(gold)
                            .padding(10)
                            .background(cardDark)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Chat with Client")
        .navigationBarTitleDisplayMode(.inline)
    }
}
