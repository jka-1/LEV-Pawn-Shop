//
//  HomeView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var runner: RunnerState
    @StateObject var locationManager = RunnerLocationManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Runner Dashboard")
                .font(.largeTitle)
                .bold()

            Toggle(isOn: $runner.isOnline) {
                Text(runner.isOnline ? "Online" : "Offline")
                    .font(.headline)
            }
            .padding()

            if !locationManager.isAuthorized {
                Button("Enable Location") {
                    locationManager.requestPermission()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            NavigationLink(destination:
                RunnerMapView()
                    .environmentObject(locationManager)
            ) {
                Text("Start Running")
                    .font(.headline)
                    .padding()
                    .frame(width: 200)
                    .background(runner.isOnline ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!runner.isOnline)

            Spacer()
        }
        .padding()
    }
}

