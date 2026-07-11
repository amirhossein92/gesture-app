import AppKit
import ApplicationServices
import GestureEngine

// Menu-bar app for the trackpad tab-switch gesture. The gesture engine runs
// in THIS process, so this is the one and only process that needs Accessibility
// permission (to post the Ctrl+Tab keystrokes).

final class Controller: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let startItem = NSMenuItem(title: "Start", action: #selector(start), keyEquivalent: "")
    private let stopItem = NSMenuItem(title: "Stop", action: #selector(stop), keyEquivalent: "")

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        startItem.target = self
        stopItem.target = self

        let menu = NSMenu()
        menu.addItem(startItem)
        menu.addItem(stopItem)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu

        // Ask for Accessibility up front (shows the system prompt if needed).
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        start() // Auto-start on launch.
        updateUI()
    }

    func applicationWillTerminate(_ notification: Notification) {
        GestureEngine.stop()
    }

    // MARK: Service control

    @objc private func start() {
        GestureEngine.start()
        updateUI()
    }

    @objc private func stop() {
        GestureEngine.stop()
        updateUI()
    }

    @objc private func quit() {
        GestureEngine.stop()
        NSApp.terminate(nil)
    }

    // MARK: UI

    private func updateUI() {
        let running = GestureEngine.isRunning
        statusItem.button?.title = running ? "●" : "○"
        startItem.isEnabled = !running
        stopItem.isEnabled = running
    }
}

let app = NSApplication.shared
let controller = Controller()
app.delegate = controller
app.setActivationPolicy(.accessory) // No dock icon; menu-bar only.
app.run()
