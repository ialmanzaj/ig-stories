//
//  LoadingRectangle.swift
//  InstaStory
//
//  Created by Isaac on 09/25/25.
//


import SwiftUI

struct LoadingRectangle: View {

    var progress: CGFloat
    var storyIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.white.opacity(0.3))
                    .cornerRadius(5)

                Rectangle()
                    .frame(width: geometry.size.width * self.progress, height: nil, alignment: .leading)
                    .foregroundColor(Color.white.opacity(0.9))
                    .cornerRadius(5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(storyIndex != nil ? "Story \(storyIndex! + 1)" : "Story progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
        .accessibilityHint("Tap to jump to this story")
    }
}

struct LoadingRectangle_Previews: PreviewProvider {
    static var previews: some View {
        LoadingRectangle(progress: 0.7, storyIndex: 0)
    }
}