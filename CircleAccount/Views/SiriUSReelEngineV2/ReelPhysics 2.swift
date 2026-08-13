import Foundation

final class SiriUSV2ReelController {
    private(set) var state: SiriUSV2ReelState = .idle
    private(set) var strip: SiriUSV2ReelStrip

    private let configuration: SiriUSV2ReelConfiguration
    private var phase: Double
    private var velocity = 0.0
    private var acceleration = 0.0
    private var stateElapsed: TimeInterval = 0
    private var motorElapsed: TimeInterval = 0
    private var trajectory: SiriUSQuinticTrajectory?
    private var targetPhase: Double?
    private var lastInputs: SiriUSV2ReelInputs

    init(inputs: SiriUSV2ReelInputs) {
        configuration = SiriUSV2ReelConfiguration(reelIndex: inputs.reelIndex)
        strip = SiriUSV2ReelStrip(symbolPool: inputs.symbolPool, reelIndex: inputs.reelIndex)
        phase = Double(max(inputs.reelIndex, 0) * 11)
        lastInputs = inputs
        strip.center(inputs.isStopped ? inputs.finalSymbol : inputs.initialDisplaySymbol, at: phase)
        state = inputs.isStopped ? .stopped : .idle

        if inputs.isSpinning {
            startSpin()
        }
    }

    func apply(_ inputs: SiriUSV2ReelInputs) {
        let old = lastInputs
        lastInputs = inputs

        if inputs.symbolPool != old.symbolPool,
           state == .idle || state == .stopped {
            strip = SiriUSV2ReelStrip(
                symbolPool: inputs.symbolPool,
                reelIndex: inputs.reelIndex
            )
            strip.center(currentRestingSymbol, at: phase)
        }

        if inputs.isSpinning && !old.isSpinning {
            startSpin()
        }

        if inputs.isStopped && !old.isStopped {
            requestStop(finalSymbol: inputs.finalSymbol)
        }

        if !inputs.isStopped && old.isStopped,
           !inputs.isSpinning {
            state = .idle
            velocity = 0
            acceleration = 0
            strip.center(inputs.initialDisplaySymbol, at: phase)
        }
    }

    func fixedStep(_ deltaTime: TimeInterval) {
        let dt = min(max(deltaTime, 0), 1.0 / 60.0)
        stateElapsed += dt
        motorElapsed += dt

        switch state {
        case .idle, .stopped:
            velocity = 0
            acceleration = 0

        case .accelerating:
            stepAcceleration(dt: dt)

        case .cruising:
            stepCruise(dt: dt)

        case .decelerating:
            stepDeceleration()

        case .locking:
            stepLocking()
        }

        normalizePhaseWhenSafe()
    }

    func makeSnapshot(predictionTime: TimeInterval = 0) -> SiriUSV2ReelRenderSnapshot {
        let renderPhase = predictedPhase(after: predictionTime)
        let faceCount = configuration.visibleFaceCount
        let half = faceCount / 2
        let wholePhase = floor(renderPhase)
        let baseIndex = Int(wholePhase)
        let fraction = renderPhase - wholePhase
        let faces = (-half...half).map { slot in
            let absoluteIndex = baseIndex + slot
            let angularPosition = fraction - Double(slot)
            return SiriUSV2ReelFaceSnapshot(
                absoluteIndex: absoluteIndex,
                symbol: strip.symbol(atAbsoluteIndex: absoluteIndex),
                localAngle: angularPosition * configuration.symbolAngle
            )
        }

        let normalizedVelocity = min(
            max(abs(velocity) / configuration.cruiseVelocity, 0),
            1
        )
        let impact: Double
        if state == .locking {
            impact = min(1, exp(-configuration.lockDamping * stateElapsed) * 1.8)
        } else {
            impact = 0
        }

        return SiriUSV2ReelRenderSnapshot(
            state: state,
            absolutePhase: renderPhase,
            angularVelocity: velocity,
            normalizedVelocity: normalizedVelocity,
            impactIntensity: impact,
            faces: faces
        )
    }

    private func predictedPhase(after rawTime: TimeInterval) -> Double {
        let time = min(max(rawTime, 0), SiriUSReelEngineV2.physicsStep)
        guard time > 0 else { return phase }

        switch state {
        case .accelerating, .cruising:
            let predictedVelocity = max(0, velocity + acceleration * time)
            return phase + (velocity + predictedVelocity) * 0.5 * time
        case .decelerating:
            return trajectory?.sample(at: stateElapsed + time).position ?? phase
        case .locking:
            guard let targetPhase else { return phase }
            return targetPhase + lockResponse(at: stateElapsed + time).offset
        case .idle, .stopped:
            return phase
        }
    }

    private var currentRestingSymbol: String {
        lastInputs.isStopped ? lastInputs.finalSymbol : lastInputs.initialDisplaySymbol
    }

    private func startSpin() {
        state = .accelerating
        stateElapsed = 0
        motorElapsed = 0
        velocity = 0
        acceleration = 0
        trajectory = nil
        targetPhase = nil

        strip = SiriUSV2ReelStrip(
            symbolPool: lastInputs.symbolPool,
            reelIndex: lastInputs.reelIndex
        )
        strip.center(lastInputs.initialDisplaySymbol, at: phase)
    }

