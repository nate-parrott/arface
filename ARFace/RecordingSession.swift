//
//  RecordingSession.swift
//  ARFace
//
//  Created by Nate Parrott on 12/3/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation

class RecordingSession {
    init() {
        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let uuid = NSUUID().uuidString
        audioURL = tempDir.appendingPathComponent(uuid + ".m4a")!
        recorder = try! AVAudioRecorder(url: audioURL, settings: [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
    }
    let recorder: AVAudioRecorder
    let audioURL: URL
    
    var recordingStartTime: TimeInterval?
    let recordAhead: TimeInterval = 1
    
    func start(started: @escaping (_ success: Bool) -> ()) {
        AVAudioSession.sharedInstance().requestRecordPermission { (permission) in
            DispatchQueue.main.async {
                if permission {
                    try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.defaultToSpeaker, .allowBluetooth])
                    try! AVAudioSession.sharedInstance().setActive(true)
                    
                    self.recordingStartTime = self.recorder.deviceCurrentTime + self.recordAhead
                    self.recorder.record(atTime: self.recordingStartTime!)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.recordAhead) {
                        started(true)
                    }
                } else {
                    started(false)
                }
            }
        }
    }
    
    func stop() {
        recorder.stop()
    }
    
    var audioRecordingStartTime: TimeInterval?
    var motionFrames = [MotionFrame]()
    
    struct MotionFrame {
        let time: TimeInterval // relative offset from start of recording
        let blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]
    }
    
    func addMotionFrame(anchor: ARFaceAnchor, session: ARSession) {
        guard let startTime = recordingStartTime else { return }
        let time = session.currentFrame!.timestamp - startTime
        motionFrames.append(MotionFrame(time: time, blendShapes: anchor.blendShapes))
    }
}
