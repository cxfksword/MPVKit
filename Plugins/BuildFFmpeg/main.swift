import Foundation
// import PackagePlugin

do {
    try BuildFFmpeg.performCommand(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    print(error.localizedDescription)
    exit(0)
}

enum BuildFFmpeg {
    // @main struct BuildFFmpeg: CommandPlugin {
//    func performCommand(context _: PluginContext, arguments: [String]) throws {
//        performCommand(arguments: arguments)
//    }
    static func performCommand(arguments: [String]) throws {
        if Utility.shell("which brew") == nil {
            print("""
            You need to run the script first
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            """)
            return
        }

        let path = URL.currentDirectory + "Script"
        if !FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
        }
        FileManager.default.changeCurrentDirectoryPath(path.path)
        BaseBuild.platforms = arguments.compactMap { argument in
            if argument.hasPrefix("platform=") {
                let value = String(argument.suffix(argument.count - "platform=".count))
                return PlatformType(rawValue: value)
            } else {
                return nil
            }
        }
        if BaseBuild.platforms.isEmpty {
            BaseBuild.platforms = PlatformType.allCases
        }
        if arguments.firstIndex(of: "enable-openssl") != nil {
            try BuildOpenSSL().buildALL()
        }
        if Utility.shell("which pkg-config") == nil {
            Utility.shell("brew install pkg-config")
        }
        if arguments.firstIndex(of: "enable-libsrt") != nil {
            try BuildSRT().buildALL()
        }

        if arguments.firstIndex(of: "enable-libass") != nil {
            try BuildFribidi().buildALL()
            try BuildHarfbuzz().buildALL()
            try BuildASS().buildALL()
        }
        try BuildFFMPEG(arguments: arguments).buildALL()
        if arguments.firstIndex(of: "enable-mpv") != nil {
            try BuildMPV().buildALL()
        }
    }
}

private enum Library: String, CaseIterable {
    case FFmpeg, fribidi, harfbuzz, libass, mpv, openssl, srt
    var version: String {
        switch self {
        case .libass:
            return "0.17.0"
        case .FFmpeg:
            return "n5.1.2"
        case .fribidi:
            return "1.0.12"
        case .harfbuzz:
            return "5.3.1"
        case .mpv:
            return "0.35.0"
        case .openssl:
            return "openssl-3.0.7"
        case .srt:
            return "1.5.1"
        }
    }

    var url: String {
        switch self {
        case .FFmpeg, .libass, .harfbuzz, .openssl:
            return "https://codeload.github.com/\(rawValue)/\(rawValue)/tar.gz/refs/tags/\(version)"
        case .mpv:
            return "https://codeload.github.com/\(rawValue)-player/\(rawValue)/tar.gz/refs/tags/v\(version)"
        case .srt:
            return "https://codeload.github.com/Haivision/\(rawValue)/tar.gz/refs/tags/v\(version)"
        default:
            return "https://codeload.github.com/\(rawValue)/\(rawValue)/tar.gz/refs/tags/v\(version)"
        }
    }
}

private class BaseBuild {
    static var platforms = PlatformType.allCases
    private let library: Library
    let directoryURL: URL
    init(library: Library) {
        self.library = library
        directoryURL = URL.currentDirectory + "\(library.rawValue)-\(library.version)"
    }

