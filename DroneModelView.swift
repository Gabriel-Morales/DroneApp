
import SwiftUI
import SceneKit

struct DroneModelView: View {
    var scene: SCNScene? {
        SCNScene(named: "Drone.scn")
    }
    
    var camera: SCNNode? {
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(x: 0, y: 0, z: 60)
        
        return camera
    }
    
    var body: some View {
        SceneView(scene: scene, pointOfView: camera, options: [.allowsCameraControl, .autoenablesDefaultLighting, .temporalAntialiasingEnabled], preferredFramesPerSecond: 30, antialiasingMode: .multisampling4X, delegate: nil, technique: nil)
    }
}
