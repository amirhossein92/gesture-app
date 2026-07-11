import ApplicationServices
import Foundation
import GestureEngine

// Standalone CLI runner for the gesture service. The menu-bar app
// (gesture-control) uses the same GestureEngine in-process instead.

guard GestureEngine.start() else {
    FileHandle.standardError.write(Data("No multitouch device found.\n".utf8))
    exit(1)
}

// Warn (but keep running) if we can't post keystrokes yet.
if !AXIsProcessTrusted() {
    let msg = "Warning: Accessibility permission not granted. Tab switching will "
        + "not work until this process is enabled in System Settings > Privacy & "
        + "Security > Accessibility.\n"
    FileHandle.standardError.write(Data(msg.utf8))
}

CFRunLoopRun()
