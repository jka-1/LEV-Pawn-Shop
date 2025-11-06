//
//  RunnrAppApp.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

@main
struct RunnrAppApp: App {
    @StateObject var runnerState = RunnerState()
    @StateObject var auth = RunnerAuthState()

    var body: some Scene {
            WindowGroup {
                NavigationView {
                    if auth.isLoggedIn {
                        HomeView()
                            .environmentObject(runnerState)
                    } else {
                        AuthSelectionView()
                    }
                }
                .environmentObject(auth)
            }
        }
}
