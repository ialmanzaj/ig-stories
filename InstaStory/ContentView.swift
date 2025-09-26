//
//  ContentView.swift
//  InstaStory
//
//  Created by Isaac on 09/25/25.
//

import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ContentView: View {
    var imageNames: [String] = ["image01","image02","image03","image04"]
    @ObservedObject var storyTimer: StoryTimer = StoryTimer(items: 4, duration: 15.0)

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Image(imageNames[safe: Int(storyTimer.progress)] ?? imageNames.last!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: nil, alignment: .center)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityIdentifier("StoryImage")

                HStack(alignment: .center, spacing: 4) {
                    ForEach(0..<imageNames.count, id: \.self) { x in
                        LoadingRectangle(progress: min( max( (CGFloat(storyTimer.progress) - CGFloat(x)), 0.0) , 1.0))
                            .frame(width: nil, height: 4, alignment: .leading)
                            .animation(.none, value: storyTimer.progress)
                            .accessibilityIdentifier("ProgressBar\(x)")
                            .onTapGesture {
                                storyTimer.jumpToStory(x)
                            }
                    }
                }.padding()
                .accessibilityIdentifier("ProgressBarContainer")

                HStack(alignment: .center, spacing: 0) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .frame(maxWidth: geometry.size.width * 0.33)
                        .accessibilityIdentifier("LeftNavigationZone")
                        .onTapGesture {
                            guard storyTimer.state != .pausedByHold else { return }
                            storyTimer.advance(by: -1)
                        }
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .frame(maxWidth: geometry.size.width * 0.67)
                        .accessibilityIdentifier("RightNavigationZone")
                        .onTapGesture {
                            guard storyTimer.state != .pausedByHold else { return }
                            storyTimer.advance(by: 1)
                        }
                }
                .accessibilityIdentifier("NavigationZones")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if storyTimer.state == .playing {
                                storyTimer.pause()
                            }
                        }
                        .onEnded { _ in
                            if storyTimer.state == .pausedByHold {
                                storyTimer.resume()
                            }
                        }
                )
            }
            .accessibilityIdentifier("StoryView")
        }
        .onAppear { storyTimer.start() }
        .onDisappear { storyTimer.cancel() }
    }

}

#Preview {
    ContentView()
}
