import SwiftUI
import ARKit
import RoomPlan

class BasicARDelegate : NSObject, ARSCNViewDelegate {
    
    var arView: ARSCNView?
    
    func initAR(_ arView: ARSCNView) {
        self.arView = arView
        let newConfig = ARWorldTrackingConfiguration()
        newConfig.planeDetection = .horizontal
        self.arView!.session.run(newConfig)
    }
    
}


struct BasicARView: UIViewRepresentable {
    
    let arDelegate = BasicARDelegate()

    func makeUIView(context: Context) -> some UIView {
        let arView = ARSCNView(frame: .zero)
        arDelegate.initAR(arView)
        return arView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}

struct RPConstants {
    static let doneNotif = Notification.Name("RPDone") 
}

// -=-=-=-=-------=-
struct RoomData {
    var results: CapturedRoom?
    var dat: CapturedRoomData?
}
class RPDelegate: NSCoding, RoomCaptureViewDelegate {
    
    var rmCaptureView: RoomCaptureView?
    var rmSessionConf: RoomCaptureSession.Configuration?
    static var persistentRoomRes: RoomData?
    init() {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initAR(view: RoomCaptureView) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.doneScanning), name: RPConstants.doneNotif, object: nil)
        rmCaptureView = view
        rmSessionConf = RoomCaptureSession.Configuration()
        rmCaptureView?.delegate = self
        rmCaptureView?.captureSession.run(configuration: rmSessionConf!)
    }
    
    
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        //
        RPDelegate.persistentRoomRes?.results = processedResult
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        RPDelegate.persistentRoomRes?.dat = roomDataForProcessing
        return true
    }
    
    func encode(with coder: NSCoder) {
        //
    }
    
    @objc func doneScanning() {
        self.rmCaptureView?.captureSession.stop()
    }
    
}


struct RoomPlanView: UIViewRepresentable {
    
    let arDelegate = RPDelegate()
    
    
    func makeUIView(context: Context) -> some UIView {
        let rmCaptureView = RoomCaptureView(frame: .zero)
        arDelegate.initAR(view: rmCaptureView)
        return rmCaptureView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}


// -=-=-=-=-=-



struct ScanPrompt: View {
    
    @State var scanReady = false
    @State var doneClicked = false
    let redBottom = Color(uiColor: UIColor(red: 237/255, green: 33/255, blue: 58/255, alpha: 1))
    @State var movingToNext = false
    
    var body : some View {
        if !movingToNext {
            if scanReady {
                ZStack {
                    RoomPlanView()
                        .ignoresSafeArea(.all)
                        .toolbar {
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                if !doneClicked {
                                    Button {
                                        NotificationCenter.default.post(name: RPConstants.doneNotif, object: nil)
                                        doneClicked = true
                                    } label: {
                                        Text("Done")
                                    }
                                }
                            }
                        }
                    
                    if doneClicked {
                        VStack {
                            Spacer()
                            Button {
                                movingToNext = true
                            } label: {
                                Text("Continue")
                                    .foregroundColor(.white)
                                    .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                            .foregroundColor(redBottom)
                                            .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                    )
                                
                            }
                            .padding(25)
                        }
                    }
                }
            } else {
                ZStack {
                    BasicARView()
                        .ignoresSafeArea(.all)
                    VStack {
                        Spacer()
                        Image("ScanPromptLogo")
                            .frame(width: 70, height: 70, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            .scaleEffect(CGSize(width: 0.25, height: 0.25), anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            .padding()
                        Text("Next, you will scan your environment to build a map. When you're ready, tap the \"Scan\" button.")
                            .padding()
                            .multilineTextAlignment(.center)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scanReady = true
                            }
                        } label: {
                            Text("Scan")
                                .foregroundColor(.white)
                                .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                        .foregroundColor(redBottom)
                                        .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                )
                            
                        }
                        .padding(25)
                    }
                    .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .background(.thinMaterial)
                    .ignoresSafeArea(.all)
                }
            }
        } else {
            DroneDistView()
                .ignoresSafeArea(.all)
        }
    }
    
}
