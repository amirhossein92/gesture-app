import CMultitouch
import CoreGraphics
import Foundation

// ---------------------------------------------------------------------------
// Tunables
// ---------------------------------------------------------------------------

/// Minimum horizontal distance (normalized 0..1 across the trackpad) between the
/// held anchor finger and the tapping finger for the tap to count as a clear
/// left/right tap rather than an ambiguous one.
private let sideThreshold: Float = 0.05

/// A tap finger must lift within this many seconds to count as a tap (not a
/// second held finger / scroll / drag).
private let tapMaxDuration: Double = 0.5

/// After a switch fires, ignore further taps for this long. A single physical
/// tap can flicker into several quick contact on/off cycles; without this each
/// flicker would fire again.
private let fireCooldown: Double = 0.3

/// How far (normalized) the anchor finger may drift and still count as "held".
/// A held finger barely moves; a swiping/scrolling finger travels well past
/// this, which disqualifies the gesture.
private let anchorMoveThreshold: Float = 0.15

// Virtual key code for Tab.
private let kVK_Tab: CGKeyCode = 0x30

// ---------------------------------------------------------------------------
// Gesture state
//
// The MultitouchSupport callback is a C function pointer with no captured
// context, so gesture state lives in this global. It is only ever touched from
// the single callback thread.
// ---------------------------------------------------------------------------

private struct GestureState {
    // The first finger down. Held while a second finger taps beside it.
    var anchorID: Int32?
    var anchorX: Float = 0
    // Where the anchor first landed, to measure drift ("held" vs swiping).
    var anchorStartX: Float = 0
    var anchorStartY: Float = 0

    // A second finger being evaluated as a potential tap.
    var tapID: Int32?
    var tapDownTime: Double = 0
    var tapX: Float = 0

    /// Timestamp of the last switch fired, for cooldown/debounce.
    var lastFireTime: Double = 0

    /// Gesture disqualified (e.g. 3+ fingers, or the anchor moved). Stays set
    /// until every finger lifts, so a multi-finger gesture can never fire even
    /// as fingers lift off one at a time.
    var blocked: Bool = false

    /// Currently-tracked finger IDs, so we can diff against the next frame to
    /// detect fingers that just appeared or just lifted.
    var prevIDs: Set<Int32> = []

    mutating func reset() {
        anchorID = nil
        tapID = nil
    }
}

private var state = GestureState()

// ---------------------------------------------------------------------------
// Keystroke output
// ---------------------------------------------------------------------------

/// Post Ctrl+Tab (next) or Ctrl+Shift+Tab (previous). Requires Accessibility
/// permission for the process posting the events.
private func switchTab(next: Bool) {
    let source = CGEventSource(stateID: .hidSystemState)
    var flags: CGEventFlags = .maskControl
    if !next { flags.insert(.maskShift) }

    let down = CGEvent(keyboardEventSource: source, virtualKey: kVK_Tab, keyDown: true)
    let up = CGEvent(keyboardEventSource: source, virtualKey: kVK_Tab, keyDown: false)
    down?.flags = flags
    up?.flags = flags
    down?.post(tap: .cghidEventTap)
    up?.post(tap: .cghidEventTap)
}

// ---------------------------------------------------------------------------
// Touch frame callback
// ---------------------------------------------------------------------------

private let contactCallback: MTContactCallbackFunction = {
    _, touchesPtr, numTouches, timestamp, _ -> Int32 in

    guard let touchesPtr = touchesPtr else { return 0 }
    let touches = UnsafeBufferPointer(start: touchesPtr, count: Int(numTouches))

    // Map current frame's fingers to their (x, y) positions.
    var currentPos: [Int32: (x: Float, y: Float)] = [:]
    for t in touches {
        currentPos[t.fingerID] = (t.normalized.position.x, t.normalized.position.y)
    }
    let currentIDs = Set(currentPos.keys)

    // The gesture is strictly two fingers. Any third finger disqualifies it
    // until the whole hand lifts, so multi-finger swipes never fire.
    if numTouches >= 3 {
        state.blocked = true
        state.reset()
    }
    if currentIDs.isEmpty {
        state.blocked = false
    }
    if state.blocked {
        state.prevIDs = currentIDs
        return 0
    }

    let newIDs = currentIDs.subtracting(state.prevIDs)
    let goneIDs = state.prevIDs.subtracting(currentIDs)

    // --- Handle lifts first ---------------------------------------------------
    // If the anchor lifted (including a two-finger tap where both fingers lift
    // together), cancel the whole gesture. Checking this before the tap-lift
    // ensures simultaneous two-finger taps never trigger a switch.
    if let anchor = state.anchorID, goneIDs.contains(anchor) {
        state.reset()
    } else if let tap = state.tapID, goneIDs.contains(tap) {
        // The tap finger lifted while the anchor is still down. Fire if it was
        // brief and clearly to one side of the anchor.
        let brief = (timestamp - state.tapDownTime) <= tapMaxDuration
        let cooled = (timestamp - state.lastFireTime) >= fireCooldown
        let dx = state.tapX - state.anchorX
        if brief, cooled, abs(dx) >= sideThreshold {
            switchTab(next: dx > 0)
            state.lastFireTime = timestamp
        }
        // Keep the anchor down so repeated taps keep switching tabs.
        state.tapID = nil
    }

    // --- Handle new touches ---------------------------------------------------
    for id in newIDs {
        guard let p = currentPos[id] else { continue }
        if state.anchorID == nil {
            state.anchorID = id
            state.anchorX = p.x
            state.anchorStartX = p.x
            state.anchorStartY = p.y
        } else if state.tapID == nil, id != state.anchorID {
            state.tapID = id
            state.tapX = p.x
            state.tapDownTime = timestamp
        }
    }

    // --- Track positions & enforce that the anchor stays "held" --------------
    if let anchor = state.anchorID, let p = currentPos[anchor] {
        let dx = p.x - state.anchorStartX
        let dy = p.y - state.anchorStartY
        if dx * dx + dy * dy > anchorMoveThreshold * anchorMoveThreshold {
            // The anchor is travelling — this is a swipe/scroll, not a hold.
            state.blocked = true
            state.reset()
        } else {
            state.anchorX = p.x
        }
    }
    if let tap = state.tapID, let p = currentPos[tap] {
        state.tapX = p.x
    }

    state.prevIDs = currentIDs
    return 0
}

// ---------------------------------------------------------------------------
// Public control surface
//
// The multitouch listening and the keystroke posting run in whichever process
// calls these — so that single process is the one that needs Accessibility
// permission. (A child process would need its own separate grant.)
// ---------------------------------------------------------------------------

public enum GestureEngine {
    private static var device: MTDeviceRef?
    private static var running = false

    public static var isRunning: Bool { running }

    /// Start listening. Returns false if no multitouch device was found.
    @discardableResult
    public static func start() -> Bool {
        if running { return true }

        if device == nil {
            device = MTDeviceCreateDefault()
            guard device != nil else { return false }
            MTRegisterContactFrameCallback(device, contactCallback)
        }

        state = GestureState() // fresh gesture state each run
        MTDeviceStart(device, 0)
        running = true
        return true
    }

    /// Stop listening. Safe to call when already stopped.
    public static func stop() {
        guard running, let device = device else { return }
        MTDeviceStop(device)
        running = false
    }
}
