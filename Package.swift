// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GrammarKeyboard",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "GrammarKeyboardCore",
            targets: ["GrammarKeyboardCore"]
        )
    ],
    targets: [
        .target(
            name: "GrammarKeyboardCore",
            dependencies: [],
            path: "GrammarKeyboard/Sources"
        )
    ]
)
