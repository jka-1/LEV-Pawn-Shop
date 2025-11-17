//
//  RunnrAppApp.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

@main
struct RunnrAppApp: App {
    @StateObject private var runnerState = RunnerState()
    @StateObject private var auth = RunnerAuthState()   // <-- FIXED: added initializer

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
            .environmentObject(auth)   // <-- ensures all child views have access
        }
    }
}
