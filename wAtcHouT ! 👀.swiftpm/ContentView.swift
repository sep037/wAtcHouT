import SwiftUI
import ARKit

struct ARFaceDistanceView: UIViewControllerRepresentable {
    @Binding var distance: CGFloat
    
    func makeUIViewController(context: Context) -> ARSessionViewController {
        return ARSessionViewController(distance: $distance)
    }
    
    func updateUIViewController(_ uiViewController: ARSessionViewController, context: Context) {}
}

class ARSessionViewController: UIViewController, ARSessionDelegate {
    var session = ARSession()
    @Binding var distance: CGFloat
    
    init(distance: Binding<CGFloat>) {
        _distance = distance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ARKit 배경색을 짙은 그레이로 설정
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        let configuration = ARFaceTrackingConfiguration()
        session.delegate = self
        session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        let transform = faceAnchor.transform
        let distanceValue = CGFloat(transform.columns.3.z * -100) // cm 단위 변환
        DispatchQueue.main.async {
            self.distance = distanceValue
        }
    }
}

struct ContentView: View {
    @State private var distance: CGFloat = 50.0
    @State private var rippleEffect = false // 애니메이션 상태
    @State private var isStarted = false   // 시작 화면 상태
    
    // 거리 기반 색상 변화 (채도 낮춤)
    func getColor(for distance: CGFloat) -> Color {
        let minDistance: CGFloat = 20
        let maxDistance: CGFloat = 60
        
        let normalized = max(0, min(1, (distance - minDistance) / (maxDistance - minDistance)))
        
        return Color(
            red: min(1, max(0, 2.0 - 2.0 * normalized)),  // 빨강 (가까울수록 강해짐)
            green: min(1, max(0, 2.0 * normalized)),      // 초록 (멀수록 강해짐)
            blue: 0
        )
    }
    
    var body: some View {
        ZStack {
            // 짙은 그레이 배경 유지
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .edgesIgnoringSafeArea(.all)
            
            // ARKit 화면을 항상 배경으로 유지
            ARFaceDistanceView(distance: $distance)
                .edgesIgnoringSafeArea(.all)
            
            if isStarted {
                // Ripple Effect (파장 애니메이션)
                Circle()
                    .stroke(getColor(for: distance).opacity(0.35), lineWidth: 5)
                    .frame(width: rippleEffect ? 400 : 300, height: rippleEffect ? 400 : 300)
                    .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: false), value: rippleEffect)
                
                Circle()
                    .stroke(getColor(for: distance).opacity(0.2), lineWidth: 3)
                    .frame(width: rippleEffect ? 500 : 350, height: rippleEffect ? 500 : 350)
                    .animation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: rippleEffect)
                
                // 중앙 메인 원 (색상 조정)
                Circle()
                    .fill(getColor(for: distance))
                    .frame(width: 300, height: 300)
                
                // 🔙 뒤로 가기 버튼
                VStack {
                    HStack {
                        Button(action: {
                            isStarted = false // 시작 화면으로 돌아가기
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
                // 시작 화면 UI 요소
                VStack {
                    Spacer()
                    
                    Text("wAtcHouT ! 👀")
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
                        isStarted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            rippleEffect = true
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
                    .padding(.bottom, 80) // 버튼을 위로 올림
                }
            }
        }
        .task {
            if isStarted {
                rippleEffect = true
            }
        }
    }
}

