//
//  LoopingVideoBackground.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


//
//  LoopingVideoBackground.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import AVKit

// MARK: - Looping Video Background

struct LoopingVideoBackground: View {
    let videoName: String
    var fileExtension: String = "mp4"
    
    var body: some View {
        LoopingVideoPlayer(videoName: videoName, fileExtension: fileExtension)
            .ignoresSafeArea()
    }
}

// MARK: - Video Player UIViewRepresentable

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    let fileExtension: String
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(videoName: videoName, fileExtension: fileExtension)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}

// MARK: - Player UIView

class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    init(videoName: String, fileExtension: String) {
        super.init(frame: .zero)
        setupPlayer(videoName: videoName, fileExtension: fileExtension)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(videoName: String, fileExtension: String) {
        // Find video file in bundle
        guard let url = Bundle.main.url(forResource: videoName, withExtension: fileExtension) else {
            print("⚠️ Video not found: \(videoName).\(fileExtension)")
            return
        }
        
        // Create player item and queue player
        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.queuePlayer = queuePlayer
        
        // Create looper for seamless looping
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // Create and configure player layer
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        // Mute and play
        queuePlayer.isMuted = true
        queuePlayer.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    deinit {
        queuePlayer?.pause()
        playerLooper?.disableLooping()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LoopingVideoBackground(videoName: "bg flow")
        
        Text("Video Background")
            .font(.title)
            .foregroundColor(.white)
    }
}