    private func requestStop(finalSymbol: String) {
        guard state == .accelerating || state == .cruising else {
            if state == .idle {
                strip.center(finalSymbol, at: phase)
                state = .stopped
            }
            return
        }

        let incomingVelocity = max(velocity, configuration.cruiseVelocity * 0.50)
        let plan = SiriUSV2ReelStopPlanner(configuration: configuration).makePlan(
            phase: phase,
            velocity: incomingVelocity,
            acceleration: acceleration
        )
        let duration = plan.duration
        let resolvedTarget = plan.targetPhase

        strip.install(finalSymbol, atAbsoluteIndex: Int(resolvedTarget))
        trajectory = SiriUSQuinticTrajectory(
            startPosition: phase,
            startVelocity: incomingVelocity,
            startAcceleration: acceleration,
            endPosition: resolvedTarget,
            duration: duration
        )
        targetPhase = resolvedTarget
        state = .decelerating
        stateElapsed = 0
    }

    private func stepAcceleration(dt: TimeInterval) {
        let duration = configuration.accelerationDuration
        let engagedTime = max(0, stateElapsed - configuration.motorEngagementDuration)
        let activeDuration = max(0.001, duration - configuration.motorEngagementDuration)
        let progress = min(max(engagedTime / activeDuration, 0), 1)
        let p2 = progress * progress
        let p3 = p2 * progress
        let p4 = p3 * progress
        let p5 = p4 * progress
        let smootherstep = 6 * p5 - 15 * p4 + 10 * p3
        let previousVelocity = velocity
        velocity = configuration.cruiseVelocity * smootherstep
        acceleration = (velocity - previousVelocity) / max(dt, 0.000_001)
        // Trapezoidal integration keeps phase and angular velocity C1-smooth
        // and removes the small cadence-dependent advance visible at 60 Hz.
        phase += (previousVelocity + velocity) * 0.5 * dt

        if progress >= 1 {
            state = .cruising
            stateElapsed = 0
            velocity = configuration.cruiseVelocity
            acceleration = 0
        }
    }

    private func stepCruise(dt: TimeInterval) {
        let index = Double(configuration.reelIndex)
        let ripple = sin(motorElapsed * 7.1 + index * 1.7) * 0.0065
            + sin(motorElapsed * 16.4 + index * 0.9) * 0.0022
        let previousVelocity = velocity
        let targetVelocity = configuration.cruiseVelocity * (1 + ripple)
        let response = 1 - exp(-dt / 0.055)
        velocity += (targetVelocity - velocity) * response
        acceleration = (velocity - previousVelocity) / max(dt, 0.000_001)
        phase += (previousVelocity + velocity) * 0.5 * dt
    }

    private func stepDeceleration() {
        guard let trajectory else {
            state = .locking
            stateElapsed = 0
            return
        }

        let sample = trajectory.sample(at: stateElapsed)
        phase = sample.position
        velocity = max(0, sample.velocity)
        acceleration = sample.acceleration

        if stateElapsed >= trajectory.duration {
            phase = targetPhase ?? phase
            velocity = 0
            acceleration = 0
            state = .locking
            stateElapsed = 0
        }
    }

    private func stepLocking() {
        guard let targetPhase else {
            state = .stopped
            return
        }

        let response = lockResponse(at: stateElapsed)
        phase = targetPhase + response.offset
        velocity = response.velocity

        if stateElapsed >= configuration.lockDuration {
            phase = targetPhase
            velocity = 0
            acceleration = 0
            state = .stopped
            stateElapsed = 0
        }
    }

    private func lockResponse(at time: TimeInterval) -> (offset: Double, velocity: Double) {
        let t = max(0, time)
        let amplitude = configuration.lockAmplitude
        let frequency = configuration.lockAngularFrequency
        let damping = configuration.lockDamping
        let envelope = exp(-damping * t)
        let phase = frequency * t

        // Multiplying by phase gives zero displacement and zero velocity at
        // brake release, so deceleration flows continuously into the tremor.
        let primaryOffset = amplitude * phase * envelope * sin(phase)
        let primaryVelocity = amplitude * frequency * envelope
            * ((1 - damping * t) * sin(phase) + phase * cos(phase))

        // A delayed, lower-frequency chassis knock follows the initial brake
        // bite. Both displacement and velocity begin at zero, preserving C1
        // continuity while leaving a short mechanical after-tremor.
        let knockTime = max(0, t - 0.125)
        let knockFrequency = frequency * 0.56
        let knockPhase = knockFrequency * knockTime
        let knockEnvelope = exp(-damping * 0.72 * knockTime)
        let knockAmplitude = amplitude * 0.34
        let knockOffset = -knockAmplitude * knockPhase * knockEnvelope * sin(knockPhase)
        let knockVelocity = -knockAmplitude * knockFrequency * knockEnvelope
            * ((1 - damping * 0.72 * knockTime) * sin(knockPhase)
                + knockPhase * cos(knockPhase))
        return (primaryOffset + knockOffset, primaryVelocity + knockVelocity)
    }

    private func normalizePhaseWhenSafe() {
        guard state == .accelerating || state == .cruising,
              strip.count > 0,
              abs(phase) > 100_000 else {
            return
        }
        let laps = floor(phase / Double(strip.count))
        phase -= laps * Double(strip.count)
    }
}
