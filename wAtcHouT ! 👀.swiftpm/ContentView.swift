import SwiftUI
import ARKit
import CoreMotion

struct ARFaceDistanceView: UIViewControllerRepresentable {
    @Binding var faceDistance: CGFloat // 얼굴과 iPad의 거리를 감지하여 ContentView와 연결
    
    func makeUIViewController(context: Context) -> ARSessionViewController {
        return ARSessionViewController(faceDistance: $faceDistance)
    }
    
    func updateUIViewController(_ uiViewController: ARSessionViewController, context: Context) {}
}

// ARKit의 얼굴 추적 기능을 활용하여 사용자의 얼굴과 기기 사이의 거리를 측정하는 UIViewController
class ARSessionViewController: UIViewController, ARSessionDelegate {
    var session = ARSession() // ARkit 세션 객체
    let motionManager = CMMotionManager() // iPad의 움직임을 감지하기 위한 CoreMotion 객체
    @Binding var faceDistance: CGFloat // 얼굴 거리 값을 ContentView에 전달
    
    init(faceDistance: Binding<CGFloat>) {
        _faceDistance = faceDistance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() { // ARFaceTrackingConfiguration을 실행하여 얼굴 인식 시작
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        let configuration = ARFaceTrackingConfiguration()
        session.delegate = self
        session.run(configuration)
        
        startDeviceMotionUpdates() // iPad 움직임 감지 시작
    }
    
    //iPad가 흔들리거나 움직였을 때 감지
    func startDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.5
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                guard let motion = motion else { return }
                
                let acceleration = motion.userAcceleration
                let threshold: Double = 0.2 // 움직임 감지 임계값
                
                // 가속도(acceleration.x/y/z) 값이 0.2보다 크면 resetTracking() 실행
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
    
    // ARFaceAnchor의 transform.columns.3.z 값을 활용하여 얼굴과 iPad 사이 거리(단위: cm) 계산
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { 
            DispatchQueue.main.async {
                self.faceDistance = 50.0 // 얼굴을 놓치면 기본값으로 리셋
            }
            return
        }
        
        
        let transform = faceAnchor.transform
        // ARKit의 좌표 시스템에서 z 값은 카메라를 향해 양수, 반대 방향으로 음수이므로 -100을 곱해 변환
        let distanceValue = CGFloat(transform.columns.3.z * -100)
        DispatchQueue.main.async {
            self.faceDistance = distanceValue
        }
    }
}

struct ContentView: View {
    @State private var faceDistance: CGFloat = 50.0 // 얼굴 거리
    @State private var isRippleAnimating = false // 파장 애니메이션 상태
    @State private var isMonitoringStarted = false // 거리 측정 기능이 활성화 되었는지 여부
    
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
                // 파장 애니메이션
                Circle()
                    .stroke(getWarningColor(for: faceDistance).opacity(0.35), lineWidth: 5)
                    .frame(width: isRippleAnimating ? 400 : 300, height: isRippleAnimating ? 400 : 300)
                    .animation(.easeOut(duration: max(0.5, min(2.0, faceDistance / 30))).repeatForever(autoreverses: false), value: isRippleAnimating)
                
                Circle()
                    .stroke(getWarningColor(for: faceDistance).opacity(0.2), lineWidth: 3)
                    .frame(width: isRippleAnimating ? 500 : 350, height: isRippleAnimating ? 500 : 350)
                    .animation(.easeOut(duration: max(0.5, min(2.0, faceDistance / 30))).repeatForever(autoreverses: false), value: isRippleAnimating)
                
                // 중앙 원 (경고 색상)
                Circle()
                    .fill(getWarningColor(for: faceDistance))
                    .frame(width: 300, height: 300)
                
                // 뒤로 가기 버튼
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
                // 시작 화면
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
                        .offset(x:0, y:-800)
                }
            }
        }
    }
}

