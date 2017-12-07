//
//  PlaybackSession.swift
//  ARFace
//
//  Created by Nate Parrott on 12/3/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import UIKit
import AVFoundation

class PlaybackSession: NSObject {
    init(motionFrames: [RecordingSession.MotionFrame], audioURL: URL) {
        self.motionFrames = motionFrames
        audioPlayer = try! AVAudioPlayer(contentsOf: audioURL)
        audioPlayer.numberOfLoops = Int(INT32_MAX)
        super.init()
    }
    
    convenience init(recordingSession: RecordingSession) {
        self.init(motionFrames: recordingSession.motionFrames, audioURL: recordingSession.audioURL)
    }
    
    convenience init(playbackSession: PlaybackSession) {
        self.init(motionFrames: playbackSession.motionFrames, audioURL: playbackSession.audioPlayer.url!)
    }
    
    typealias FrameCallback = (RecordingSession.MotionFrame) -> ()
    
    let motionFrames: [RecordingSession.MotionFrame]
    let audioPlayer: AVAudioPlayer
    
    var frameCallback: FrameCallback?
    var timer: Timer?
    var prevTime: TimeInterval?
    
    func start() {
        audioPlayer.currentTime = 0
        prevTime = 0
        audioPlayer.play()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60, repeats: true, block: { [weak self] (_) in
            self?.deliverFrameCallback()
        })
    }
    
    func stop() {
        audioPlayer.stop()
        timer?.invalidate()
        timer = nil
    }
    
    func deliverFrameCallback() {
        if audioPlayer.isPlaying {
            if let frame = findFrame(nearTime: audioPlayer.currentTime), let cb = frameCallback {
                cb(frame)
            }
            if let prev = prevTime {
                if audioPlayer.currentTime < prev && prev - audioPlayer.currentTime > 0.01 {
                    if let cb = onDone {
                        cb()
                    }
                }
            }
            prevTime = audioPlayer.currentTime
        }
    }
    
    func findFrame(nearTime time: TimeInterval) -> RecordingSession.MotionFrame? {
        if motionFrames.count == 0 { return nil }
        var a = 0
        var b = motionFrames.count - 1
        while a < b {
            let mid = (a + b) / 2
            if mid == a { break }
            let midTime = motionFrames[mid].time
            if midTime < time {
                a = mid
            } else {
                b = mid
            }
        }
        return motionFrames[min(motionFrames.count, a)]
    }
    
    var onDone: (() -> ())?
}
