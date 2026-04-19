import CoreMotion
import Foundation

// MARK: - Protocol

protocol MotionControlService: AnyObject {
    var pitch: Double { get }  // forward/back tilt (-1..1)
    var roll: Double { get }   // left/right tilt (-1..1)
    var isAvailable: Bool { get }
    var onShake: (() -> Void)? { get set }
    func start()
    func stop()
}

// MARK: - Implementation

final class CMMotionController: MotionControlService {
    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 30.0

    private(set) var pitch: Double = 0
    private(set) var roll: Double = 0
    var onShake: (() -> Void)?

    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    private var lastAcceleration: CMAcceleration?
    private let shakeThreshold: Double = 2.5

    func start() {
        guard isAvailable else { return }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.pitch = Self.clamp(motion.attitude.pitch / (.pi / 4))
            self.roll = Self.clamp(motion.attitude.roll / (.pi / 4))
            self.detectShake(motion.userAcceleration)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        pitch = 0
        roll = 0
    }

    private func detectShake(_ acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        if magnitude > shakeThreshold {
            onShake?()
        }
    }

    private static func clamp(_ value: Double) -> Double {
        max(-1, min(1, value))
    }
}
