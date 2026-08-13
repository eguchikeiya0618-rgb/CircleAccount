import CoreGraphics
import Foundation

struct SiriUSV2ReelConfiguration {
    let reelIndex: Int

    let accelerationDuration: TimeInterval
    let motorEngagementDuration: TimeInterval
    let cruiseVelocity: Double
    let stopDuration: TimeInterval
    let slipDurationIncrement: TimeInterval
    let minimumStopTravel: Double
    let inertialTravelFactor: Double
    let brakingDeceleration: Double

    let lockDuration: TimeInterval
    let lockAmplitude: Double
    let lockAngularFrequency: Double
    let lockDamping: Double

    let symbolAngle: Double
    let drumRadiusRatio: CGFloat
    let minimumDrumGeometryHeight: CGFloat
    let perspectiveDistance: CGFloat
    let visibleFaceCount: Int
    let guardHeightRatio: CGFloat

    init(reelIndex: Int) {
        let index = max(0, reelIndex)
        self.reelIndex = index
        accelerationDuration = 0.86 + Double(index) * 0.040
        motorEngagementDuration = 0.11 + Double(index) * 0.009
        cruiseVelocity = 17.4 + Double(index) * 0.92
        stopDuration = 0.72 + Double(index) * 0.040
        slipDurationIncrement = 0.042
        minimumStopTravel = 5.2
        inertialTravelFactor = 0.68
        brakingDeceleration = 29.0 + Double(index) * 1.35

        lockDuration = 0.52
        lockAmplitude = 0.132 + Double(index) * 0.011
        lockAngularFrequency = 36 + Double(index) * 1.65
        lockDamping = 10.8

        // The physical drum remains sized for the former 190pt viewport, but
        // the cabinet aperture only reveals about 3.3 symbol pitches.
        symbolAngle = .pi / 10.0
        drumRadiusRatio = 0.88
        minimumDrumGeometryHeight = 190
        perspectiveDistance = 680
        // Thirteen mounted faces keep a deep offscreen reserve around the
        // roughly 3.3 faces exposed by the physical aperture.
        visibleFaceCount = 13
        guardHeightRatio = 0.62
    }
}

struct SiriUSV2ReelInputs: Equatable {
    let finalSymbol: String
    let initialDisplaySymbol: String
    let symbolPool: [String]
    let isSpinning: Bool
    let isStopped: Bool
    let reelIndex: Int
}

struct SiriUSV2ReelStrip {
    private(set) var symbols: [String]

    init(symbolPool: [String], minimumCount: Int = 72, reelIndex: Int) {
        let supplied = symbolPool.filter { !$0.isEmpty }
        let source = supplied.isEmpty
            ? ["7", "🌈7", "BAR", "🔔", "🍇", "🍒"]
            : supplied

        var result: [String] = []
        var lap = 0

        while result.count < max(minimumCount, source.count * 8) {
            let rawShift = reelIndex * 3 + lap * 2
            let remainder = rawShift % source.count
            let shift = remainder >= 0 ? remainder : remainder + source.count
            for index in source.indices {
                result.append(source[(index + shift) % source.count])
            }
            lap += 1
        }

        symbols = result
    }

    var count: Int { symbols.count }

    func symbol(atAbsoluteIndex index: Int) -> String {
        guard !symbols.isEmpty else { return "🍒" }
        return symbols[positiveModulo(index, symbols.count)]
    }

    mutating func install(_ symbol: String, atAbsoluteIndex index: Int) {
        guard !symbol.isEmpty, !symbols.isEmpty else { return }
        symbols[positiveModulo(index, symbols.count)] = symbol
    }

    mutating func center(_ symbol: String, at phase: Double) {
        install(symbol, atAbsoluteIndex: Int(floor(phase)))
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

enum SiriUSV2ReelState: Equatable {
    case idle
    case accelerating
    case cruising
    case decelerating
    case locking
    case stopped
}

struct SiriUSV2ReelFaceSnapshot {
    let absoluteIndex: Int
    let symbol: String
    let localAngle: Double
}

struct SiriUSV2ReelRenderSnapshot {
    let state: SiriUSV2ReelState
    let absolutePhase: Double
    let angularVelocity: Double
    let normalizedVelocity: Double
    let impactIntensity: Double
    let faces: [SiriUSV2ReelFaceSnapshot]
}

struct SiriUSQuinticTrajectory {
    let duration: TimeInterval
    private let c0: Double
    private let c1: Double
    private let c2: Double
    private let c3: Double
    private let c4: Double
    private let c5: Double

    init(
        startPosition: Double,
        startVelocity: Double,
        startAcceleration: Double,
        endPosition: Double,
        duration: TimeInterval
    ) {
        let duration = max(duration, 0.001)
        self.duration = duration
        c0 = startPosition
        c1 = startVelocity
        c2 = startAcceleration / 2

        let t = duration
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let t5 = t4 * t
        let displacement = endPosition - startPosition

        // Boundary conditions: p(0), v(0), a(0), p(T), v(T)=0, a(T)=0.
        c3 = 10 * displacement / t3
            - 6 * startVelocity / t2
            - 1.5 * startAcceleration / t
        c4 = -15 * displacement / t4
            + 8 * startVelocity / t3
            + 1.5 * startAcceleration / t2
        c5 = 6 * displacement / t5
            - 3 * startVelocity / t4
            - 0.5 * startAcceleration / t3
    }

    func sample(at rawTime: TimeInterval) -> (position: Double, velocity: Double, acceleration: Double) {
        let t = min(max(rawTime, 0), duration)
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let t5 = t4 * t

        let position = c0 + c1 * t + c2 * t2 + c3 * t3 + c4 * t4 + c5 * t5
        let velocity = c1 + 2 * c2 * t + 3 * c3 * t2 + 4 * c4 * t3 + 5 * c5 * t4
        let acceleration = 2 * c2 + 6 * c3 * t + 12 * c4 * t2 + 20 * c5 * t3
        return (position, velocity, acceleration)
    }
}
