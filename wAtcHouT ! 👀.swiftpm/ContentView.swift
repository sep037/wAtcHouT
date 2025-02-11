import SwiftUI
import ARKit
import CoreMotion

struct ARFaceDistanceView: UIViewControllerRepresentable {
    @Binding var faceDistance: CGFloat // Connect with ContentView by detecting the distance between the face and iPad
    
    func makeUIViewController(context: Context) -> ARSessionViewController {
        return ARSessionViewController(faceDistance: $faceDistance)
    }
    
    func updateUIViewController(_ uiViewController: ARSessionViewController, context: Context) {}
}

// UIViewController that leverages ARKit's face tracking capabilities to measure the distance between the user's face and the device
class ARSessionViewController: UIViewController, ARSessionDelegate {
    var session = ARSession()
    let motionManager = CMMotionManager() // CoreMotion objects for detecting the movement of iPad
    @Binding var faceDistance: CGFloat // Pass face distance values to ContentView
    
    init(faceDistance: Binding<CGFloat>) {
        _faceDistance = faceDistance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() { // Start facial recognition by running ARFaceTracking Configuration
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        let configuration = ARFaceTrackingConfiguration()
        session.delegate = self
        session.run(configuration)
        
        startDeviceMotionUpdates() // Start detecting iPad movement
    }
    
    // Detects when the iPad shakes or moves
    func startDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.5
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                guard let motion = motion else { return }
                
                let acceleration = motion.userAcceleration
                let threshold: Double = 0.2
                
                // Run resetTracking () if the acceleration (acceleration.x/y/z) value is greater than 0.2
                if abs(acceleration.x) > threshold || abs(acceleration.y) > threshold || abs(acceleration.z) > threshold {
                    self.resetTracking()
                }
            }
        }
    }
    
    func resetTracking() {
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { 
            DispatchQueue.main.async {
                self.faceDistance = 50.0 // Reset to default
            }
            return
        }
        
        
        let transform = faceAnchor.transform
        // In ARKit's coordinate system, the z value is positive toward the camera, negative in the opposite direction, so multiply by -100 to convert
        let distanceValue = CGFloat(transform.columns.3.z * -100)
        DispatchQueue.main.async {
            self.faceDistance = distanceValue
        }
    }
}

struct ContentView: View {
    @State private var faceDistance: CGFloat = 50.0 // the distance of one's face
    @State private var isRippleAnimating = false // Wavelength animation status
    @State private var isMonitoringStarted = false // distance measurement
    
    // 거리 값에 따른 경고 색 설정
    func getWarningColor(for faceDistance: CGFloat) -> Color {
        let minDistance: CGFloat = 20
        let maxDistance: CGFloat = 60
        let normalized = max(0, min(1, (faceDistance - minDistance) / (maxDistance - minDistance)))
        
        return Color(
            red: min(1, max(0, 2.0 - 2.0 * normalized)),  
            green: min(1, max(0, 2.0 * normalized)),      
            blue: 0
        )
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .edgesIgnoringSafeArea(.all)
            
            ARFaceDistanceView(faceDistance: $faceDistance)
                .edgesIgnoringSafeArea(.all)
            
            if isMonitoringStarted {
                Circle()
                    .stroke(getWarningColor(for: faceDistance).opacity(0.35), lineWidth: 5)
                    .frame(width: isRippleAnimating ? 400 : 300, height: isRippleAnimating ? 400 : 300)
                    .animation(.easeOut(duration: max(0.5, min(2.0, faceDistance / 30))).repeatForever(autoreverses: false), value: isRippleAnimating)
                
                Circle()
                    .stroke(getWarningColor(for: faceDistance).opacity(0.2), lineWidth: 3)
                    .frame(width: isRippleAnimating ? 500 : 350, height: isRippleAnimating ? 500 : 350)
                    .animation(.easeOut(duration: max(0.5, min(2.0, faceDistance / 30))).repeatForever(autoreverses: false), value: isRippleAnimating)
                
                Circle()
                    .fill(getWarningColor(for: faceDistance))
                    .frame(width: 300, height: 300)
                
                VStack {
                    HStack {
                        Button(action: {
                            isMonitoringStarted = false
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 50)
                        
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                VStack {
                    Spacer()
                    
                    Text("wAtcHouT !")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    Text("It keeps your face from getting close to your iPad!")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    Button(action: {
                        isMonitoringStarted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isRippleAnimating = true
                        }
                    }) {
                        Text("Start")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(width: 220, height: 70)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(35)
                    }
                    .padding(.bottom, 80)
                    
                    Image(systemName: "hand.raised.fill")
                        .resizable()
                        .frame(width: 100, height: 120)
                        .foregroundColor(.green)
                        .offset(x:0, y:-750)
                }
            }
        }
    }
}

