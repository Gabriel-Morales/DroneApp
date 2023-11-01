import SwiftUI
struct FloatySubView: View {
    @State var location = CGSize(width: 0, height: 0)
    @State var totalZoom = 1.0
    
    @State var currentZoom = 0.0
    @State var fw = 0.0
    @State var fh = 0.0
    @State var offset = CGSize.zero
    
    @Environment(\.horizontalSizeClass) var szClass 
    
    
    @State var pdm = PublishedDroneMonitor()
    @State var loadedImg = UIImage()
    var ctx = CIContext()
    
    
    init() {
        pdm.startServices()
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { 
                c in 
                location.width += c.translation.width
                location.height += c.translation.height
                
            }
    }
    
    var pinch: some Gesture {
        MagnificationGesture()
            .onChanged { c in
                currentZoom = c.magnitude - 1
            }
            .onEnded { e in
                totalZoom += currentZoom
                currentZoom = 0.0
            }
    }
    
    var body: some View {
        
        GeometryReader { geo in 
            Image(uiImage: loadedImg)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .continuous), style: FillStyle())
                .shadow(color: /*@START_MENU_TOKEN@*/.black/*@END_MENU_TOKEN@*/.opacity(0.5), radius: 25, x: 0.0, y: 0.0)
                .padding()
                .gesture(drag)
                .position(
                    CGPoint(x:  location.width, y: location.height)
                )
                .gesture(pinch)
                .scaleEffect(currentZoom + totalZoom)
                .frame(width: fw, height: fh, alignment: .center)
                .onAppear(perform: {
                    
                    
                    if szClass != .compact {
                        location.height = (geo.size.height / 3 / 2) 
                        location.width = (geo.size.width / 3 / 2) 
                        fw = geo.size.width  / 3
                        fh = geo.size.height / 3
                        
                    } else {
                        location.width = geo.size.width / 2
                        location.height = (geo.size.height / 3 / 2)
                        fw = geo.size.width
                        fh = geo.size.height / 3 
                    }
                    
                })
                .onReceive(pdm.imageStream, perform: { im in
                    let cgimg = ctx.createCGImage(im, from: im.extent)
                    loadedImg = UIImage(cgImage: cgimg!)
                })
            
            
            
        }
        
    }
}

