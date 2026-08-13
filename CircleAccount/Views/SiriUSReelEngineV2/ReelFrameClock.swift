import QuartzCore
import UIKit

@MainActor
protocol SiriUSV2ReelFrameObserver: AnyObject {
    func reelFrameClockDidTick(timestamp: CFTimeInterval)
}

@MainActor
final class SiriUSV2ReelFrameClock {
    static let shared = SiriUSV2ReelFrameClock()

    private let observers = NSHashTable<AnyObject>.weakObjects()
    private var displayLink: CADisplayLink?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    func add(_ observer: SiriUSV2ReelFrameObserver) {
        observers.add(observer)
        startIfNeeded()
    }

    func remove(_ observer: SiriUSV2ReelFrameObserver) {
        observers.remove(observer)
        stopIfUnused()
    }

    private func startIfNeeded() {
        guard displayLink == nil, !observers.allObjects.isEmpty else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 60,
                maximum: 120,
                preferred: 120
            )
        } else {
            link.preferredFramesPerSecond = 60
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopIfUnused() {
        guard observers.allObjects.isEmpty else { return }
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let presentationTimestamp = link.targetTimestamp > link.timestamp
            ? link.targetTimestamp
            : link.timestamp
        let currentObservers = observers.allObjects.compactMap {
            $0 as? SiriUSV2ReelFrameObserver
        }
        for observer in currentObservers {
            observer.reelFrameClockDidTick(timestamp: presentationTimestamp)
        }
        stopIfUnused()
    }

    @objc private func applicationDidEnterBackground() {
        displayLink?.isPaused = true
    }

    @objc private func applicationWillEnterForeground() {
        displayLink?.isPaused = false
    }
}
