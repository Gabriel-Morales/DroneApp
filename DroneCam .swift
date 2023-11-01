import SwiftUI
import Network
import Combine
import SwiftUI
import Network
import Combine

class DroneIPWrapper {
    public static var ip = ""
}


class PublishedDroneMonitor: ObservableObject {
    let imageStream = PassthroughSubject<CIImage, Never>()
    // bound socket for the drone proxy listener
    private let droneRecvPort = "6789"
    private var droneAddy: String
    private let droneKeepAlive: NWConnection
    
    private let eventQueue = DispatchQueue(label: "Frame Queue", qos: .background)
    
    private var imageDataBuffer: Data
    
    init() {
        self.droneAddy = DroneIPWrapper.ip
        // TODO: add a parameter for the drone ip address
        let endpointH = NWEndpoint.Host(droneAddy)
        let endpointP = NWEndpoint.Port("6789")!
        let host = NWEndpoint.hostPort(host: endpointH, port: endpointP)
        droneKeepAlive = NWConnection(to: host, using: .udp)
        imageDataBuffer = Data()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func stopServices() -> Void {
        self.droneKeepAlive.cancel()
    }
    
    func startServices() -> Void {
        print("helll")
        print(droneAddy)
        self.droneKeepAlive.stateUpdateHandler = { (newState) in
            
            switch newState {
            case .ready:
                print("Ready connection")
                self.receiveUDPs()
            case .setup:
                print("Setting up connection")
            case .cancelled:
                print("Cancelled connection")
            case .preparing:
                print("Preparing connection")
            default:
                print("Defaulted")
            }
            
        }
        
        droneKeepAlive.start(queue: self.eventQueue)
        
    }
    
    func sendKeepalive() -> Void {
        let KAMsg = "KA"
        self.droneKeepAlive.send(content: KAMsg.data(using: .utf8, allowLossyConversion: true), contentContext: .defaultMessage, isComplete: true, completion: .idempotent)
    }
    
    func receiveUDPs() -> Void {
        
        sendKeepalive()
        
        self.droneKeepAlive.receive(minimumIncompleteLength: 128, maximumLength: 40000, completion: {
            dat, cxt, complete, err in
            
            if let data = dat {
                
                self.imageDataBuffer.append(data[54..<data.count])

                
                if (data[data.count-2] == 255) && (data[data.count-1] == 217) {
                    if self.imageDataBuffer[0] == 255 && self.imageDataBuffer[1] == 216 {
                        print("incomplete image")
                        self.sendKeepalive()
                        self.receiveUDPs()
                    }
                    
                    print("reached end image")
                    //make the image here
                    
                    let cii = CIImage(data: self.imageDataBuffer)
                    
                    guard let cii = cii else {
                        self.sendKeepalive()
                        self.imageDataBuffer = Data()
                        return
                    }
                    
                    self.imageStream.send(cii)
                    
                    self.imageDataBuffer = Data()
                    self.sendKeepalive()
                    
                    
                }
                
                self.receiveUDPs()
                
                //self.startServices()
            }
            
        })
        
    }
    
    
}

struct IntermediateDroneView: View {
    @State var pdm = PublishedDroneMonitor()
    @State var loadedImg = UIImage()
    @State var dot = 0
    var ctx = CIContext()
    
    
    init() {
        pdm.startServices()
    }
    
    
    var body: some View {
        Image(uiImage: loadedImg)
            .resizable()
            .frame(width: 680, height: 420, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .onReceive(pdm.imageStream, perform: { im in
                let cgimg = ctx.createCGImage(im, from: im.extent)
                loadedImg = UIImage(cgImage: cgimg!)
            })
        
    }
}






struct DroneCamView: View {
    
    
    var body: some View {
        VStack {
            IntermediateDroneView()
        }
    }
}




