// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "gesture-app",
    platforms: [.macOS(.v11)],
    targets: [
        // Declarations for Apple's private MultitouchSupport.framework.
        .target(name: "CMultitouch"),

        // Shared gesture engine: listens to trackpad touch frames and posts
        // Ctrl+Tab / Ctrl+Shift+Tab based on a hold-and-tap gesture. Runs
        // in-process for whichever target uses it, so that process is the one
        // needing Accessibility permission.
        .target(
            name: "GestureEngine",
            dependencies: ["CMultitouch"],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/System/Library/PrivateFrameworks",
                    "-framework", "MultitouchSupport",
                ])
            ]
        ),

        // Standalone CLI runner for the gesture engine.
        .executableTarget(name: "gesture-app", dependencies: ["GestureEngine"]),

        // Menu-bar app: runs the gesture engine in-process, Start/Stop from the
        // menu bar. This is the process to grant Accessibility permission.
        .executableTarget(name: "gesture-control", dependencies: ["GestureEngine"]),
    ]
)
