// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "FFmpegKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "FFmpeg",
            type: .static,
            targets: ["FFmpeg"]
        ),
        .library(name: "Libavcodec", targets: ["Libavcodec"]),
        .library(name: "Libavfilter", targets: ["Libavfilter"]),
        .library(name: "Libavformat", targets: ["Libavformat"]),
        .library(name: "Libavutil", targets: ["Libavutil"]),
        .library(name: "Libswresample", targets: ["Libswresample"]),
        .library(name: "Libswscale", targets: ["Libswscale"]),
        .library(name: "Libssl", targets: ["Libssl"]),
        .library(name: "Libcrypto", targets: ["Libcrypto"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "FFmpeg",
            dependencies: [
                "Libavcodec", "Libavfilter", "Libavformat", "Libavutil", "Libswresample", "Libswscale",
                "Libssl", "Libcrypto",
//                "Libsrt",
            ],
//            dependencies: ["Libssl", "Libcrypto"],
//            exclude: ["include", "compat"],
//            cSettings: [
//                .headerSearchPath("compat"),
//                .headerSearchPath("compat/cuda"),
//                .headerSearchPath("include/libavcodec"),
//                .headerSearchPath("include/libavcodec/aarch64"),
//                .headerSearchPath("include/libavcodec/arm"),
//                .headerSearchPath("include/libavcodec/x86"),
//                .headerSearchPath("include/libavdevice"),
//                .headerSearchPath("include/libavfilter"),
//                .headerSearchPath("include/libavformat"),
//                .headerSearchPath("include/libavutil"),
//                .headerSearchPath("include/libswresample"),
//                .headerSearchPath("include/libswscale"),
//            ],
            linkerSettings: [
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),
        .executableTarget(
            name: "build-FFmpeg",
            path: "Plugins/BuildFFmpeg"
        ),
        // .plugin(
        //     name: "Build FFmpeg",
        //     capability: .command(
        //         intent: .custom(
        //             verb: "build-FFmpeg",
        //             description: "You can customize FFmpeg and then compile FFmpeg"
        //         ),
        //         permissions: [
        //             .writeToPackageDirectory(reason: "This command compile FFmpeg and generate xcframework. So you need run swift package build-FFmpeg --allow-writing-to-package-directory"),
        //         ]
        //     )
        // ),
        .binaryTarget(
            name: "Libavcodec",
            path: "Sources/Libavcodec.xcframework"
        ),
        .binaryTarget(
            name: "Libavfilter",
            path: "Sources/Libavfilter.xcframework"
        ),
        .binaryTarget(
            name: "Libavformat",
            path: "Sources/Libavformat.xcframework"
        ),
        .binaryTarget(
            name: "Libavutil",
            path: "Sources/Libavutil.xcframework"
        ),
        .binaryTarget(
            name: "Libswresample",
            path: "Sources/Libswresample.xcframework"
        ),
        .binaryTarget(
            name: "Libswscale",
            path: "Sources/Libswscale.xcframework"
        ),
        .binaryTarget(
            name: "Libssl",
            path: "Sources/Libssl.xcframework"
        ),
        .binaryTarget(
            name: "Libcrypto",
            path: "Sources/Libcrypto.xcframework"
        ),
//        .binaryTarget(
//            name: "Libsrt",
//            path: "Sources/Libsrt.xcframework"
//        ),
    ]
)
