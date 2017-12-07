import UIKit
import SceneKit
import ARKit
import ReplayKit

class ARViewController : UIViewController, ARSCNViewDelegate, RPPreviewViewControllerDelegate {
    // MARK: External API
    
    var character: Character? {
        didSet {
            for child in objectNode.childNodes { child.removeFromParentNode() }
            self.morpher = nil
            if let (node, morpher) = character?.create(mode: .ar) {
                objectNode.addChildNode(node)
                self.morpher = morpher
            }
        }
    }
    
    var playbackSession: PlaybackSession? {
        didSet {
            playbackSession?.frameCallback = {
                [weak self] (frame) in
                self?.morpher?.applyBlendShapes(frame.blendShapes)
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func done() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var actionsContainer: UIView!
    
    // MARK: Recording
    
    @IBAction func record() {
        recordingMode = true
        playbackSession!.stop()
        RPScreenRecorder.shared().startRecording { (err) in
            DispatchQueue.main.async {
                self.playbackSession!.onDone = {
                    RPScreenRecorder.shared().stopRecording(handler: { (previewVCOpt, _) in
                        DispatchQueue.main.async {
                            if let preview = previewVCOpt {
                                preview.previewControllerDelegate = self
                                self.present(preview, animated: true, completion: nil)
                            }
                        }
                    })
                    self.playbackSession!.onDone = nil
                    self.doneRecording()
                }
                self.playbackSession!.start()
                if err != nil {
                    self.doneRecording()
                }
            }
        }
    }
    
    func doneRecording() {
        recordingMode = false
    }
    
    var recordingMode = false {
        didSet {
            actionsContainer.isHidden = recordingMode
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        previewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Internal
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    let objectNode = SCNNode()
    var morpher: SCNMorpher?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        guard let camera = sceneView.pointOfView?.camera else { return }
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        sceneView.configureEnvLighting()
        
        playbackSession?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        playbackSession?.stop()
    }
    
    var cameraYRotation: Float {
        let forward = sceneView.pointOfView!.convertPosition(SCNVector3(0, 0, -1), to: sceneView.scene.rootNode)
        let cameraOrigin = sceneView.pointOfView!.convertPosition(SCNVector3(0, 0, 0), to: sceneView.scene.rootNode)
        let angle = atan2(forward.z - cameraOrigin.z, forward.x - cameraOrigin.x)
        return angle
    }
    
    @IBAction func tapped(sender: UITapGestureRecognizer) {
        if let (position: position, planeAnchor: _, isOnPlane: _) = sceneView.worldPosition(fromScreenPosition: sender.location(in: sceneView), objectPosition:  nil) {
            objectNode.position = SCNVector3(position.x, position.y, position.z)
            objectNode.rotation = SCNVector4(0, 1, 0, -Float.pi / 2 - cameraYRotation)
            if objectNode.parent == nil {
                sceneView.scene.rootNode.addChildNode(objectNode)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        sceneView.updateEnvLighting()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let plane = anchor as? ARPlaneAnchor {
            objectNode.adjustOntoPlaneAnchor(plane, using: node)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let plane = anchor as? ARPlaneAnchor {
            objectNode.adjustOntoPlaneAnchor(plane, using: node)
        }
    }
}