    func buildALL() throws {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            Utility.shell("curl \(library.url) | tar xj")
        }
        try? FileManager.default.removeItem(at: URL.currentDirectory + library.rawValue)
        for platform in BaseBuild.platforms {
            for arch in architectures(platform) {
                try build(platform: platform, arch: arch)
            }
        }
        try createXCFramework()
    }

    func architectures(_ platform: PlatformType) -> [ArchType] {
        platform.architectures()
    }

    func build(platform: PlatformType, arch: ArchType) throws {
        let url = scratch(platform: platform, arch: arch)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        let environ = environment(platform: platform, arch: arch)
        let configure = directoryURL + "configure"
        if !FileManager.default.fileExists(atPath: configure.path) {
            let autogen = directoryURL + "autogen.sh"
            if FileManager.default.fileExists(atPath: autogen.path) {
                do {
                    var environ = environ
                    environ["NOCONFIGURE"] = "1"
                    try Utility.launch(path: autogen.path, arguments: [], environment: environ)
                } catch {
                    try? Utility.launch(path: "/usr/local/bin/autoreconf", arguments: ["--force", "--install", "-I", "m4"], currentDirectoryURL: directoryURL, environment: environ)
                }
            } else {
                try? Utility.launch(path: "/usr/local/bin/autoreconf", arguments: ["--force", "--install", "-I", "m4"], currentDirectoryURL: directoryURL, environment: environ)
            }
        }
        try? Utility.launch(path: "/usr/bin/make", arguments: ["distclean"], currentDirectoryURL: url)
        try Utility.launch(path: configure.path, arguments: arguments(platform: platform, arch: arch), currentDirectoryURL: url, environment: environ)
        modifyMakefile(url: url + "Makefile")
        try Utility.launch(path: "/usr/bin/make", arguments: ["-j5", "-s"], currentDirectoryURL: url, environment: environ)
        try Utility.launch(path: "/usr/bin/make", arguments: ["-j5", "install", "-s"], currentDirectoryURL: url, environment: environ)
    }

    func modifyMakefile(url _: URL) {}

    private func pkgConfigPath(platform: PlatformType, arch: ArchType) -> String {
        var pkgConfigPath = ""
        for lib in Library.allCases {
            let path = URL.currentDirectory + [lib.rawValue, platform.rawValue, "thin", arch.rawValue]
            if FileManager.default.fileExists(atPath: path.path) {
                pkgConfigPath += "\(path.path)/lib/pkgconfig:"
            }
        }
        return pkgConfigPath
    }

    func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        ["LC_CTYPE": "C",
         "CC": ccFlags(platform: platform, arch: arch),
         "CFLAGS": cFlags(platform: platform, arch: arch),
         "CXXFLAGS": cFlags(platform: platform, arch: arch),
         "LDFLAGS": ldFlags(platform: platform, arch: arch),
         "PKG_CONFIG_PATH": pkgConfigPath(platform: platform, arch: arch),
         "CMAKE_OSX_ARCHITECTURES": arch.rawValue,
         "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
    }

    func ccFlags(platform _: PlatformType, arch _: ArchType) -> String {
        "/usr/bin/clang "
    }

    func cFlags(platform: PlatformType, arch: ArchType) -> String {
        var cflags = "-arch " + arch.rawValue + " " + platform.deploymentTarget(arch)
        if platform == .macos || platform == .maccatalyst {
            cflags += " -fno-common"
        }
        let syslibroot = platform.isysroot()
        cflags += " -isysroot \(syslibroot)"
        if platform == .maccatalyst {
            cflags += " -iframework \(syslibroot)/System/iOSSupport/System/Library/Frameworks"
        }
        if platform == .tvos || platform == .tvsimulator {
            cflags += " -DHAVE_FORK=0"
        }
        return cflags
    }

    func ldFlags(platform: PlatformType, arch: ArchType) -> String {
        cFlags(platform: platform, arch: arch)
    }

    func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
        ]
    }

    func createXCFramework() throws {
        var frameworks: [String] = []
        if let platform = BaseBuild.platforms.first {
            if let arch = architectures(platform).first {
                let lib = thinDir(platform: platform, arch: arch) + "lib"
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: lib.path)
                for fileName in fileNames {
                    if fileName.hasPrefix("lib"), fileName.hasSuffix(".a") {
                        frameworks.append("Lib" + fileName.dropFirst(3).dropLast(2))
                    }
                }
            }
        }
        for framework in frameworks {
            var arguments = ["-create-xcframework"]
            for platform in BaseBuild.platforms {
                arguments.append("-framework")
                arguments.append(try createFramework(framework: framework, platform: platform))
            }
            arguments.append("-output")
            let XCFrameworkFile = URL.currentDirectory + ["../Sources", framework + ".xcframework"]
            arguments.append(XCFrameworkFile.path)
            if FileManager.default.fileExists(atPath: XCFrameworkFile.path) {
                try? FileManager.default.removeItem(at: XCFrameworkFile)
            }
            try Utility.launch(path: "/usr/bin/xcodebuild", arguments: arguments)
        }
    }

    private func createFramework(framework: String, platform: PlatformType) throws -> String {
        let frameworkDir = URL.currentDirectory + [library.rawValue, platform.rawValue, "\(framework).framework"]
        try? FileManager.default.removeItem(at: frameworkDir)
        try? FileManager.default.createDirectory(at: frameworkDir, withIntermediateDirectories: true, attributes: nil)
        var arguments = ["-create"]
        for arch in architectures(platform) {
            let prefix = thinDir(platform: platform, arch: arch)
            arguments.append((prefix + ["lib", "\(framework).a"]).path)
            var headerURL = prefix + "include" + framework
            if !FileManager.default.fileExists(atPath: headerURL.path) {
                headerURL = prefix + "include"
            }
            try? FileManager.default.copyItem(at: headerURL, to: frameworkDir + "Headers")
        }
        arguments.append("-output")
        arguments.append((frameworkDir + framework).path)
        try Utility.launch(path: "/usr/bin/lipo", arguments: arguments)
        try? FileManager.default.createDirectory(at: frameworkDir + "Modules", withIntermediateDirectories: true, attributes: nil)
        var modulemap = """
        framework module \(framework) [system] {
            umbrella "."

        """
        frameworkExcludeHeaders(framework).forEach { header in
            modulemap += """
                exclude header "\(header).h"

            """
        }
        modulemap += """
            export *
        }
        """
        FileManager.default.createFile(atPath: frameworkDir.path + "/Modules/module.modulemap", contents: modulemap.data(using: .utf8), attributes: nil)
        createPlist(path: frameworkDir.path + "/Info.plist", name: framework, minVersion: platform.minVersion, platform: platform.sdk())
        return frameworkDir.path
    }

    func thinDir(platform: PlatformType, arch: ArchType) -> URL {
        URL.currentDirectory + [library.rawValue, platform.rawValue, "thin", arch.rawValue]
    }

    func scratch(platform: PlatformType, arch: ArchType) -> URL {
        URL.currentDirectory + [library.rawValue, platform.rawValue, "scratch", arch.rawValue]
    }

    func frameworkExcludeHeaders(_: String) -> [String] {
        []
    }

    private func createPlist(path: String, name: String, minVersion: String, platform: String) {
        let identifier = "com.kintan.ksplayer." + name
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleExecutable</key>
        <string>\(name)</string>
        <key>CFBundleIdentifier</key>
        <string>\(identifier)</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>\(name)</string>
        <key>CFBundlePackageType</key>
        <string>FMWK</string>
        <key>CFBundleShortVersionString</key>
        <string>87.88.520</string>
        <key>CFBundleVersion</key>
        <string>87.88.520</string>
        <key>CFBundleSignature</key>
        <string>????</string>
        <key>MinimumOSVersion</key>
        <string>\(minVersion)</string>
        <key>CFBundleSupportedPlatforms</key>
        <array>
        <string>\(platform)</string>
        </array>
        <key>NSPrincipalClass</key>
        <string></string>
        </dict>
        </plist>
        """
        FileManager.default.createFile(atPath: path, contents: content.data(using: .utf8), attributes: nil)
    }
}

private class BuildFFMPEG: BaseBuild {
    private let isDebug: Bool
    init(arguments: [String]) {
        isDebug = arguments.firstIndex(of: "enable-debug") != nil
        super.init(library: .FFmpeg)
    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        try super.build(platform: platform, arch: arch)
        let prefix = thinDir(platform: platform, arch: arch)
        let buildDir = scratch(platform: platform, arch: arch)
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        if let data = FileManager.default.contents(atPath: lldbFile.path), var str = String(data: data, encoding: .utf8) {
            str.append("settings \(str.count == 0 ? "set" : "append") target.source-map \((buildDir + "src").path) \(directoryURL.path)\n")
            try str.write(toFile: lldbFile.path, atomically: true, encoding: .utf8)
        }
        if platform == .macos, arch.executable() {
            try replaceBin(prefix: prefix, item: "ffmpeg")
            try replaceBin(prefix: prefix, item: "ffplay")
            try replaceBin(prefix: prefix, item: "ffprobe")
        }
    }

    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var environ = super.environment(platform: platform, arch: arch)
        environ["CPPFLAGS"] = cFlags(platform: platform, arch: arch)
        return environ
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var arguments = super.arguments(platform: platform, arch: arch)
        arguments += ffmpegConfiguers
        arguments.append("--target-os=darwin")
        arguments.append("--arch=\(arch.arch())")
        arguments.append(arch.cpu())
        if isDebug {
            arguments.append("--enable-debug")
            arguments.append("--disable-stripping")
            arguments.append("--disable-optimizations")
        } else {
            arguments.append("--disable-debug")
            arguments.append("--enable-stripping")
            arguments.append("--enable-optimizations")
        }
        /**
         aacpsdsp.o), building for Mac Catalyst, but linking in object file built for
         x86_64 binaries are built without ASM support, since ASM for x86_64 is actually x86 and that confuses `xcodebuild -create-xcframework` https://stackoverflow.com/questions/58796267/building-for-macos-but-linking-in-object-file-built-for-free-standing/59103419#59103419
         */
        if platform == .maccatalyst || arch == .x86_64 {
            arguments.append("--disable-neon")
            arguments.append("--disable-asm")
        } else {
            arguments.append("--enable-neon")
            arguments.append("--enable-asm")
        }
        if platform == .macos, arch.executable() {
            arguments.append("--enable-ffplay")
            arguments.append("--enable-sdl2")
            arguments.append("--enable-encoder=aac")
            arguments.append("--enable-encoder=movtext")
            arguments.append("--enable-encoder=mpeg4")
            arguments.append("--enable-decoder=rawvideo")
            arguments.append("--enable-filter=color")
            arguments.append("--enable-filter=lut")
            arguments.append("--enable-filter=negate")
            arguments.append("--enable-filter=testsrc")
            arguments.append("--disable-avdevice")
            //            arguments.append("--enable-avdevice")
            //            arguments.append("--enable-indev=lavfi")
        } else {
            arguments.append("--disable-avdevice")
            arguments.append("--disable-programs")
        }
        //        if platform == .isimulator || platform == .tvsimulator {
        //            arguments.append("--assert-level=1")
        //        }

        let opensslPath = URL.currentDirectory + [Library.openssl.rawValue, platform.rawValue, "thin", arch.rawValue]
        if FileManager.default.fileExists(atPath: opensslPath.path) {
            arguments.append("--enable-openssl")
        }
        let srtPath = URL.currentDirectory + [Library.srt.rawValue, platform.rawValue, "thin", arch.rawValue]
        if FileManager.default.fileExists(atPath: srtPath.path) {
            arguments.append("--enable-libsrt")
            arguments.append("--enable-protocol=libsrt")
        }
//        let assPath = URL.currentDirectory + [Library.libass.rawValue, platform.rawValue, "thin", arch.rawValue]
//        if FileManager.default.fileExists(atPath: assPath.path) {
//            arguments.append("--enable-libass")
//        }
        return arguments
    }

    private func replaceBin(prefix: URL, item: String) throws {
        if FileManager.default.fileExists(atPath: (prefix + ["bin", item]).path) {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/\(item)"))
            try? FileManager.default.copyItem(at: prefix + ["bin", item], to: URL(fileURLWithPath: "/usr/local/bin/\(item)"))
        }
    }

//    override func createXCFramework() throws {
//        try super.createXCFramework()
//        makeFFmpegSourece()
//    }

    private func makeFFmpegSourece() throws {
        guard let platform = BaseBuild.platforms.first, let arch = architectures(platform).first else {
            return
        }
        let target = URL.currentDirectory + ["../Sources", "FFmpeg"]
        try? FileManager.default.removeItem(at: target)
        try? FileManager.default.createDirectory(at: target, withIntermediateDirectories: true, attributes: nil)
        let thin = thinDir(platform: platform, arch: arch)
        try? FileManager.default.copyItem(at: thin + "include", to: target + "include")
        let scratchURL = scratch(platform: platform, arch: arch)
        try? FileManager.default.createDirectory(at: target + "include", withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.copyItem(at: scratchURL + "config.h", to: target + "include" + "config.h")
        let fileNames = try FileManager.default.contentsOfDirectory(atPath: scratchURL.path)
        for fileName in fileNames where fileName.hasPrefix("lib") {
            var url = scratchURL + fileName
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                // copy .c
                if let subpaths = FileManager.default.enumerator(atPath: url.path) {
                    let dstDir = target + fileName
                    while let subpath = subpaths.nextObject() as? String {
                        if subpath.hasSuffix(".c") {
                            let srcURL = url + subpath
                            let dstURL = target + "include" + fileName + subpath
                            try? FileManager.default.copyItem(at: srcURL, to: dstURL)
                        } else if subpath.hasSuffix(".o") {
                            let subpath = subpath.replacingOccurrences(of: ".o", with: ".c")
                            let srcURL = scratchURL + "src" + fileName + subpath
                            let dstURL = dstDir + subpath
                            let dstURLDir = dstURL.deletingLastPathComponent()
                            if !FileManager.default.fileExists(atPath: dstURLDir.path) {
                                try? FileManager.default.createDirectory(at: dstURLDir, withIntermediateDirectories: true, attributes: nil)
                            }
                            try? FileManager.default.copyItem(at: srcURL, to: dstURL)
                        }
                    }
                }
                url = scratchURL + "src" + fileName
                // copy .h
                try? FileManager.default.copyItem(at: scratchURL + "src" + "compat", to: target + "compat")
                if let subpaths = FileManager.default.enumerator(atPath: url.path) {
                    let dstDir = target + "include" + fileName
                    while let subpath = subpaths.nextObject() as? String {
                        if subpath.hasSuffix(".h") || subpath.hasSuffix("_template.c") {
                            let srcURL = url + subpath
                            let dstURL = dstDir + subpath
                            let dstURLDir = dstURL.deletingLastPathComponent()
                            if !FileManager.default.fileExists(atPath: dstURLDir.path) {
                                try? FileManager.default.createDirectory(at: dstURLDir, withIntermediateDirectories: true, attributes: nil)
                            }
                            try? FileManager.default.copyItem(at: srcURL, to: dstURL)
                        }
                    }
                }
            }
        }
    }

    override func buildALL() throws {
        try prepareAsm()
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        try? FileManager.default.removeItem(at: lldbFile)
        FileManager.default.createFile(atPath: lldbFile.path, contents: nil, attributes: nil)
        let path = directoryURL + "libavcodec/videotoolbox.c"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "kCVPixelBufferOpenGLESCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            try str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
        try super.buildALL()
    }

    private func prepareAsm() throws {
        if Utility.shell("which nasm") == nil {
            Utility.shell("brew install nasm")
        }
        if Utility.shell("which sdl2-config") == nil {
            Utility.shell("brew install sdl2")
        }
    }

    override func frameworkExcludeHeaders(_ framework: String) -> [String] {
        if framework == "Libavcodec" {
            return ["xvmc", "vdpau", "qsv", "dxva2", "d3d11va"]
        } else if framework == "Libavutil" {
            return ["hwcontext_vulkan", "hwcontext_vdpau", "hwcontext_vaapi", "hwcontext_qsv", "hwcontext_opencl", "hwcontext_dxva2", "hwcontext_d3d11va", "hwcontext_cuda"]
        } else {
            return super.frameworkExcludeHeaders(framework)
        }
    }

    private let ffmpegConfiguers = [
        // Configuration options:
        "--disable-armv5te", "--disable-armv6", "--disable-armv6t2", "--disable-bsfs",
        "--disable-bzlib", "--disable-gray", "--disable-iconv", "--disable-linux-perf",
        "--disable-xlib", "--disable-swscale-alpha", "--disable-symver", "--disable-small",
        "--enable-cross-compile", "--enable-gpl", "--enable-libxml2", "--enable-nonfree",
        "--enable-runtime-cpudetect", "--enable-thumb", "--enable-version3", "--pkg-config-flags=--static",
        "--enable-static", "--disable-shared",
        // Documentation options:
        "--disable-doc", "--disable-htmlpages", "--disable-manpages", "--disable-podpages", "--disable-txtpages",
        // Component options:
        "--enable-avcodec", "--enable-avformat", "--enable-avutil", "--enable-network", "--enable-swresample", "--enable-swscale",
        "--disable-devices", "--disable-outdevs", "--disable-indevs", "--disable-postproc",
        // ,"--disable-pthreads"
        // ,"--disable-w32threads"
        // ,"--disable-os2threads"
        // ,"--disable-dct"
        // ,"--disable-dwt"
        // ,"--disable-lsp"
        // ,"--disable-lzo"
        // ,"--disable-mdct"
        // ,"--disable-rdft"
        // ,"--disable-fft"
        // Hardware accelerators:
        "--disable-d3d11va", "--disable-dxva2", "--disable-vaapi", "--disable-vdpau",
        "--enable-videotoolbox", "--enable-audiotoolbox",
        // Individual component options:
        // ,"--disable-everything"
        // 用所有的encoders的话，那avcodec就会达到40MB了，指定的话，那就只要20MB。
        "--disable-encoders",
        // ./configure --list-decoders
        "--disable-decoders",
        // 视频
        "--enable-decoder=av1", "--enable-decoder=dca", "--enable-decoder=flv", "--enable-decoder=h263",
        "--enable-decoder=h263i", "--enable-decoder=h263p", "--enable-decoder=h264", "--enable-decoder=hevc",
        "--enable-decoder=mjpeg", "--enable-decoder=mjpegb", "--enable-decoder=mpeg1video", "--enable-decoder=mpeg2video",
        "--enable-decoder=mpeg4", "--enable-decoder=mpegvideo", "--enable-decoder=rv30", "--enable-decoder=rv40",
        "--enable-decoder=tscc", "--enable-decoder=wmv1", "--enable-decoder=wmv2", "--enable-decoder=wmv3",
        "--enable-decoder=vc1", "--enable-decoder=vp6", "--enable-decoder=vp6a", "--enable-decoder=vp6f",
        "--enable-decoder=vp7", "--enable-decoder=vp8", "--enable-decoder=vp9",
        // 音频
        "--enable-decoder=aac*", "--enable-decoder=ac3*", "--enable-decoder=alac*",
        "--enable-decoder=amr*", "--enable-decoder=ape", "--enable-decoder=cook",
        "--enable-decoder=dca", "--enable-decoder=dolby_e", "--enable-decoder=eac3*", "--enable-decoder=flac",
        "--enable-decoder=mp1*", "--enable-decoder=mp2*", "--enable-decoder=mp3*", "--enable-decoder=opus",
        "--enable-decoder=pcm*", "--enable-decoder=truehd", "--enable-decoder=vorbis", "--enable-decoder=wma*",
        // 字幕
        "--enable-decoder=ass", "--enable-decoder=dvbsub", "--enable-decoder=dvdsub", "--enable-decoder=movtext",
        "--enable-decoder=pgssub", "--enable-decoder=srt", "--enable-decoder=ssa", "--enable-decoder=subrip",
        "--enable-decoder=webvtt",
        // ./configure --list-muxers
        "--disable-muxers",
        "--enable-muxer=dash", "--enable-muxer=hevc", "--enable-muxer=mp4", "--enable-muxer=m4v", "--enable-muxer=mov",
        "--enable-muxer=mpegts", "--enable-muxer=webm*",
        // ./configure --list-demuxers
        // 用所有的demuxers的话，那avformat就会达到8MB了，指定的话，那就只要4MB。
        "--disable-demuxers",
        "--enable-demuxer=aac", "--enable-demuxer=ac3", "--enable-demuxer=aiff", "--enable-demuxer=amr",
        "--enable-demuxer=ape", "--enable-demuxer=asf", "--enable-demuxer=ass", "--enable-demuxer=avi", "--enable-demuxer=caf",
        "--enable-demuxer=concat", "--enable-demuxer=dash", "--enable-demuxer=data", "--enable-demuxer=eac3",
        "--enable-demuxer=flac", "--enable-demuxer=flv", "--enable-demuxer=h264", "--enable-demuxer=hevc",
        "--enable-demuxer=hls", "--enable-demuxer=live_flv", "--enable-demuxer=loas", "--enable-demuxer=m4v",
        "--enable-demuxer=matroska", "--enable-demuxer=mov", "--enable-demuxer=mp3", "--enable-demuxer=mpeg*",
        "--enable-demuxer=ogg", "--enable-demuxer=rm", "--enable-demuxer=rtsp", "--enable-demuxer=srt",
        "--enable-demuxer=vc1", "--enable-demuxer=wav", "--enable-demuxer=webm_dash_manifest",
        // ./configure --list-protocols
        "--enable-protocols",
        "--disable-protocol=bluray", "--disable-protocol=ffrtmpcrypt", "--disable-protocol=gopher", "--disable-protocol=icecast",
        "--disable-protocol=librtmp*", "--disable-protocol=libssh", "--disable-protocol=md5", "--disable-protocol=mmsh",
        "--disable-protocol=mmst", "--disable-protocol=sctp", "--disable-protocol=subfile", "--disable-protocol=unix",
        // filters
        "--disable-filters",
        "--enable-filter=aformat", "--enable-filter=amix", "--enable-filter=anull", "--enable-filter=aresample",
        "--enable-filter=areverse", "--enable-filter=asetrate", "--enable-filter=atempo", "--enable-filter=atrim",
        "--enable-filter=bwdif", "--enable-filter=estdif", "--enable-filter=format", "--enable-filter=fps",
        "--enable-filter=hflip", "--enable-filter=hwdownload", "--enable-filter=hwmap", "--enable-filter=hwupload",
        "--enable-filter=idet", "--enable-filter=null",
        "--enable-filter=overlay", "--enable-filter=palettegen", "--enable-filter=paletteuse", "--enable-filter=pan",
        "--enable-filter=rotate", "--enable-filter=scale", "--enable-filter=setpts", "--enable-filter=transpose",
        "--enable-filter=trim", "--enable-filter=vflip", "--enable-filter=volume", "--enable-filter=w3fdif",
        "--enable-filter=yadif", "--enable-filter=yadif_videotoolbox",
    ]
}

private class BuildOpenSSL: BaseBuild {
    init() {
        super.init(library: .openssl)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        super.arguments(platform: platform, arch: arch) +
            [
                arch == .x86_64 ? "darwin64-x86_64" : arch == .arm64e ? "iphoneos-cross" : "darwin64-arm64",
                "no-async", "no-shared", "no-dso", "no-engine", "no-tests",
            ]
    }
}

private class BuildSRT: BaseBuild {
    init() {
        super.init(library: .srt)
    }

    override func buildALL() throws {
        if Utility.shell("which cmake") == nil {
            Utility.shell("brew install cmake")
        }
        if Utility.shell("which wget") == nil {
            Utility.shell("brew install wget")
        }
        try super.buildALL()
    }
}

private class BuildFribidi: BaseBuild {
    init() {
        super.init(library: .fribidi)
    }

    override func modifyMakefile(url: URL) {
        // DISABLE BUILDING OF doc FOLDER (doc depends on c2man which is not available on all platforms)
        if let data = FileManager.default.contents(atPath: url.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: " doc ", with: " ")
            try? str.write(toFile: url.path, atomically: true, encoding: .utf8)
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        super.arguments(platform: platform, arch: arch) +
            [
                "--with-sysroot=\(platform.isysroot())",
                "--disable-fast-install",
                "--disable-debug",
                "--disable-deprecated",
                "--enable-static",
                "--with-pic",
                "--disable-shared",
                "--disable-dependency-tracking",
                "--host=\(platform.host(arch: arch))",
            ]
    }
}

private class BuildASS: BaseBuild {
    init() {
        super.init(library: .libass)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        let asmOptions = platform == .maccatalyst || arch == .x86_64 ? "--disable-asm" : "--enable-asm"
        return super.arguments(platform: platform, arch: arch) +
            [
                "--with-sysroot=\(platform.isysroot())",
                "--disable-libtool-lock",
                "--disable-fontconfig",
                "--disable-require-system-font-provider",
                "--disable-fast-install",
                "--disable-test",
                "--disable-profile",
                "--disable-coretext",
                "--enable-static",
                "--with-pic",
                "--disable-shared",
                "--disable-dependency-tracking",
                "--host=\(platform.host(arch: arch))",
//                asmOptions,
//                todo
                "--disable-asm",
            ]
    }
}

private class BuildHarfbuzz: BaseBuild {
    init() {
        super.init(library: .harfbuzz)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        super.arguments(platform: platform, arch: arch) +
            [
                "--with-sysroot=\(platform.isysroot())",
                "--with-glib=no",
                "--disable-fast-install",
                "--with-freetype=no",
                "--with-pic",
                "--enable-static",
                "--disable-shared",
                "--disable-dependency-tracking",
                "--with-directwrite=no",
                "--host=\(platform.host(arch: arch))",
            ]
    }
}

private class BuildMPV: BaseBuild {
    init() {
        super.init(library: .mpv)
    }

    override func buildALL() throws {
        let path = directoryURL + "wscript_build.py"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of:
                """
                "osdep/subprocess-posix.c",            "posix"
                """, with:
                """
                "osdep/subprocess-posix.c",            "posix && !tvos"
                """)
            try str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
        try super.buildALL()
    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        let url = scratch(platform: platform, arch: arch)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        let environ = environment(platform: platform, arch: arch)
        try Utility.launch(path: (directoryURL + "bootstrap.py").path, arguments: [], currentDirectoryURL: directoryURL)
        try Utility.launch(path: "/usr/bin/python3", arguments: [(directoryURL + "waf").path, "distclean"], currentDirectoryURL: directoryURL, environment: environ)
        try Utility.launch(path: "/usr/bin/python3", arguments: [(directoryURL + "waf").path, "configure"] + arguments(platform: platform, arch: arch), currentDirectoryURL: directoryURL, environment: environ)
        try Utility.launch(path: "/usr/bin/python3", arguments: [(directoryURL + "waf").path, "build"], currentDirectoryURL: directoryURL, environment: environ)
        try Utility.launch(path: "/usr/bin/python3", arguments: [(directoryURL + "waf").path, "install"], currentDirectoryURL: directoryURL, environment: environ)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        super.arguments(platform: platform, arch: arch) +
            [
                "--disable-cplayer",
                "--disable-lcms2",
                "--disable-lua",
                "--disable-rubberband",
                "--disable-zimg",
                "--enable-libmpv-static",
                "--disable-gl",
                "--disable-javascript",
                "--disable-libbluray",
                "--disable-vapoursynth",
//                "--swift",
                "--enable-lgpl",
            ]
    }

    override func architectures(_ platform: PlatformType) -> [ArchType] {
        if platform == .macos {
            return [.x86_64]
        } else {
            return super.architectures(platform)
        }
    }
}

private enum PlatformType: String, CaseIterable {
    case ios, isimulator, tvos, tvsimulator, macos, maccatalyst
    var minVersion: String {
        switch self {
        case .ios, .isimulator:
            return "13.0"
        case .tvos, .tvsimulator:
            return "13.0"
        case .macos:
            return "10.15"
        case .maccatalyst:
            return "13.0"
        }
    }

    func architectures() -> [ArchType] {
        switch self {
        case .ios:
            return [.arm64, .arm64e]
        case .tvos:
            return [.arm64]
        case .isimulator, .tvsimulator:
            return [.arm64, .x86_64]
        case .macos:
            return [.arm64, .x86_64]
        case .maccatalyst:
            return [.arm64, .x86_64]
        }
    }

    func deploymentTarget(_ arch: ArchType) -> String {
        switch self {
        case .ios:
            return "-mios-version-min=\(minVersion)"
        case .isimulator:
            return "-mios-simulator-version-min=\(minVersion)"
        case .tvos:
            return "-mtvos-version-min=\(minVersion)"
        case .tvsimulator:
            return "-mtvos-simulator-version-min=\(minVersion)"
        case .macos:
            return "-mmacosx-version-min=\(minVersion)"
        case .maccatalyst:
            return arch == .x86_64 ? "-target x86_64-apple-ios-macabi" : "-target arm64-apple-ios-macabi"
        }
    }

    func sdk() -> String {
        switch self {
        case .ios:
            return "iPhoneOS"
        case .isimulator:
            return "iPhoneSimulator"
        case .tvos:
            return "AppleTVOS"
        case .tvsimulator:
            return "AppleTVSimulator"
        case .macos:
            return "MacOSX"
        case .maccatalyst:
            return "MacOSX"
        }
    }

    func isysroot() -> String {
        try! Utility.launch(path: "/usr/bin/xcrun", arguments: ["--sdk", sdk().lowercased(), "--show-sdk-path"], isOutput: true)
    }

    func host(arch: ArchType) -> String {
        switch self {
        case .ios, .isimulator, .maccatalyst:
            return "\(arch == .x86_64 ? "x86_64" : "arm64")-ios-darwin"
        case .tvos, .tvsimulator:
            return "\(arch == .x86_64 ? "x86_64" : "arm64")-tvos-darwin"
        case .macos:
            return "\(arch == .x86_64 ? "x86_64" : "arm64")-apple-darwin"
        }
    }
}

enum ArchType: String, CaseIterable {
    // swiftlint:disable identifier_name
    case arm64, x86_64, arm64e
    // swiftlint:enable identifier_name
    func executable() -> Bool {
        guard let architecture = Bundle.main.executableArchitectures?.first?.intValue else {
            return false
        }
        #if os(macOS)
        if #available(iOS 14.0, tvOS 14.0, macOS 11.0, *) {
            if architecture == NSBundleExecutableArchitectureARM64, self == .arm64 {
                return true
            }
        }
        #endif
        if architecture == NSBundleExecutableArchitectureX86_64, self == .x86_64 {
            return true
        }
        return false
    }

    func arch() -> String {
        switch self {
        case .arm64, .arm64e:
            return "aarch64"
        case .x86_64:
            return "x86_64"
        }
    }

    func cpu() -> String {
        switch self {
        case .arm64:
            return "--cpu=armv8"
        case .x86_64:
            return "--cpu=x86_64"
        case .arm64e:
            return "--cpu=armv8.3-a"
        }
    }
}

enum Utility {
    @discardableResult
    static func shell(_ command: String, isOutput _: Bool = false, currentDirectoryURL: URL? = nil, environment: [String: String] = [:]) -> String? {
        try? launch(path: "/bin/zsh", arguments: ["-c", command], currentDirectoryURL: currentDirectoryURL, environment: environment)
    }

    @discardableResult
    static func launch(path: String, arguments: [String], isOutput: Bool = false, currentDirectoryURL: URL? = nil, environment: [String: String] = [:]) throws -> String {
        #if os(macOS)
        let task = Process()
        task.environment = environment
        task.currentDirectoryURL = currentDirectoryURL
        let pipe = Pipe()
        //        task.standardError = pipe
        if isOutput {
            task.standardOutput = pipe
        }
        task.arguments = arguments
        task.executableURL = URL(fileURLWithPath: path)
        print(path + " " + arguments.joined(separator: " "))
        task.launch()
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            if isOutput {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
            } else {
                return ""
            }
        } else {
            throw NSError(domain: "fail", code: Int(task.terminationStatus))
        }
        #else
        return ""
        #endif
    }
}

extension URL {
    static var currentDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    static func + (left: URL, right: String) -> URL {
        var url = left
        url.appendPathComponent(right)
        return url
    }

    static func + (left: URL, right: [String]) -> URL {
        var url = left
        right.forEach {
            url.appendPathComponent($0)
        }
        return url
    }
}
