//
//  RelaxationAudioManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/16/25.
//


//
//  RelaxationAudioManager.swift
//  NoMas
//
//  Audio manager for relaxation/meditation sounds with looping support
//

import Foundation
import AVFoundation
import Combine

class RelaxationAudioManager: ObservableObject {
    static let shared = RelaxationAudioManager()
    
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: TimeInterval = 0
    @Published var currentSoundName: String?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: AnyCancellable?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }
    
    func playSound(from url: URL, named soundName: String) {
        // Stop any currently playing sound
        stop()
        
        isLoading = true
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        currentSoundName = soundName
        
        // Observe player item status using Combine
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        self?.isLoading = false
                        self?.isPlaying = true
                        print("▶️ Playing: \(soundName)")
                    case .failed:
                        self?.isLoading = false
                        self?.isPlaying = false
                        print("❌ Failed to load audio")
                    case .unknown:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        
        // Enable looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        player?.play()
        
        print("⏳ Loading: \(soundName) from URL: \(url)")
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
            print("⏸ Paused")
        } else {
            player.play()
            isPlaying = true
            print("▶️ Resumed")
        }
    }
    
    func stop() {
        player?.pause()
        
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        statusObserver?.cancel()
        statusObserver = nil
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        player = nil
        isPlaying = false
        isLoading = false
        currentTime = 0
        currentSoundName = nil
        
        print("⏹ Stopped")
    }
    
    deinit {
        stop()
    }
}