//
//  PickupWorkflowView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import SwiftUI

struct PickupWorkflowView: View {
    @State private var assignments: [Assignment] = [] // Fetch from API later
    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)

    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Pickup Workflow")
                        .font(.largeTitle.bold())
                        .foregroundColor(gold)
                        .padding(.bottom, 10)

                    ForEach(assignments) { assignment in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(assignment.title)
                                .bold()
                                .foregroundColor(.white)
                            if let desc = assignment.description {
                                Text(desc)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            if let address = assignment.address {
                                Text("Address: \(address)")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(cardDark)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Pickup Workflow")
        .navigationBarTitleDisplayMode(.inline)
    }
}
