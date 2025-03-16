//
//  ContentView.swift
//  Audio-playback
//
//  Created by Xcode on 2025/03/16.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State var queuePlayer = AVQueuePlayer()
    @State var totalTime: CMTime?
    @State var currentTime: Double = 0.0
    @State var nextIndex = 0
    @State var urls: [URL] = []
    @State var nextItem: AVPlayerItem?
    
    var body: some View {
        VStack {
            if let totalTime = totalTime {
                VStack {
                    Slider(value: Binding(
                        get: { currentTime },
                        set: { newValue in seekAudio(to: newValue)}
                    ), in: 0...CMTimeGetSeconds(totalTime))
                    
                    HStack {
                        Text(formatTime(seconds: currentTime))
                        Spacer()
                        Text(formatTime(seconds: CMTimeGetSeconds(totalTime)))
                    }
                    Spacer().frame(height: 30)
                    HStack(spacing: 30) {
                        Button(
                            action: {
                                queuePlayer.remove(nextItem!)
//                                print("count after remove: \(queuePlayer.items().count)")
                                nextIndex -= 2
                                if nextIndex < 0 {
                                    nextIndex += urls.count
                                }
                                nextItem = AVPlayerItem(url: urls[nextIndex])
                                queuePlayer.insert(nextItem!, after: nil)
                                seekToNext()
                            },
                            label: {
                                Image(systemName: "backward.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        )
                        Button(
                            action: { seekToStart() },
                            label: {
                                Image(systemName: "backward.end.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        )
                        Button(
                            action: { isPlaying() ? pauseAudio() : playAudio() },
                            label: {
                                Image(systemName: isPlaying() ? "pause.fill" : "play.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        )
                        Button("    ") { }
                        Button(
                            action: {
                                seekToNext()
                            },
                            label: {
                                Image(systemName: "forward.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        )
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .padding([.leading, .trailing], 15)
        .task {
            await setupAudio()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) {_ in updateProgress() }
        .onChange(of: queuePlayer.currentItem) {
            nextIndex += 1
            if nextIndex == urls.count {
                nextIndex = 0
            }
            nextItem = AVPlayerItem(url: urls[nextIndex])
            queuePlayer.insert(nextItem!, after: nil)
//            print("count onChange: \(queuePlayer.items().count)")
            
            Task {
                totalTime = try! await queuePlayer.currentItem?.asset.load(.duration)
            }
        }
    }
    
    private func setupAudio() async {
        guard let url1 = Bundle.main.url(forResource: "mixkit-epical-drums-01-676", withExtension: "mp3")
        else {
            return
        }
        guard let url2 = Bundle.main.url(forResource: "mixkit-dirty-thinkin-989", withExtension: "mp3")
        else {
            return
        }
        
        urls.append(url1)
        urls.append(url2)
        nextItem = AVPlayerItem(url: urls[0])
        queuePlayer = AVQueuePlayer(playerItem: nextItem)
        queuePlayer.actionAtItemEnd = .advance
        totalTime = try! await queuePlayer.currentItem?.asset.load(.duration)
    }
    
    private func playAudio() {
        queuePlayer.play()
    }
    
    private func pauseAudio() {
        queuePlayer.pause()
    }
    
    private func seekAudio(to time: Double) {
        queuePlayer.seek(to: CMTime(seconds: time, preferredTimescale: 1))
    }
    
    private func seekToStart() {
        queuePlayer.seek(to: CMTime(seconds: 0.0, preferredTimescale: 1))
    }
    
    private func seekToNext() {
        queuePlayer.advanceToNextItem()
        seekToStart()
    }
    
    private func updateProgress() {
        currentTime = CMTimeGetSeconds(queuePlayer.currentTime())
    }
    
    private func isPlaying() -> Bool {
        return queuePlayer.timeControlStatus == .playing
    }
    
    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
