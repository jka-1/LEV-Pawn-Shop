//
//  MeetupScreen.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import SwiftUI
import MapKit

struct MeetupScreen: View {
    @EnvironmentObject var auth: RunnerAuthState
    @State private var meetup: MeetupPoint?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)
    private let textGray = Color.gray.opacity(0.6)

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()

            if isLoading {
                ProgressView("Loading meetup info...")
                    .progressViewStyle(CircularProgressViewStyle(tint: gold))
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if let meetup {
                ScrollView {
                    VStack(spacing: 20) {
                        SectionHeader(title: "Meetup Point", gold: gold)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Name:")
                                    .bold()
                                    .foregroundColor(.white)
                                Text(meetup.name)
                                    .foregroundColor(.white)
                            }

                            Map(coordinateRegion: $region, annotationItems: [meetup]) { point in
                                MapAnnotation(coordinate: point.coordinate) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title)
                                            .foregroundColor(gold)
                                            .shadow(radius: 3)
                                        Text(point.name)
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .frame(height: 250)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.7), radius: 5, y: 2)
                        }
                        .padding()
                        .background(cardDark)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                Text("No meetup scheduled.")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadMeetup()
        }
        .navigationTitle("Meetup")
        .navigationBarTitleDisplayMode(.inline)
    }

    func loadMeetup() {
        guard let runnerId = auth.currentUser?.id else {
            errorMessage = "No logged-in runner"
            isLoading = false
            return
        }

        Task {
            do {
                isLoading = true
                meetup = try await StorefrontAPI.shared.getRunnerMeetup(runnerId: runnerId)
                if let meetup = meetup {
                    region.center = meetup.coordinate
                }
                isLoading = false
            } catch {
                errorMessage = "Failed to load meetup: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
