//
//  HomeView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/14/25.
//

import SwiftUI

struct HomeView: View {

    // MARK: - Color Theme
    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)   // #1A1A1A
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)       // #D6A645
    private let textGray = Color.gray.opacity(0.6)

    var body: some View {
        NavigationStack {
            ZStack {
                bgBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // MARK: - Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Runner Dashboard")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)

                            Text("Your current assignments and tools")
                                .font(.subheadline)
                                .foregroundColor(textGray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        // MARK: - Feature Card
                        VStack(spacing: 22) {
                            SectionHeader(title: "Runner Tools", gold: gold)

                            NavigationLink {
                                RunnerProfileView()
                            } label: {
                                FeatureRow(
                                    icon: "person.crop.circle.fill",
                                    label: "Runner Profile",
                                    description: "View and edit your profile information."
                                )
                            }

                            NavigationLink {
                                PickupWorkflowView()
                            } label: {
                                FeatureRow(
                                    icon: "shippingbox.fill",
                                    label: "Pickup Workflow",
                                    description: "View instructions for current packages."
                                )
                            }

                            NavigationLink {
                                ChatView()
                            } label: {
                                FeatureRow(
                                    icon: "bubble.left.and.bubble.right.fill",
                                    label: "Communication with Client",
                                    description: "Send and receive messages with buyers."
                                )
                            }
                        }
                        .padding(20)
                        .background(cardDark)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 3)
                        .padding(.horizontal)


                        // MARK: - Buttons
                        VStack(spacing: 18) {

                            NavigationLink {
                                RunnerMapView()   // << Works now
                            } label: {
                                GoldButtonContent(
                                    title: "Start Shift",
                                    icon: "figure.walk",
                                    gold: gold
                                )
                            }

                            NavigationLink {
                                MeetupScreen()   // works now
                            } label: {
                                GoldButtonContent(
                                    title: "Navigate to Meetup",
                                    icon: "mappin.and.ellipse",
                                    gold: gold
                                )
                            }

                            NavigationLink {
                                AssignmentsView() // works now
                            } label: {
                                GoldButtonContent(
                                    title: "View Assignments",
                                    icon: "list.bullet.clipboard",
                                    gold: gold
                                )
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - Footer
                        Text("Runnr • Powered by LEV")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 40)
                    }
                    .padding(.vertical, 40)
                }
            }
        }
    }
}

//
// MARK: - Components
//

struct SectionHeader: View {
    let title: String
    let gold: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Circle()
                .fill(gold)
                .frame(width: 8, height: 8)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let label: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .foregroundColor(.white)
                    .font(.headline)

                Text(description)
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.caption)
            }

            Spacer()
        }
    }
}

// MARK: - Gold Button Content
struct GoldButtonContent: View {
    let title: String
    let icon: String
    let gold: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding()
        .background(gold)
        .cornerRadius(10)
    }
}

