import SwiftUI
import SceneKit

class DroneConfigWrapper {
    // default
    static var ipAddr: String = ""
}

class TimeAsync {
    static func getTime() async -> String {
        return Date.now.formatted(date: .omitted, time: .shortened)
    }
}

struct ContentView: View {
    
    @State var time = Date.now.formatted(date: .omitted, time: .shortened)
    let redBottom = Color(uiColor: UIColor(red: 237/255, green: 33/255, blue: 58/255, alpha: 1))
    
    @State var isConfiguring = false
    @State var isViewing = false
    @State var droneIPConf = ""
    @State var showIPModal = false
    
    @Environment(\.horizontalSizeClass) var vertSzClass
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                GeometryReader {p in 
                    DroneModelView()
                        .position(x: p.size.width/2, y: p.size.height/2)
                        .frame(width: p.size.width, height: p.size.height, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }
                .ignoresSafeArea(.all)
                VStack {
                    Text(time.hasSuffix("AM") ? "Good Morning" : "Good Afternoon")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(redBottom)
                    //.padding(.top, 45)
                        .padding(.bottom, 14)
                    
                    Text("Fly, navigate, control.")
                        .font(.system(.headline, design: .default, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                    VStack {
                        
                        Text("Ensure you have the following set up:")
                            .font(.system(.body, design: .default, weight: .regular))
                            .multilineTextAlignment(.center)
                        
                        if vertSzClass == .compact {
                            IconNotifView()
                            HStack {
                                Image(systemName: "network")
                                    .symbolRenderingMode(.multicolor)
                                Text("Drone IP: \(droneIPConf.isEmpty ? "None" : droneIPConf)")
                                    .font(.system(.body, design: .default, weight: .regular))
                                
                            }
                            
                        } else {
                            HStack {
                                IconNotifView()
                                HStack {
                                    Image(systemName: "network")
                                        .symbolRenderingMode(.multicolor)
                                    Text("Drone IP: \(droneIPConf.isEmpty ? "None" : droneIPConf)")
                                    
                                }
                                .padding()
                            }
                        }
                        
                        
                        
                        
                    }
                    
                    
                    
                    Button {
                        if droneIPConf.isEmpty {
                            showIPModal = true
                        } 
                        
                    } label: {
                        if droneIPConf.isEmpty {
                            Text("Find and Pair Drone")
                                .foregroundColor(.white)
                                .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                        .foregroundColor(redBottom)
                                        .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                )
                        } else {
                            NavigationLink(destination: ScanPrompt()) {
                                Text("Find and Pair Drone")
                                    .foregroundColor(.white)
                                    .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                            .foregroundColor(redBottom)
                                            .frame(width: UIScreen.main.bounds.width * (350 / UIScreen.main.bounds.width))
                                    )
                            }
                        }
                    }
                    .alert("IP Missing", isPresented: $showIPModal) {
                        
                    } message: {
                        Text("Enter your drone's IP address in the configuration setting; it cannot be empty.")
                    }
                    .padding()
                    
                    
                    
                    
                    
                }
                .ignoresSafeArea(/*@START_MENU_TOKEN@*/.keyboard/*@END_MENU_TOKEN@*/, edges: /*@START_MENU_TOKEN@*/.bottom/*@END_MENU_TOKEN@*/)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        
                        Button {
                            isViewing = true
                        } label: {
                            Image(systemName: "ant.circle")
                                .foregroundColor(redBottom)
                        }.sheet(isPresented: $isViewing) {
                            DroneCamView()
                        }
                        
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isConfiguring = true
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(redBottom)
                        }.alert("Drone IP Config", isPresented: $isConfiguring) {
                            TextField("192.168.0.1 (Default)", text: $droneIPConf)
                                .keyboardType(.numberPad)
                                
                            
                            
                            Button {
                                isConfiguring = false
                                DroneIPWrapper.ip = droneIPConf
                            } label: {
                                Text("Done")
                            }
                            
                            
                        } message: {
                            Text("Enter the drone's IP address for camera streaming.")
                        }
                        
                    }
                    
                    
                }
                
            }
            
        }.tint(.red)
    
    }
    
}


struct IconNotifView: View {
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "wifi")
                    .symbolRenderingMode(.multicolor)
                Text("Wi-Fi")
                    .font(.system(.body, design: .default, weight: .regular))
                
            }
            .padding()
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .symbolRenderingMode(.multicolor)
                Text("Bluetooth")
                    .font(.system(.body, design: .default, weight: .regular))
                
            }
            .padding()
        }
    }
}
