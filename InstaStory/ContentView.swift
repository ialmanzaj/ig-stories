//
//  ContentView.swift
//  InstaStory
//
//  Created by Isaac on 09/25/25.
//

import SwiftUI


struct HomeView: View {
  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        NavigationLink("Open Stories") {
          StoriesScreen()
        }
        .buttonStyle(.borderedProminent)
      }
      .padding()
      .navigationTitle("Home")
    }
  }
}

// MARK: - SwiftUI Preview
/// Preview provider for Xcode canvas development and testing
#Preview {
    HomeView()
}
