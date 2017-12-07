//
//  Extensions.swift
//  ARFace
//
//  Created by Nate Parrott on 11/28/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import SceneKit
import ARKit

extension SCNBoundingVolume {
    var scaleToNormalize: Float {
        get {
            let dx = boundingBox.max.x - boundingBox.min.x
            let dy = boundingBox.max.y - boundingBox.min.y
            let dz = boundingBox.max.z - boundingBox.min.z
            return min(1.0 / dx, 1.0 / dy, 1.0 / dz)
        }
    }
}

extension SCNMorpher {
    func applyBlendShapes(_ shapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        let blendLocationsToMorphTargets: [ARFaceAnchor.BlendShapeLocation: String] = [
            .jawOpen: "jawOpen",
            .eyeBlinkLeft: "eyeBlinkLeft",
            .eyeBlinkRight: "eyeBlinkRight",
            .eyeSquintLeft: "eyeSquintLeft",
            .eyeSquintRight: "eyeSquintRight",
            .jawForward: "jawForward",
            .jawLeft: "jawLeft",
            .jawRight: "jawRight"
        ]
        for (blendLoc, morphKey) in blendLocationsToMorphTargets {
            setWeight(shapes[blendLoc] as! CGFloat, forTargetNamed: morphKey)
        }
        setWeight(min(1, (shapes[.jawOpen] as! CGFloat) * 1.5), forTargetNamed: "jawOpen")
    }
}

extension ARSCNView {
    func configureEnvLighting() {
        automaticallyUpdatesLighting = false
        let environmentMap = UIImage(named: "env.exr")!
        scene.lightingEnvironment.contents = environmentMap
        scene.lightingEnvironment.intensity = 10
    }
    func updateEnvLighting() {
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = scene.lightingEnvironment
        if let lightEstimate = session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }
}
