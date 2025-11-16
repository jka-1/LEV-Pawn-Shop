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
            if session.isLoggedIn {
                // 👉 Load your real app here
                ContentView()
            } else {
                // 👉 Load login flow
                LoginView()
            }
        }
        .animation(.easeInOut, value: session.isLoggedIn)
    }
}
