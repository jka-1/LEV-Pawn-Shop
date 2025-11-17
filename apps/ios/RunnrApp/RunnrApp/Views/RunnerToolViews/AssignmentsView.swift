//
//  AssignmentsView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import SwiftUI

struct AssignmentsView: View {
    @EnvironmentObject var auth: RunnerAuthState  // get current runner info
    @State private var assignments: [Assignment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)
    private let textGray = Color.gray.opacity(0.6)

    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()

            if isLoading {
                ProgressView("Loading assignments...")
                    .progressViewStyle(CircularProgressViewStyle(tint: gold))
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Your Assignments", gold: gold)

                        ForEach(assignments) { assignment in
                            AssignmentCard(assignment: assignment, gold: gold, cardDark: cardDark)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadAssignments()
        }
        .navigationTitle("Assignments")
        .navigationBarTitleDisplayMode(.inline)
    }

    func loadAssignments() {
        guard let runnerId = auth.currentUser?.id else {
            errorMessage = "No logged-in runner"
            isLoading = false
            return
        }

        Task {
            do {
                isLoading = true
                assignments = try await StorefrontAPI.shared.getRunnerAssignments(runnerId: runnerId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load assignments: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
