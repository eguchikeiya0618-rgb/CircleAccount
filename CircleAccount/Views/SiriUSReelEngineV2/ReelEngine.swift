import Foundation

enum SiriUSReelEngineV2 {
    static let version = "2.0.0"
    static let physicsStep: TimeInterval = 1.0 / 240.0
    static let minimumDisplayRate = 60
    static let preferredDisplayRate = 120
}

struct SiriUSV2StopPlan {
    let targetPhase: Double
    let slipSymbols: Int
    let duration: TimeInterval
    let naturalBrakingDistance: Double
}

/// Converts current mechanical energy into a reachable stop tooth.
/// No random number or symbol hash participates in slip selection.
struct SiriUSV2ReelStopPlanner {
    let configuration: SiriUSV2ReelConfiguration

    func makePlan(
        phase: Double,
        velocity: Double,
        acceleration: Double
    ) -> SiriUSV2StopPlan {
        let safeVelocity = max(velocity, configuration.cruiseVelocity * 0.50)

        // Rotational equivalent of v² / 2a. Units are symbol pitches.
        let energyDistance = safeVelocity * safeVelocity
            / (2 * configuration.brakingDeceleration)
        let accelerationLoad = max(0, acceleration)
            / max(configuration.brakingDeceleration, 0.001)
        let normalizedMomentum = min(
            max(safeVelocity / configuration.cruiseVelocity, 0),
            1.25
        )
        let rotorCarry = normalizedMomentum * configuration.inertialTravelFactor
        let naturalDistance = energyDistance
            + accelerationLoad * 0.18
            + rotorCarry
        let minimumDistance = max(
            configuration.minimumStopTravel,
            naturalDistance
        )

        // The fractional tooth energy determines how many additional ratchet
        // teeth pass the detector. This produces a physical 0...3 symbol slip.
        let fractionalEnergy = naturalDistance - floor(naturalDistance)
        let rawSlip = Int(
            floor(fractionalEnergy * 3.2 + normalizedMomentum * 0.72)
        )
        let slip = min(max(rawSlip, 0), 3)
        let target = ceil(phase + minimumDistance) + Double(slip)
        let duration = configuration.stopDuration
            + Double(slip) * configuration.slipDurationIncrement

        return SiriUSV2StopPlan(
            targetPhase: target,
            slipSymbols: slip,
            duration: duration,
            naturalBrakingDistance: naturalDistance
        )
    }
}
