import SwiftUI

import SwiftUI
import ARKit
import RealityKit
import CoreML
import Vision
import Combine
import Accelerate




class RoiWrapper {
    
    var bb: CGRect?
    var savedFrame: ARFrame?
    
    
}

class CustomSessionDelegate: NSObject, ARSessionDelegate {
    
    let visionQueue = DispatchQueue(label: "visqueue", qos: .background)
    let taskqueue = DispatchQueue(label: "taskqueue", qos: .background)
    let trackReqHandle = VNSequenceRequestHandler()
    
    var arview: ARView?
    var reqNo = 0
    var rw: RoiWrapper?
    var readyToTrack = false
    
    func setupView(_ view: ARView, _ rw: RoiWrapper) {
        view.session.delegate = self
        let config = ARWorldTrackingConfiguration()
        //config.frameSemantics = .sceneDepth
        config.sceneReconstruction = .mesh
        arview = view
        arview?.session.run(config)
        self.rw = rw
        NotificationCenter.default.addObserver(self, selector: #selector(self.trackPressed), name: Notification.Name("TrackPressed"), object: nil)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // stub
        if let bb = self.rw?.bb {
            
            let centerPoint = CGPoint(x: bb.midX, y: bb.midY)//CGPoint(x: bb.minX + (bb.width / 2),
            //y: bb.minY + (bb.height / 2))
            
            let ds = self.arview!.hitTest(centerPoint, types: .featurePoint)
            
            if let dist = ds.first?.distance {
                print("estimated dist \(dist * 3.28) feet")
            }
        }
    }
    
    
    
    func drawRect(_ rect: CGRect) {
        guard let _ = arview else {
            return
        }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let path: UIBezierPath = UIBezierPath(rect: rect)
        
        let rectShape: CAShapeLayer = CAShapeLayer()
        rectShape.path = path.cgPath
        rectShape.position = center
        rectShape.bounds = rect
        
        rectShape.strokeColor = UIColor.systemBlue.cgColor
        rectShape.fillColor = UIColor.clear.cgColor
        rectShape.lineWidth = 2.5
        if let sl = arview!.layer.sublayers {
            if !(sl.isEmpty) && !(sl.count == 1){
                let _ = arview!.layer.sublayers?.popLast()
            }
        }
        arview!.layer.addSublayer(rectShape)
    }
    
    
    func convertScreenRectToVisionCoordinates(screenRect: CGRect, viewPort: CGRect) -> CGRect? {
        
        
        // Convert the screen rectangle to normalized coordinates
        let normalizedScreenRect = VNNormalizedRectForImageRect(screenRect, Int(viewPort.width), Int(viewPort.height))
        /*CGRect(
         x: screenRect.origin.x / viewPort.width,
         y: screenRect.origin.y / viewPort.height,
         width: screenRect.width / viewPort.width,
         height: screenRect.height / viewPort.height
         )
         */
        // Calculate Vision coordinates based on normalized screen rectangle
        let visionRect = CGRect(
            x: normalizedScreenRect.origin.x,
            y: 1.0 - normalizedScreenRect.maxY,
            width: normalizedScreenRect.width,
            height: normalizedScreenRect.height
        )
        
        return visionRect
    }
    
    
    func convertVisionCoordinatesToScreenRect(visionRect: CGRect, viewPort: CGRect) -> CGRect? {
        // Convert Vision coordinates to normalized screen coordinates
        let normalizedScreenRect = CGRect(
            x: visionRect.origin.x,
            y: 1.0 - visionRect.maxY,
            width: visionRect.width,
            height: visionRect.height
        )
        
        // Convert normalized screen coordinates to screen space
        let screenRect = CGRect(
            x: normalizedScreenRect.origin.x * viewPort.width,
            y: normalizedScreenRect.origin.y * viewPort.height,
            width: normalizedScreenRect.width * viewPort.width,
            height: normalizedScreenRect.height * viewPort.height
        )
        
        return screenRect
    }
    
    @objc func trackPressed(_ notif: Notification) {
        /*
         let rect = obj as! CGRect
         if case rect = .zero {
         print("no rect")
         return 
         }
         self.rw?.bb = rect
         print("rect received")*/
        
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    let delegate = CustomSessionDelegate()
    var roiW: RoiWrapper?
    func makeUIView(context: Context) -> ARView {
        
        
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        
        delegate.setupView(arView, self.roiW!)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        //
    }
    
    
}

struct TransformationHelper {
    
    static func visionTransform(frame: ARFrame, viewport: CGRect) -> CGAffineTransform {
        let orientation = UIApplication.shared.statusBarOrientation
        let transform = frame.displayTransform(for: orientation,
                                               viewportSize: viewport.size)
        let scale = CGAffineTransform(scaleX: viewport.width,
                                      y: viewport.height)
        
        var t = CGAffineTransform()
        if orientation.isPortrait {
            t = CGAffineTransform(scaleX: -1, y: 1)
            t = t.translatedBy(x: -viewport.width, y: 0)
        } else if orientation.isLandscape {
            t = CGAffineTransform(scaleX: 1, y: -1)
            t = t.translatedBy(x: 0, y: -viewport.height)
        }
        
        return transform.concatenating(scale).concatenating(t)
    }
    
    
}

struct DroneDistView: View {
    @State var pos = CGRect()
    @State var isRdy = false
    @State var touchedX = 0.0
    @State var touchedY = 0.0
    @State var endedX = 0.0
    @State var endedY = 0.0
    @State var readyToTrack = false
    @State var pth = CGRect()
    
    var roiw = RoiWrapper()
    let redBottom = Color(uiColor: UIColor(red: 237/255, green: 33/255, blue: 58/255, alpha: 1))
    var arv: ARViewContainer
    
    init() {
        self.arv = ARViewContainer()
        self.arv.roiW = self.roiw
    }
    
    
    var drag: some Gesture {
        DragGesture()
            .onChanged({ c in
                touchedX = c.startLocation.x
                touchedY = c.startLocation.y
                endedX = c.location.x - c.startLocation.x
                endedY = c.location.y - c.startLocation.y
                readyToTrack = false
                pth = CGRect(x: Int(touchedX), y: Int(touchedY), width: Int(endedX), height: Int(endedY))
                self.arv.delegate.drawRect(pth)
            })
            .onEnded({ e in
                self.arv.delegate.readyToTrack = true
                self.roiw.bb = pth
            })
        
    }
    
    var body: some View {
        
        ZStack {
            self.arv
                .edgesIgnoringSafeArea(.all)
                .gesture(drag)
            
            VStack {
                Text("Draw a box around the drone.\nTap \"Capture\" when ready.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10), style: .continuous), style: FillStyle())
                    .padding(35)
                Spacer()
                
                Button {
                    isRdy = true
                    NotificationCenter.default.post(name: Notification.Name("TrackPressed"), object: self.pth)
                } label: {
                    Text("Capture")
                        .padding()
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).foregroundColor(redBottom))
                        .padding()
                }
            }
            
        }
        
        
    }
}
