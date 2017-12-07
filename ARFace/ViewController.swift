//
//  ViewController.swift
//  ARFace
//
//  Created by Nate Parrott on 11/27/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var pageSwiper: PageSwiperScrollView!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var postRecordButtons: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let cornerRadius: CGFloat = 5
        recordButton.layer.cornerRadius = cornerRadius
        for view in postRecordButtons.subviews {
            if let button = view as? UIButton {
                button.layer.cornerRadius = cornerRadius
            }
        }
        
        isRecording = false
        playbackSession = nil
        
        sceneView.delegate = self
        pageSwiper.nPages = characters.count
        pageSwiper.callback = { [weak self] (page, offset) in
            self?.currentCharacterIndex = page
            self?.characterPositionOffset = Float(offset)
        }
    }
    
    // MARK: High-level options
    let characters: [Character] = [
        SkullCharacter(),
        HqToiletCharacter(),
        ToiletCharacter(),
        ToiletAltCharacter(),
        ToiletCharacter(),
        ToiletAltCharacter()
    ]
    
    var currentCharacterIndex = -1 {
        didSet(old) {
            if old != currentCharacterIndex {
                currentCharacter = characters[currentCharacterIndex]
            }
        }
    }
    
    var currentCharacter: Character? {
        didSet {
            self.characterNode = nil
            self.morpher = nil
            if let character = currentCharacter {
                let (node: node, morpher: morpher) = character.create(mode: .selfie)
                self.characterNode = node
                self.morpher = morpher
            }
        }
    }
    
    var characterPositionOffset: Float = 0
    
    // MARK: Persistent anchors
    var faceNode: SCNNode!
    var faceGeoNode: SCNNode!
    var faceOverlayNode: SCNNode!
    
    // MARK: Character-based nodes
    var characterNode: SCNNode? {
        didSet(old) {
            old?.removeFromParentNode()
            if let c = characterNode {
                faceOverlayNode.addChildNode(c)
            }
        }
    }
    var morpher: SCNMorpher?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // create face overlay:
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        faceGeoNode = SCNNode(geometry: faceGeometry)
        let material = faceGeometry.firstMaterial!
        material.colorBufferWriteMask = []
        faceGeoNode.renderingOrder = -1
        
        faceOverlayNode = SCNNode()
        // faceOverlayNode.addChildNode(faceGeoNode)

        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        // configuration.isLightEstimationEnabled = true
        
        sceneView.scene.background.contents = UIColor.black
        // sceneView.scene.lightingEnvironment.contents = bgImage
        // sceneView.autoenablesDefaultLighting = true
        sceneView.configureEnvLighting()
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        if currentCharacterIndex == -1 {
            currentCharacterIndex = 0
        }
        
        playbackSession?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // TODO: stop recording, pause playback
        if isRecording { stopRecording() }
        playbackSession?.stop()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Hold onto the `faceNode` so that the session does not need to be restarted when switching masks.
        faceNode = node
        faceNode.addChildNode(faceOverlayNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // sceneView.updateEnvLighting()
    }
    
    /// - Tag: ARFaceGeometryUpdate
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        if let character = self.characterNode {
            guard let parent = character.parent else { return }
            
            if playbackSession == nil {
                let geo = faceGeoNode.geometry! as! ARSCNFaceGeometry
                geo.update(from: faceAnchor.geometry)
                updateBlendShapes(faceAnchor.blendShapes)
                recordingSession?.addMotionFrame(anchor: faceAnchor, session: sceneView.session)
            }
            
            character.position = sceneView.pointOfView!.convertPosition(SCNVector3(characterPositionOffset * 0.5, 0, -0.4), to: parent)
        }
    }
    
    func updateBlendShapes(_ shapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        if let morpher = self.morpher {
            morpher.applyBlendShapes(shapes)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: Recording
    
    var isRecording = false {
        didSet {
            recordButton.backgroundColor = isRecording ? Styles.recordRed : UIColor(white: 0.98, alpha: 1)
            recordButton.setTitleColor(isRecording ? UIColor.white : Styles.darkGray, for: .normal)
            recordButton.setTitle(isRecording ? "Finish" : "Record", for: .normal)
        }
    }
    @IBAction func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    var recordingSession: RecordingSession?
    
    func startRecording() {
        recordingSession = RecordingSession()
        recordButton.isUserInteractionEnabled = false
        recordButton.setTitle("Starting…", for: .normal)
        recordingSession!.start { (success: Bool) in
            self.recordButton.isUserInteractionEnabled = true
            self.isRecording = success
        }
    }
    
    func stopRecording() {
        recordingSession?.stop()
        isRecording = false
        if let rec = recordingSession {
            playbackSession = PlaybackSession(recordingSession: rec)
        }
        recordingSession = nil
    }
    
    // MARK: Post record
    var playbackSession: PlaybackSession? {
        didSet(old) {
            old?.stop()
            
            recordButton.isHidden = playbackSession != nil
            postRecordButtons.isHidden = playbackSession == nil
            if let sess = playbackSession {
                sess.frameCallback = { [weak self] (frame) in
                    self?.updateBlendShapes(frame.blendShapes)
                }
                sess.start()
            }
        }
    }
    
    @IBAction func placeInAR() {
        if let playbackSess = playbackSession {
            let arVC = storyboard!.instantiateViewController(withIdentifier: "ARViewController") as! ARViewController
            arVC.character = currentCharacter
            arVC.playbackSession = PlaybackSession(playbackSession: playbackSess)
            present(arVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func startOver() {
        playbackSession = nil
    }
}
