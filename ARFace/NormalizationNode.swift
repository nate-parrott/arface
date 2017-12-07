//
//  NormalizationNode.swift
//  ARFace
//
//  Created by Nate Parrott on 12/2/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import Foundation
import SceneKit

class NormalizationNode: SCNNode {
    var container = SCNNode()
    var child: SCNNode? {
        didSet(old) {
            old?.removeFromParentNode()
            if container.parent == nil {
                addChildNode(container)
            }
            if let c = child {
                container.addChildNode(c)
                container.position = SCNVector3(0, 0, 0)
                container.scale = SCNVector3(1, 1, 1)
                
                let scale = c.scaleToNormalize
                container.scale = SCNVector3(scale, scale, scale)
                
                let bbox = container.boundingBox
                let dx: Float = 0 // (bbox.max.x - bbox.min.x) / 2
                let dy = (bbox.max.y - bbox.min.y) / 2
                let dz = (bbox.max.z - bbox.min.z) / 2
                container.position = SCNVector3(-dx*scale, -dy*scale, -dz*scale)
            }
        }
    }
}
