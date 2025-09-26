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

    @State private var isDragging: Bool = false
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Image(imageNames[safe: Int(storyTimer.progress)] ?? imageNames.last!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: nil, alignment: .center)
                    .clipped()

                HStack(alignment: .center, spacing: 4) {
                    ForEach(imageNames.indices) { x in
                        LoadingRectangle(progress: min( max( (CGFloat(storyTimer.progress) - CGFloat(x)), 0.0) , 1.0))
                            .frame(width: nil, height: 4, alignment: .leading)
                            .animation(.linear)
                            .onTapGesture {
                                storyTimer.jumpToStory(x)
                            }
                    }
                }.padding()
                HStack(alignment: .center, spacing: 0) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            storyTimer.advance(by: -1)
                        }
                        .onLongPressGesture(minimumDuration: 0.2) {
                            // Long press handled by main gesture
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                if storyTimer.state == .playing {
                                    storyTimer.pause()
                                }
                            } else {
                                if storyTimer.state == .pausedByHold {
                                    storyTimer.resume()
                                }
                            }
                        }
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            storyTimer.advance(by: 1)
                        }
                        .onLongPressGesture(minimumDuration: 0.2) {
                            // Long press handled by main gesture
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                if storyTimer.state == .playing {
                                    storyTimer.pause()
                                }
                            } else {
                                if storyTimer.state == .pausedByHold {
                                    storyTimer.resume()
                                }
                            }
                        }
                }
            }
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1 - abs(dragOffset.height) / geometry.size.height * 0.3 : 1.0)
            .background(Color.black.opacity(isDragging ? 0.7 : 1.0))
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        let translation = value.translation

                        // Vertical drag to dismiss
                        if abs(translation.height) > abs(translation.width) &&
                           abs(translation.height) >= 8 &&
                           storyTimer.state != .pausedByHold {

                            if !isDragging {
                                isDragging = true
                                if storyTimer.state == .playing {
                                    storyTimer.pause()
                                }
                            }
                            dragOffset = translation
                        }
                    }
                    .onEnded { value in
                        if isDragging {
                            let shouldDismiss = abs(value.translation.height) > geometry.size.height * 0.33 ||
                                              abs(value.velocity.height) > 800

                            if shouldDismiss {
                                storyTimer.enterDismissing()
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = CGSize(width: 0, height: value.translation.height > 0 ? geometry.size.height : -geometry.size.height)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dragOffset = .zero
                                    isDragging = false
                                    storyTimer.cancel()
                                }
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                                if storyTimer.state == .pausedByHold {
                                    storyTimer.resume()
                                }
                            }
                            isDragging = false
                        }
                    }
            )
        }
        .onAppear { storyTimer.start() }
        .onDisappear { storyTimer.cancel() }
    }

}

#Preview {
    ContentView()
}
