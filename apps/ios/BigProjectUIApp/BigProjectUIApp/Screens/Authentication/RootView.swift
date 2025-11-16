//
//  RootView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        Group {
            if session.isAuthenticated {
                // 👉 As soon as you're logged in, go straight to your main app UI
                ContentView()           // or MainScreen() if that's your real landing view
            } else {
                // 👉 Login / Register / Forgot Password live in here
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}
