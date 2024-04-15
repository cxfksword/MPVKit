import Foundation

do {
    try BuildFFmpeg.performCommand(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    print(error.localizedDescription)
    exit(0)
}

private enum Library: String, CaseIterable {
    case FFmpeg, libfontconfig, libunibreak, libfreetype, libfribidi, libharfbuzz, libass, libpng, libbluray, libmpv, openssl, libsrt, libsmbclient, gnutls, gmp, nettle, libbrotli, libuchardet, readline, libglslang, libshaderc, vulkan, lcms2, libdovi, spirvcross, libplacebo, libdav1d, libzvbi, libluajit
    var version: String {
        switch self {
        case .libmpv:
            return "v0.37.0"
        case .FFmpeg:
            return "n7.0"
        case .libfontconfig:
            return "2.14.2"
        case .libunibreak:
            return "libunibreak_5_1"
        case .libfreetype:
            // VER-2-10-1以上版本需要依赖libbrotli库，或指定--with-brotli=no
            return "VER-2-12-1"
        case .libfribidi:
            return "v1.0.12"
        case .libharfbuzz:
            return "5.3.1"
        case .libass:       // depend libunibreak libfreetype libfribidi libharfbuzz
            return "0.17.1"
        case .libpng:
            return "v1.6.39"
        case .openssl:
            return "openssl-3.2.0"
        case .libsrt:
            return "v1.5.1"
        case .readline:
            return "readline-8.2"
        case .libsmbclient:
            return "samba-4.15.13"
        case .gnutls:
            return "3.8.3"
        case .nettle:
            return "nettle_3.9.1_release_20230601"
        case .gmp:
            return "v6.2.1"
        case .libbrotli:
            return "v1.0.9"
        case .libuchardet:
            return "v0.0.8"
        case .libglslang:
            return "13.1.1"
        case .libshaderc:  // compiling GLSL (OpenGL Shading Language) shaders into SPIR-V (Standard Portable Intermediate Representation - Vulkan) code
            return "v2023.8"
        case .vulkan:
            return "v1.2.8"
        case .libdovi:     // Library to read & write Dolby Vision metadata
            return "libdovi-3.3.0"
        case .lcms2:
            return "lcms2.16"
        case .spirvcross:  // parsing and converting SPIR-V to other shader languages.
            return "vulkan-sdk-1.3.268.0"
        case .libplacebo:  // depend vulkan lcms2 libdovi libshaderc, provides a powerful and flexible video rendering framework for mpv
            return "v6.338.2"
        case .libdav1d:    // AV1 decoding
            return "1.3.0"
        case .libzvbi:     // teletext support
            return "v0.2.42"
        case .libbluray:
            return "1.3.4"
        case .libluajit:
            return "v2.1"
        }
    }

    var url: String {
        switch self {
        case .libpng:
            return "https://github.com/glennrp/libpng"
        case .libmpv:
            return "https://github.com/mpv-player/mpv"
        case .libsrt:
            return "https://github.com/Haivision/srt"
        case .libsmbclient:
            return "https://github.com/samba-team/samba"
        case .nettle:
            return "https://git.lysator.liu.se/nettle/nettle"
        case .gmp:
            return "https://github.com/alisw/GMP"
        case .libbrotli:
            return "https://github.com/google/brotli"
        case .libfontconfig:
            return "https://gitlab.freedesktop.org/fontconfig/fontconfig"
        case .libuchardet:
            return "https://gitlab.freedesktop.org/uchardet/uchardet"
        case .libplacebo:
            return "https://github.com/haasn/libplacebo"
        case .vulkan:
            return "https://github.com/KhronosGroup/MoltenVK"
        case .libshaderc:
            return "https://github.com/google/shaderc"
        case .readline:
            return "https://git.savannah.gnu.org/git/readline.git"
        case .libglslang:
            return "https://github.com/KhronosGroup/glslang"
        case .libdovi:
            return "https://github.com/quietvoid/dovi_tool"
        case .lcms2:
            return "https://github.com/mm2/Little-CMS"
        case .libdav1d:
            return "https://github.com/videolan/dav1d"
        case .libzvbi:
            return "https://github.com/zapping-vbi/zvbi"
        case .libunibreak:
            return "https://github.com/adah1972/libunibreak"
        case .libass:
            return "https://github.com/libass/libass"
        case .spirvcross:
            return "https://github.com/KhronosGroup/SPIRV-Cross"
        case .libbluray:
            return "https://code.videolan.org/videolan/libbluray.git"
        case .libluajit:
            return "https://github.com/LuaJIT/LuaJIT.git"
        default:
            var value = rawValue
            if value.hasPrefix("lib") {
                value = String(value.suffix(value.count - "lib".count))
            }
            return "https://github.com/\(value)/\(value)"
        }
    }
}


enum BuildFFmpeg {
    static func performCommand(arguments: [String]) throws {
        if Utility.shell("which brew") == nil {
            print("""
            You need to run the script first
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            """)
            return
        }
        if Utility.shell("which pkg-config") == nil {
            Utility.shell("brew install pkg-config")
        }
        let path = URL.currentDirectory + "Script"
        if !FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
        }
        FileManager.default.changeCurrentDirectoryPath(path.path)
        BaseBuild.isDebug = arguments.firstIndex(of: "enable-debug") != nil
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
        if arguments.firstIndex(of: "enable-libsrt") != nil {
            try BuildSRT().buildALL()
        }
        if arguments.firstIndex(of: "enable-libass") != nil {
            // try BuildBrotli().buildALL()
            try BuildUnibreak().buildALL()
            try BuildFontconfig().buildALL()
            try BuildFreetype().buildALL()
            try BuildFribidi().buildALL()
            try BuildHarfbuzz().buildALL()
            try BuildASS().buildALL()
        }
        if arguments.firstIndex(of: "enable-libsmbclient") != nil {
            try BuildReadline().buildALL()
            try BuildGmp().buildALL()
            try BuildNettle().buildALL()
            try BuildGnutls().buildALL()
            try BuildSmbclient().buildALL()
        }
        if arguments.firstIndex(of: "enable-ffmpeg") != nil {
            // try BuildGlslang().buildALL()
            // try BuildDav1d().buildALL()
            // try BuildDovi().buildALL()
            // try BuildLittleCms().buildALL()
            // try BuildShaderc().buildALL()
            // try BuildSpirvCross().buildALL()
            // try BuildVulkan().buildALL()
            // try BuildPlacebo().buildALL()
            try BuildFFMPEG().buildALL()
        }
        if arguments.firstIndex(of: "enable-mpv") != nil {
            // try BuildUchardet().buildALL()
            // try BuildBluray().buildALL()
            // try BuildLuaJIT().buildALL()
            try BuildMPV().buildALL()
        }
    }
}

private class BaseBuild {
    static var platforms = PlatformType.allCases
    static var isDebug: Bool = false
    let library: Library
    let directoryURL: URL
    init(library: Library) {
        self.library = library
        directoryURL = URL.currentDirectory + "\(library.rawValue)-\(library.version)"

        
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            // pull code
            try! Utility.launch(path: "/usr/bin/git", arguments: ["-c", "advice.detachedHead=false", "clone", "--depth", "1", "--branch", library.version, library.url, directoryURL.path])

            // apply patch
            let patch = URL.currentDirectory + "../Plugins/BuildFFmpeg/patch/\(library.rawValue)"
            if FileManager.default.fileExists(atPath: patch.path) {
                _ = try? Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "."], currentDirectoryURL: directoryURL)
                let fileNames = try! FileManager.default.contentsOfDirectory(atPath: patch.path).sorted()
                for fileName in fileNames {
                    try! Utility.launch(path: "/usr/bin/git", arguments: ["apply", "\((patch + fileName).path)"], currentDirectoryURL: directoryURL)
                }
            }
        }
    }

    func buildALL() throws {
        try? FileManager.default.removeItem(at: URL.currentDirectory + library.rawValue)
        try? FileManager.default.removeItem(at: directoryURL.appendingPathExtension("log"))
        for platform in BaseBuild.platforms {
            for arch in architectures(platform) {
                try build(platform: platform, arch: arch)
            }
        }
        try createXCFramework()
    }

    func architectures(_ platform: PlatformType) -> [ArchType] {
        platform.architectures
    }

    func platforms() -> [PlatformType] {
        BaseBuild.platforms
    }

    func build(platform: PlatformType, arch: ArchType) throws {
        let buildURL = scratch(platform: platform, arch: arch)
        try? FileManager.default.createDirectory(at: buildURL, withIntermediateDirectories: true, attributes: nil)
        let environ = environment(platform: platform, arch: arch)
        if FileManager.default.fileExists(atPath: (directoryURL + "meson.build").path) {
            if Utility.shell("which meson") == nil {
                Utility.shell("brew install meson")
            }
            if Utility.shell("which ninja") == nil {
                Utility.shell("brew install ninja")
            }
            

            let crossFile = createMesonCrossFile(platform: platform, arch: arch)
            let meson = Utility.shell("which meson", isOutput: true)!
            try Utility.launch(path: meson, arguments: ["setup", buildURL.path, "--cross-file=\(crossFile.path)"] + arguments(platform: platform, arch: arch), currentDirectoryURL: directoryURL, environment: environ)
            try Utility.launch(path: meson, arguments: ["compile", "--clean"], currentDirectoryURL: buildURL, environment: environ)
            try Utility.launch(path: meson, arguments: ["compile", "--verbose"], currentDirectoryURL: buildURL, environment: environ)
            try Utility.launch(path: meson, arguments: ["install"], currentDirectoryURL: buildURL, environment: environ)
        } else if FileManager.default.fileExists(atPath: (directoryURL + wafPath()).path) {
            let waf = (directoryURL + wafPath()).path
            try Utility.launch(path: waf, arguments: ["configure"] + arguments(platform: platform, arch: arch), currentDirectoryURL: directoryURL, environment: environ)
            try Utility.launch(path: waf, arguments: wafBuildArg(), currentDirectoryURL: directoryURL, environment: environ)
            try Utility.launch(path: waf, arguments: ["install"] + wafInstallArg(), currentDirectoryURL: directoryURL, environment: environ)
        } else {
            try configure(buildURL: buildURL, environ: environ, platform: platform, arch: arch)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8"], currentDirectoryURL: buildURL, environment: environ)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8", "install"], currentDirectoryURL: buildURL, environment: environ)
        }
    }

    func wafPath() -> String {
        "./waf"
    }

    func wafBuildArg() -> [String] {
        ["build"]
    }

    func wafInstallArg() -> [String] {
        []
    }

    func configure(buildURL: URL, environ: [String: String], platform: PlatformType, arch: ArchType) throws {
        let autogen = directoryURL + "autogen.sh"
        if FileManager.default.fileExists(atPath: autogen.path) {
            var environ = environ
            environ["NOCONFIGURE"] = "1"
            try Utility.launch(executableURL: autogen, arguments: [], currentDirectoryURL: directoryURL, environment: environ)
        }
        let makeLists = directoryURL + "CMakeLists.txt"
        if FileManager.default.fileExists(atPath: makeLists.path) {
            if Utility.shell("which cmake") == nil {
                Utility.shell("brew install cmake")
            }
            let cmake = Utility.shell("which cmake", isOutput: true)!
            let thinDirPath = thinDir(platform: platform, arch: arch).path
            var arguments = [
                makeLists.path,
                "-DCMAKE_VERBOSE_MAKEFILE=0",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_OSX_SYSROOT=\(platform.sdk.lowercased())",
                "-DCMAKE_OSX_ARCHITECTURES=\(arch.rawValue)",
                "-DCMAKE_INSTALL_PREFIX=\(thinDirPath)",
                "-DBUILD_SHARED_LIBS=0",
            ]
            arguments.append(contentsOf: self.arguments(platform: platform, arch: arch))
            try Utility.launch(path: cmake, arguments: arguments, currentDirectoryURL: buildURL, environment: environ)
        } else {
            let configure = directoryURL + "configure"
            if !FileManager.default.fileExists(atPath: configure.path) {
                var bootstrap = directoryURL + "bootstrap"
                if !FileManager.default.fileExists(atPath: bootstrap.path) {
                    bootstrap = directoryURL + ".bootstrap"
                }
                if FileManager.default.fileExists(atPath: bootstrap.path) {
                    try Utility.launch(executableURL: bootstrap, arguments: [], currentDirectoryURL: directoryURL, environment: environ)
                }
            }
            var arguments = [
                "--prefix=\(thinDir(platform: platform, arch: arch).path)",
            ]
            arguments.append(contentsOf: self.arguments(platform: platform, arch: arch))
            try Utility.launch(executableURL: configure, arguments: arguments, currentDirectoryURL: buildURL, environment: environ)
        }
    }

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
        let cFlags = cFlags(platform: platform, arch: arch).joined(separator: " ")
        let ldFlags = ldFlags(platform: platform, arch: arch).joined(separator: " ")
        let pkgConfigPathDefault = Utility.shell("pkg-config --variable pc_path pkg-config", isOutput: true)!
        return [
            "LC_CTYPE": "C",
            "CC": "/usr/bin/clang",
            "CXX": "/usr/bin/clang++",
            // "SDKROOT": platform.sdk.lowercased(),
            "CURRENT_ARCH": arch.rawValue,
            "CFLAGS": cFlags,
            // makefile can't use CPPFLAGS
            "CPPFLAGS": cFlags,
            // 这个要加，不然cmake在编译maccatalyst 会有问题
            "CXXFLAGS": cFlags,
            "LDFLAGS": ldFlags,
            "PKG_CONFIG_LIBDIR": platform.pkgConfigPath(arch: arch) + pkgConfigPathDefault,
            "PATH": Constants.defaultPath,
        ]
    }

    func cFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var cFlags = platform.cFlags(arch: arch)
        let librarys = flagsDependencelibrarys()
        for library in librarys {
            let path = URL.currentDirectory + [library.rawValue, platform.rawValue, "thin", arch.rawValue]
            if FileManager.default.fileExists(atPath: path.path) {
                if library == .libsmbclient {
                    cFlags.append("-I\(path.path)/include/samba-4.0")
                } else {
                    cFlags.append("-I\(path.path)/include")
                }
            }
        }
        return cFlags
    }

    func ldFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var ldFlags = platform.ldFlags(arch: arch)
        let librarys = flagsDependencelibrarys()
        for library in librarys {
            let path = URL.currentDirectory + [library.rawValue, platform.rawValue, "thin", arch.rawValue]
            if FileManager.default.fileExists(atPath: path.path) {
                var libname = library.rawValue
                if libname.hasPrefix("lib") {
                    libname = String(libname.dropFirst(3))
                }
                ldFlags.append("-L\(path.path)/lib")
                ldFlags.append("-l\(libname)")
                if library == .nettle {
                    ldFlags.append("-lhogweed")
                } else if library == .gnutls {
                    ldFlags.append(contentsOf: ["-framework", "Security", "-framework", "CoreFoundation"])
                } else if library == .libsmbclient {
                    ldFlags.append(contentsOf: ["-lresolv", "-lpthread", "-lz", "-liconv"])
                }
            }
        }
        return ldFlags
    }

    func flagsDependencelibrarys() -> [Library] {
        []
    }


    func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        return []
    }

    func frameworks() throws -> [String] {
        [library.rawValue]
    }

    func createXCFramework() throws {
        var frameworks: [String] = []
        let libNames = try self.frameworks()
        for libName in libNames {
            if libName.hasPrefix("lib") {
                frameworks.append("Lib" + libName.dropFirst(3))
            } else {
                frameworks.append(libName)
            }
        }
        for framework in frameworks {
            var arguments = ["-create-xcframework"]
            for platform in BaseBuild.platforms {
                if let frameworkPath = try createFramework(framework: framework, platform: platform) {
                    arguments.append("-framework")
                    arguments.append(frameworkPath)
                }
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

    private func createFramework(framework: String, platform: PlatformType) throws -> String? {
        let frameworkDir = URL.currentDirectory + [library.rawValue, platform.rawValue, "\(framework).framework"]
        if !platforms().contains(platform) {
            if FileManager.default.fileExists(atPath: frameworkDir.path) {
                return frameworkDir.path
            } else {
                return nil
            }
        }
        try? FileManager.default.removeItem(at: frameworkDir)
        try FileManager.default.createDirectory(at: frameworkDir, withIntermediateDirectories: true, attributes: nil)
        var arguments = ["-create"]
        for arch in platform.architectures {
            let prefix = thinDir(platform: platform, arch: arch)
            if !FileManager.default.fileExists(atPath: prefix.path) {
                return nil
            }
            let libname = framework.hasPrefix("lib") || framework.hasPrefix("Lib") ? framework : "lib" + framework
            var libPath = prefix + ["lib", "\(libname).a"]
            if !FileManager.default.fileExists(atPath: libPath.path) {
                libPath = prefix + ["lib", "\(libname).dylib"]
            }
            arguments.append(libPath.path)
            var headerURL: URL = prefix + "include" + framework
            if !FileManager.default.fileExists(atPath: headerURL.path) {
                headerURL = prefix + "include"
            }
            try? FileManager.default.copyItem(at: headerURL, to: frameworkDir + "Headers")
        }
        arguments.append("-output")
        arguments.append((frameworkDir + framework).path)
        try Utility.launch(path: "/usr/bin/lipo", arguments: arguments)
        try FileManager.default.createDirectory(at: frameworkDir + "Modules", withIntermediateDirectories: true, attributes: nil)
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
        createPlist(path: frameworkDir.path + "/Info.plist", name: framework, minVersion: platform.minVersion, platform: platform.sdk)
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


    private func createMesonCrossFile(platform: PlatformType, arch: ArchType) -> URL {
        let url = scratch(platform: platform, arch: arch)
        let crossFile = url + "crossFile.meson"
        let prefix = thinDir(platform: platform, arch: arch)
        let cFlags = cFlags(platform: platform, arch: arch).map {
            "'" + $0 + "'"
        }.joined(separator: ", ")
        let ldFlags = ldFlags(platform: platform, arch: arch).map {
            "'" + $0 + "'"
        }.joined(separator: ", ")
        let content = """
        [binaries]
        c = '/usr/bin/clang'
        cpp = '/usr/bin/clang++'
        objc = '/usr/bin/clang'
        objcpp = '/usr/bin/clang++'
        ar = '\(platform.xcrunFind(tool: "ar"))'
        strip = '\(platform.xcrunFind(tool: "strip"))'
        pkg-config = 'pkg-config'

        [properties]
        has_function_printf = true
        has_function_hfkerhisadf = false

        [host_machine]
        system = 'darwin'
        subsystem = '\(platform.mesonSubSystem)'
        kernel = 'xnu'
        cpu_family = '\(arch.cpuFamily)'
        cpu = '\(arch.targetCpu)'
        endian = 'little'

        [built-in options]
        default_library = 'static'
        buildtype = 'release'
        prefix = '\(prefix.path)'
        c_args = [\(cFlags)]
        cpp_args = [\(cFlags)]
        objc_args = [\(cFlags)]
        objcpp_args = [\(cFlags)]
        c_link_args = [\(ldFlags)]
        cpp_link_args = [\(ldFlags)]
        objc_link_args = [\(ldFlags)]
        objcpp_link_args = [\(ldFlags)]
        """
        FileManager.default.createFile(atPath: crossFile.path, contents: content.data(using: .utf8), attributes: nil)
        return crossFile
    }
}

private class BuildFFMPEG: BaseBuild {
    init() {
        super.init(library: .FFmpeg)

        if Utility.shell("which nasm") == nil {
            Utility.shell("brew install nasm")
        }
        if Utility.shell("which sdl2-config") == nil {
            Utility.shell("brew install sdl2")
        }
        
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        try? FileManager.default.removeItem(at: lldbFile)
        FileManager.default.createFile(atPath: lldbFile.path, contents: nil, attributes: nil)
        // let path = directoryURL + "libavcodec/videotoolbox.c"
        // if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
        //     str = str.replacingOccurrences(of: "kCVPixelBufferOpenGLESCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
        //     str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
        //     try? str.write(toFile: path.path, atomically: true, encoding: .utf8)
        // }
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.gmp, .nettle, .gnutls, .libsmbclient]
    }

    override func frameworks() throws -> [String] {
        var frameworks: [String] = []
        if let platform = platforms().first {
            if let arch = platform.architectures.first {
                let lib = thinDir(platform: platform, arch: arch) + "lib"
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: lib.path)
                for fileName in fileNames {
                    if fileName.hasPrefix("lib"), fileName.hasSuffix(".a") {
                        // 因为其他库也可能引入libavformat,所以把lib改成大写，这样就可以排在前面，覆盖别的库。
                        frameworks.append("Lib" + fileName.dropFirst(3).dropLast(2))
                    }
                }
            }
        }
        return frameworks
    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        try super.build(platform: platform, arch: arch)
        let buildURL = scratch(platform: platform, arch: arch)
        let prefix = thinDir(platform: platform, arch: arch)
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        if let data = FileManager.default.contents(atPath: lldbFile.path), var str = String(data: data, encoding: .utf8) {
            str.append("settings \(str.isEmpty ? "set" : "append") target.source-map \((buildURL + "src").path) \(directoryURL.path)\n")
            try str.write(toFile: lldbFile.path, atomically: true, encoding: .utf8)
        }
        try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavutil/config.h")
        try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavcodec/config.h")
        try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavformat/config.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/getenv_utf8.h", to: prefix + "include/libavutil/getenv_utf8.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/libm.h", to: prefix + "include/libavutil/libm.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/thread.h", to: prefix + "include/libavutil/thread.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/intmath.h", to: prefix + "include/libavutil/intmath.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/mem_internal.h", to: prefix + "include/libavutil/mem_internal.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/attributes_internal.h", to: prefix + "include/libavutil/attributes_internal.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavcodec/mathops.h", to: prefix + "include/libavcodec/mathops.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavformat/os_support.h", to: prefix + "include/libavformat/os_support.h")
        let internalPath = prefix + "include/libavutil/internal.h"
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/internal.h", to: internalPath)
        if let data = FileManager.default.contents(atPath: internalPath.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
            #include "timer.h"
            """, with: """
            // #include "timer.h"
            """)
            str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            try str.write(toFile: internalPath.path, atomically: true, encoding: .utf8)
        }
        if platform == .macos, arch.executable {
            // // copy fftools header
            // let fftoolsFile = URL.currentDirectory + "../Sources/fftools"
            // try? FileManager.default.removeItem(at: fftoolsFile)
            // if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/compat").path) {
            //     try FileManager.default.createDirectory(at: fftoolsFile + "include/compat", withIntermediateDirectories: true)
            // }
            // try FileManager.default.copyItem(at: buildURL + "src/compat/va_copy.h", to: fftoolsFile + "include/compat/va_copy.h")
            // try FileManager.default.copyItem(at: buildURL + "config.h", to: fftoolsFile + "include/config.h")
            // try FileManager.default.copyItem(at: buildURL + "config_components.h", to: fftoolsFile + "include/config_components.h")
            // if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/libavdevice").path) {
            //     try FileManager.default.createDirectory(at: fftoolsFile + "include/libavdevice", withIntermediateDirectories: true)
            // }
            // try FileManager.default.copyItem(at: buildURL + "src/libavdevice/avdevice.h", to: fftoolsFile + "include/libavdevice/avdevice.h")
            // try FileManager.default.copyItem(at: buildURL + "src/libavdevice/version_major.h", to: fftoolsFile + "include/libavdevice/version_major.h")
            // try FileManager.default.copyItem(at: buildURL + "src/libavdevice/version.h", to: fftoolsFile + "include/libavdevice/version.h")
            // if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/libpostproc").path) {
            //     try FileManager.default.createDirectory(at: fftoolsFile + "include/libpostproc", withIntermediateDirectories: true)
            // }
            // try FileManager.default.copyItem(at: buildURL + "src/libpostproc/postprocess_internal.h", to: fftoolsFile + "include/libpostproc/postprocess_internal.h")
            // try FileManager.default.copyItem(at: buildURL + "src/libpostproc/postprocess.h", to: fftoolsFile + "include/libpostproc/postprocess.h")
            // try FileManager.default.copyItem(at: buildURL + "src/libpostproc/version_major.h", to: fftoolsFile + "include/libpostproc/version_major.h")
            // try FileManager.default.copyItem(at: buildURL + "src/libpostproc/version.h", to: fftoolsFile + "include/libpostproc/version.h")

            // // copy ffplay and ffprobe
            // let ffmpegFile = URL.currentDirectory + "../Sources/ffmpeg"
            // try? FileManager.default.removeItem(at: ffmpegFile)
            // try FileManager.default.createDirectory(at: ffmpegFile + "include", withIntermediateDirectories: true)
            // let ffplayFile = URL.currentDirectory + "../Sources/ffplay"
            // try? FileManager.default.removeItem(at: ffplayFile)
            // try FileManager.default.createDirectory(at: ffplayFile, withIntermediateDirectories: true)
            // let ffprobeFile = URL.currentDirectory + "../Sources/ffprobe"
            // try? FileManager.default.removeItem(at: ffprobeFile)
            // try FileManager.default.createDirectory(at: ffprobeFile, withIntermediateDirectories: true)
            // let fftools = buildURL + "src/fftools"
            // let fileNames = try FileManager.default.contentsOfDirectory(atPath: fftools.path)
            // for fileName in fileNames {
            //     if fileName.hasPrefix("ffplay") {
            //         try FileManager.default.copyItem(at: fftools + fileName, to: ffplayFile + fileName)
            //     } else if fileName.hasPrefix("ffprobe") {
            //         try FileManager.default.copyItem(at: fftools + fileName, to: ffprobeFile + fileName)
            //     } else if fileName.hasPrefix("ffmpeg") {
            //         if fileName.hasSuffix(".h") {
            //             try FileManager.default.copyItem(at: fftools + fileName, to: ffmpegFile + "include" + fileName)
            //         } else {
            //             try FileManager.default.copyItem(at: fftools + fileName, to: ffmpegFile + fileName)
            //         }
            //     } else if fileName.hasSuffix(".h") {
            //         try FileManager.default.copyItem(at: fftools + fileName, to: fftoolsFile + "include" + fileName)
            //     } else if fileName.hasSuffix(".c") {
            //         try FileManager.default.copyItem(at: fftools + fileName, to: fftoolsFile + fileName)
            //     }
            // }
            // let prefix = scratch(platform: platform, arch: arch)
            // try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
            // try? FileManager.default.copyItem(at: prefix + "ffmpeg", to: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
            // try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffplay"))
            // try? FileManager.default.copyItem(at: prefix + "ffplay", to: URL(fileURLWithPath: "/usr/local/bin/ffplay"))
            // try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffprobe"))
            // try? FileManager.default.copyItem(at: prefix + "ffprobe", to: URL(fileURLWithPath: "/usr/local/bin/ffprobe"))
        }
    }


    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var arguments = ffmpegConfiguers
        if BaseBuild.isDebug {
            arguments.append("--enable-debug")
            arguments.append("--disable-stripping")
            arguments.append("--disable-optimizations")
        } else {
            arguments.append("--disable-debug")
            arguments.append("--enable-stripping")
            arguments.append("--enable-optimizations")
        }
        // arguments += Build.ffmpegConfiguers
        arguments.append("--disable-large-tests")
        arguments.append("--ignore-tests=TESTS")
        arguments.append("--arch=\(arch.cpuFamily)")
        arguments.append("--target-os=darwin")
        // arguments.append(arch.cpu())

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
        if platform == .macos, arch.executable {
            arguments.append("--enable-ffplay")
            arguments.append("--enable-sdl2")
            arguments.append("--enable-decoder=rawvideo")
            arguments.append("--enable-filter=color")
            arguments.append("--enable-filter=lut")
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
        for library in [Library.gmp, .gnutls, .libsmbclient, .libfontconfig, .libfreetype, .libharfbuzz, .libfribidi, .libass, .libsrt, .vulkan, .libshaderc, .lcms2, .libplacebo, .libdav1d, .libzvbi] {
            let path = URL.currentDirectory + [library.rawValue, platform.rawValue, "thin", arch.rawValue]
            if FileManager.default.fileExists(atPath: path.path) {
                arguments.append("--enable-\(library.rawValue)")
                if library == .libsrt || library == .libsmbclient {
                    arguments.append("--enable-protocol=\(library.rawValue)")
                } else if library == .libdav1d {
                    arguments.append("--enable-decoder=\(library.rawValue)")
                } else if library == .libass {
                    arguments.append("--enable-filter=ass")
                    arguments.append("--enable-filter=subtitles")
                } else if library == .libzvbi {
                    arguments.append("--enable-decoder=libzvbi_teletext")
                } else if library == .libplacebo {
                    arguments.append("--enable-filter=libplacebo")
                }
            }
        }
        
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
        "--disable-armv5te", "--disable-armv6", "--disable-armv6t2",
        "--disable-bzlib", "--disable-gray", "--disable-iconv", "--disable-linux-perf",
        "--disable-shared", "--disable-small", "--disable-swscale-alpha", "--disable-symver", "--disable-xlib",
        "--enable-cross-compile", "--enable-gpl", "--enable-libxml2", "--enable-nonfree",
        "--enable-optimizations", "--enable-pic", "--enable-runtime-cpudetect", "--enable-static", "--enable-thumb", "--enable-version3",
        "--pkg-config-flags=--static",
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
        // Individual component options:
        // ,"--disable-everything"
        // ./configure --list-muxers
        "--disable-muxers",
        "--enable-muxer=flac", "--enable-muxer=dash", "--enable-muxer=hevc",
        "--enable-muxer=m4v", "--enable-muxer=matroska", "--enable-muxer=mov", "--enable-muxer=mp4",
        "--enable-muxer=mpegts", "--enable-muxer=webm*",
        // ./configure --list-encoders
        "--disable-encoders",
        "--enable-encoder=aac", "--enable-encoder=alac", "--enable-encoder=flac", "--enable-encoder=pcm*",
        "--enable-encoder=movtext", "--enable-encoder=mpeg4", "--enable-encoder=h264_videotoolbox",
        "--enable-encoder=hevc_videotoolbox", "--enable-encoder=prores", "--enable-encoder=prores_videotoolbox",
        // ./configure --list-protocols
        "--enable-protocols",
        // ./configure --list-demuxers
        // 用所有的demuxers的话，那avformat就会达到8MB了，指定的话，那就只要4MB。
        "--disable-demuxers",
        "--enable-demuxer=aac", "--enable-demuxer=ac3", "--enable-demuxer=aiff", "--enable-demuxer=amr",
        "--enable-demuxer=ape", "--enable-demuxer=asf", "--enable-demuxer=ass", "--enable-demuxer=av1",
        "--enable-demuxer=avi", "--enable-demuxer=caf", "--enable-demuxer=concat",
        "--enable-demuxer=dash", "--enable-demuxer=data", "--enable-demuxer=dv",
        "--enable-demuxer=eac3",
        "--enable-demuxer=flac", "--enable-demuxer=flv", "--enable-demuxer=h264", "--enable-demuxer=hevc",
        "--enable-demuxer=hls", "--enable-demuxer=live_flv", "--enable-demuxer=loas", "--enable-demuxer=m4v",
        // matroska=mkv,mka,mks,mk3d
        "--enable-demuxer=matroska", "--enable-demuxer=mov", "--enable-demuxer=mp3", "--enable-demuxer=mpeg*",
        "--enable-demuxer=ogg", "--enable-demuxer=rm", "--enable-demuxer=rtsp", "--enable-demuxer=rtp",
        "--enable-demuxer=srt", "--enable-demuxer=webvtt",
        "--enable-demuxer=vc1", "--enable-demuxer=wav", "--enable-demuxer=webm_dash_manifest",
        // ./configure --list-bsfs
        "--enable-bsfs",
        // ./configure --list-decoders
        // 用所有的decoders的话，那avcodec就会达到40MB了，指定的话，那就只要20MB。
        "--disable-decoders",
        // 视频
        "--enable-decoder=av1", "--enable-decoder=dca", "--enable-decoder=dxv",
        "--enable-decoder=ffv1", "--enable-decoder=ffvhuff", "--enable-decoder=flv",
        "--enable-decoder=h263", "--enable-decoder=h263i", "--enable-decoder=h263p", "--enable-decoder=h264",
        "--enable-decoder=hap", "--enable-decoder=hevc", "--enable-decoder=huffyuv",
        "--enable-decoder=indeo5",
        "--enable-decoder=mjpeg", "--enable-decoder=mjpegb", "--enable-decoder=mpeg*", "--enable-decoder=mts2",
        "--enable-decoder=prores",
        "--enable-decoder=mpeg4", "--enable-decoder=mpegvideo",
        "--enable-decoder=rv10", "--enable-decoder=rv20", "--enable-decoder=rv30", "--enable-decoder=rv40",
        "--enable-decoder=snow", "--enable-decoder=svq3",
        "--enable-decoder=tscc", "--enable-decoder=txd",
        "--enable-decoder=wmv1", "--enable-decoder=wmv2", "--enable-decoder=wmv3",
        "--enable-decoder=vc1", "--enable-decoder=vp6", "--enable-decoder=vp6a", "--enable-decoder=vp6f",
        "--enable-decoder=vp7", "--enable-decoder=vp8", "--enable-decoder=vp9",
        // 音频
        "--enable-decoder=aac*", "--enable-decoder=ac3*", "--enable-decoder=adpcm*", "--enable-decoder=alac*",
        "--enable-decoder=amr*", "--enable-decoder=ape", "--enable-decoder=cook",
        "--enable-decoder=dca", "--enable-decoder=dolby_e", "--enable-decoder=eac3*", "--enable-decoder=flac",
        "--enable-decoder=mp1*", "--enable-decoder=mp2*", "--enable-decoder=mp3*", "--enable-decoder=opus",
        "--enable-decoder=pcm*", "--enable-decoder=sonic",
        "--enable-decoder=truehd", "--enable-decoder=tta", "--enable-decoder=vorbis", "--enable-decoder=wma*",
        // 字幕
        "--enable-decoder=ass", "--enable-decoder=ccaption", "--enable-decoder=dvbsub", "--enable-decoder=dvdsub",
        "--enable-decoder=mpl2", "--enable-decoder=movtext",
        "--enable-decoder=pgssub", "--enable-decoder=srt", "--enable-decoder=ssa", "--enable-decoder=subrip",
        "--enable-decoder=xsub", "--enable-decoder=webvtt",

        // ./configure --list-filters
        "--disable-filters",
        "--enable-filter=aformat", "--enable-filter=amix", "--enable-filter=anull", "--enable-filter=aresample",
        "--enable-filter=areverse", "--enable-filter=asetrate", "--enable-filter=atempo", "--enable-filter=atrim",
        "--enable-filter=bwdif", "--enable-filter=delogo",
        "--enable-filter=equalizer", "--enable-filter=estdif",
        "--enable-filter=firequalizer", "--enable-filter=format", "--enable-filter=fps",
        "--enable-filter=hflip", "--enable-filter=hwdownload", "--enable-filter=hwmap", "--enable-filter=hwupload",
        "--enable-filter=idet", "--enable-filter=lenscorrection", "--enable-filter=lut*", "--enable-filter=negate", "--enable-filter=null",
        "--enable-filter=overlay",
        "--enable-filter=palettegen", "--enable-filter=paletteuse", "--enable-filter=pan",
        "--enable-filter=rotate",
        "--enable-filter=scale", "--enable-filter=setpts", "--enable-filter=superequalizer",
        "--enable-filter=transpose", "--enable-filter=trim",
        "--enable-filter=vflip", "--enable-filter=volume",
        "--enable-filter=w3fdif",
        "--enable-filter=yadif",
        "--enable-filter=avgblur_vulkan", "--enable-filter=blend_vulkan", "--enable-filter=bwdif_vulkan",
        "--enable-filter=chromaber_vulkan", "--enable-filter=flip_vulkan", "--enable-filter=gblur_vulkan",
        "--enable-filter=hflip_vulkan", "--enable-filter=nlmeans_vulkan", "--enable-filter=overlay_vulkan",
        "--enable-filter=vflip_vulkan", "--enable-filter=xfade_vulkan",
    ]
}

private class BuildOpenSSL: BaseBuild {
    init() {
        super.init(library: .openssl)
    }

    override func frameworks() throws -> [String] {
        ["libssl", "libcrypto"]
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        let array = [
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
            "no-async", "no-shared", "no-dso", "no-engine", "no-tests",
            arch == .x86_64 ? "darwin64-x86_64" : arch == .arm64e ? "iphoneos-cross" : "darwin64-arm64",
        ]
        // if [PlatformType.tvos, .tvsimulator, .watchos, .watchsimulator].contains(platform) {
        //     array.append("-DHAVE_FORK=0")
        // }
        return array
    }
}

private class BuildSmbclient: BaseBuild {
    let heimdalUrl = "https://github.com/heimdal/heimdal.git"
    let heimdalVersion = "heimdal-7.8.0"

    init() {
        // // if use brew version python, you will need to install python-setuptools for distutils dependency error
        // if Utility.shell("brew list python-setuptools") == nil {
        //     Utility.shell("brew install python-setuptools")
        // }

        // install setuptools for distutils dependency
        if Utility.shell("python -m pip list|grep setuptools") == nil {
            Utility.shell("python -m pip install setuptools")
        }

        // To cross compile samba, need to build asn1_compile and compile_et first 
        if Utility.shell("which asn1_compile") == nil || Utility.shell("which compile_et") == nil {
            if Utility.shell("which makeinfo") == nil {
                Utility.shell("brew install texinfo")
            }

            let heimdalDirectoryURL = URL.currentDirectory + "\(heimdalVersion)"
            if !FileManager.default.fileExists(atPath: heimdalDirectoryURL.path) {
                try! Utility.launch(path: "/usr/bin/git", arguments: ["-c", "advice.detachedHead=false", "clone", "--depth", "1", "--branch", heimdalVersion, heimdalUrl, heimdalDirectoryURL.path])
            }
            let heimdalPrefix = heimdalDirectoryURL + "buildtools"
            let asn1URL = heimdalPrefix + "libexec/heimdal/asn1_compile"
            if !FileManager.default.fileExists(atPath: asn1URL.path) {
                let autogen = heimdalDirectoryURL + "autogen.sh"
                try! Utility.launch(executableURL: autogen, arguments: [], currentDirectoryURL: heimdalDirectoryURL)
                let configure = heimdalDirectoryURL + "configure"
                let arguments = [
                    "--prefix=\(heimdalPrefix.path)",
                ]
                try! Utility.launch(executableURL: configure, arguments: arguments, currentDirectoryURL: heimdalDirectoryURL)
                try! Utility.launch(path: "/usr/bin/make", arguments: ["-j8"], currentDirectoryURL: heimdalDirectoryURL)
                try! Utility.launch(path: "/usr/bin/make", arguments: ["-j8", "install"], currentDirectoryURL: heimdalDirectoryURL)
            }
        }


        super.init(library: .libsmbclient)
    }

    override func wafPath() -> String {
        "buildtools/bin/waf"
    }

    override func cFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var cFlags = super.cFlags(platform: platform, arch: arch)
        cFlags.append("-Wno-error=implicit-function-declaration")
        return cFlags
    }

    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var env = super.environment(platform: platform, arch: arch)
        let heimdalDirectoryURL = URL.currentDirectory + "\(heimdalVersion)"
        env["PATH"] = (heimdalDirectoryURL + "buildtools/libexec/heimdal").path + ":" + (heimdalDirectoryURL + "lib/com_err").path + ":" + (directoryURL + "buildtools/bin").path + ":" + (env["PATH"] ?? "")
        env["PYTHONHASHSEED"] = "1"
        env["WAF_MAKE"] = "1"
        return env
    }

    override func wafBuildArg() -> [String] {
        ["--targets=smbclient"]
    }

    override func wafInstallArg() -> [String] {
        ["--targets=smbclient"]
    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        try super.build(platform: platform, arch: arch)
        try FileManager.default.copyItem(at: directoryURL + "bin/default/source3/libsmb/libsmbclient.a", to: thinDir(platform: platform, arch: arch) + "lib/libsmbclient.a")
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--without-cluster-support",
            "--disable-rpath",
            "--without-ldap",
            "--without-pam",
            "--enable-fhs",
            "--without-winbind",
            "--without-ads",
            "--disable-avahi",
            "--disable-cups",
            "--without-gettext",
            "--without-ad-dc",
            "--without-acl-support",
            "--without-utmp",
            "--disable-iprint",
            "--nopyc",
            "--nopyo",
            "--disable-python",
            "--disable-symbol-versions",
            "--without-json",
            "--without-libarchive",
            "--without-regedit",
            "--without-lttng",
            "--without-gpgme",
            "--disable-cephfs",
            "--disable-glusterfs",
            "--without-syslog",
            "--without-quotas",
            "--bundled-libraries=ALL",
            "--with-static-modules=!vfs_snapper,ALL",
            "--nonshared-binary=smbtorture,smbd/smbd,client/smbclient",
            "--builtin-libraries=!smbclient,!smbd_base,!smbstatus,ALL",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",

            "--cross-compile",
            "--cross-answers=cross-answers.txt",
        ]
    }
}

private class BuildReadline: BaseBuild {
    init() {
        super.init(library: .readline)
    }

    // readline 只是在编译的时候需要用到。外面不需要用到
    override func frameworks() throws -> [String] {
        []
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--enable-static",
            "--disable-shared",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
        ]
    }
}

private class BuildGmp: BaseBuild {
    init() {
        super.init(library: .gmp)
        // if Utility.shell("which makeinfo") == nil {
        //     Utility.shell("brew install texinfo")
        // }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-maintainer-mode",
            "--disable-assembly",
            "--with-pic",
            "--enable-static",
            "--disable-shared",
            "--disable-fast-install",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
        ]
    }
}
private class BuildNettle: BaseBuild {
    init() {
        if Utility.shell("which autoconf") == nil {
            Utility.shell("brew install autoconf")
        }
        super.init(library: .nettle)
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.gmp]
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-assembler",
            "--disable-openssl",
            "--disable-gcov",
            "--disable-documentation",
            "--enable-pic",
            "--enable-static",
            "--disable-shared",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
//                arch == .arm64 || arch == .arm64e ? "--enable-arm-neon" : "--enable-x86-aesni",
        ]
    }

    override func frameworks() throws -> [String] {
        [library.rawValue, "hogweed"]
    }
}

private class BuildGnutls: BaseBuild {
    init() {
        if Utility.shell("which automake") == nil {
            Utility.shell("brew install automake")
        }
        if Utility.shell("which gtkdocize") == nil {
            Utility.shell("brew install gtk-doc")
        }
        if Utility.shell("which wget") == nil {
            Utility.shell("brew install wget")
        }
        if Utility.shell("brew list bison") == nil {
            Utility.shell("brew install bison")
        }
        if Utility.shell("which glibtoolize") == nil {
            Utility.shell("brew install libtool")
        }
        if Utility.shell("which asn1Parser") == nil {
            Utility.shell("brew install libtasn1")
        }
        super.init(library: .gnutls)
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.gmp, .nettle]
    }

    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var env = super.environment(platform: platform, arch: arch)
        // 需要bison的版本大于2.4,系统自带的/usr/bin/bison是 2.3
        env["PATH"] = "/usr/local/opt/bison/bin:/opt/homebrew/opt/bison/bin:" + (env["PATH"] ?? "")
        return env
    }

    override func configure(buildURL: URL, environ: [String: String], platform: PlatformType, arch: ArchType) throws {
        try super.configure(buildURL: buildURL, environ: environ, platform: platform, arch: arch)
        let path = directoryURL + "lib/accelerated/aarch64/Makefile.in"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "AM_CCASFLAGS =", with: "#AM_CCASFLAGS=")
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--with-included-libtasn1",
            "--with-included-unistring",
            "--without-brotli",
            "--without-idn",
            "--without-p11-kit",
            "--without-zlib",
            "--without-zstd",
            "--enable-hardware-acceleration",
            "--disable-openssl-compatibility",
            "--disable-code-coverage",
            "--disable-doc",
            "--disable-maintainer-mode",
            "--disable-manpages",
            "--disable-nls",
            "--disable-rpath",
//                "--disable-tests",
            "--disable-tools",
            "--disable-full-test-suite",
            "--with-pic",
            "--enable-static",
            "--disable-shared",
            "--disable-fast-install",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
        ]
    }
}

private class BuildSRT: BaseBuild {
    init() {
        super.init(library: .libsrt)
    }

    override func arguments(platform: PlatformType, arch _: ArchType) -> [String] {
        [
            "-Wno-dev",
//            "-DUSE_ENCLIB=openssl",
            "-DUSE_ENCLIB=gnutls",
            "-DENABLE_STDCXX_SYNC=1",
            "-DENABLE_CXX11=1",
            "-DUSE_OPENSSL_PC=1",
            "-DENABLE_DEBUG=0",
            "-DENABLE_LOGGING=0",
            "-DENABLE_HEAVY_LOGGING=0",
            "-DENABLE_APPS=0",
            "-DENABLE_SHARED=0",
            platform == .maccatalyst ? "-DENABLE_MONOTONIC_CLOCK=0" : "-DENABLE_MONOTONIC_CLOCK=1",
        ]
    }
}

private class BuildFribidi: BaseBuild {
    init() {
        super.init(library: .libfribidi)
    }

    override func arguments(platform : PlatformType, arch : ArchType) -> [String] {
        [
            "-Ddeprecated=false",
            "-Ddocs=false",
            "-Dbin=false",
            "-Dtests=false",
        ]
            // [
            //     "--disable-deprecated",
            //     "--disable-debug",
            //     "--with-pic",
            //     "--enable-static",
            //     "--disable-shared",
            //     "--disable-fast-install",
            //     "--disable-dependency-tracking",
            //     "--host=\(platform.host(arch: arch))",
            //     "--prefix=\(thinDir(platform: platform, arch: arch).path)",
            // ]
    }
}

private class BuildHarfbuzz: BaseBuild {
    init() {
        super.init(library: .libharfbuzz)
    }

    override func arguments(platform : PlatformType, arch : ArchType) -> [String] {
        [
            "-Dglib=disabled",
            "-Dfreetype=disabled",
            "-Ddocs=disabled",
            "-Dtests=disabled",
        ]
            // [
            //     "--with-glib=no",
            //     "--with-freetype=no",
            //     "--with-directwrite=no",
            //     "--with-pic",
            //     "--enable-static",
            //     "--disable-shared",
            //     "--disable-fast-install",
            //     "--disable-dependency-tracking",
            //     "--host=\(platform.host(arch: arch))",
            //     "--prefix=\(thinDir(platform: platform, arch: arch).path)",
            // ]
    }
}

private class BuildUnibreak: BaseBuild {
    init() {
        super.init(library: .libunibreak)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--enable-static",
            "--disable-shared",
            "--disable-fast-install",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
        ]
    }

    // override func frameworks() throws -> [String] {
    //     // ignore generate xci framework
    //     return []
    // }
}

private class BuildFontconfig: BaseBuild {
    init() {
        super.init(library: .libfontconfig)
        // disable autogen, use cmake to build
        let path = directoryURL + "autogen.sh"
        try? FileManager.default.removeItem(at: path)
    }

    override func arguments(platform : PlatformType, arch : ArchType) -> [String] {
        [
            "-Ddoc=disabled",
            "-Ddoc-txt=disabled",
            "-Ddoc-man=disabled",
            "-Ddoc-pdf=disabled",
            "-Ddoc-html=disabled",
            "-Dtests=disabled",
            "-Dtools=disabled",
        ]
    }
}

private class BuildFreetype: BaseBuild {
    init() {
        super.init(library: .libfreetype)
    }

    override func arguments(platform : PlatformType, arch : ArchType) -> [String] {
        [
            "-Dzlib=enabled",
            "-Dharfbuzz=disabled", 
            "-Dbzip2=disabled", 
            "-Dmmap=disabled",
            "-Dpng=disabled",
            "-Dbrotli=disabled",
        ]
            // [
            //     "--with-zlib",
            //     "--without-harfbuzz",
            //     "--without-bzip2",
            //     // "--without-fsref",
            //     "--without-quickdraw-toolbox",
            //     "--without-quickdraw-carbon",
            //     // "--without-ats",
            //     "--disable-mmap",
            //     "--with-png=no",
            //     "--with-brotli=no",
            //     "--with-pic",
            //     "--enable-static",
            //     "--disable-shared",
            //     "--disable-fast-install",
            //     "--host=\(platform.host(arch: arch))",
            //     "--prefix=\(thinDir(platform: platform, arch: arch).path)",
            // ]
    }
}


private class BuildBrotli: BaseBuild {
    init() {
        super.init(library: .libbrotli)
    }

    override func arguments(platform : PlatformType, arch : ArchType) -> [String] {
            [
                "--enable-static",
                "--disable-shared",
                "--host=\(platform.host(arch: arch))",
                "--prefix=\(thinDir(platform: platform, arch: arch).path)",
            ]
    }

    override func buildALL() throws {
        let configure = directoryURL + "configure"
        try? FileManager.default.removeItem(at: configure)

        try super.buildALL()
    }

    override func configure(buildURL: URL, environ: [String: String], platform: PlatformType, arch: ArchType) throws {
        let configure = directoryURL + "configure"
        let bootstrap = directoryURL + "bootstrap"
        if !FileManager.default.fileExists(atPath: configure.path), FileManager.default.fileExists(atPath: bootstrap.path) {
            Utility.shell("./bootstrap", isOutput: true, currentDirectoryURL: directoryURL, environment: environ)
        }

        try super.configure(buildURL: buildURL, environ: environ, platform: platform, arch: arch)
    }
}

private class BuildPng: BaseBuild {
    init() {
        super.init(library: .libpng)
        let path = directoryURL + "autogen.sh"
        try? FileManager.default.removeItem(at: path)
    }

    override func arguments(platform : PlatformType, arch : ArchType) -> [String] {
        ["-DPNG_HARDWARE_OPTIMIZATIONS=yes"]
    }

}


private class BuildASS: BaseBuild {
    init() {
        super.init(library: .libass)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        let result =
            [
                "--disable-libtool-lock",
                // "--disable-fontconfig",
                // "--disable-require-system-font-provider",
                "--disable-test",
                "--disable-profile",
                "--disable-directwrite",
                // "--disable-coretext",
                "--disable-asm",  // TODO: enable will make ffmpeg build fail
                "--with-pic",
                // "--disable-libunibreak",  // TODO: enable libunibreak may improves performance
                "--enable-static",
                "--disable-shared",
                "--disable-fast-install",
                "--disable-dependency-tracking",
                "--host=\(platform.host(arch: arch))",
            ]
        // if arch != .x86_64 {
        //     result.append("--disable-asm")
        // }
        return result
    }
}

private class BuildBluray: BaseBuild {
    init() {
        super.init(library: .libbluray)

        Utility.shell("git submodule update --init --recursive", currentDirectoryURL: directoryURL)
    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        // 依赖DiskArbitration框架，只能macos下使用，不然提示缺少DiskArbitration/DADisk.h
        if platform != .macos && platform != .maccatalyst {
            return
        }
        try super.build(platform: platform, arch: arch)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--without-external-libudfread",
            "--disable-doxygen-doc",
            "--disable-doxygen-dot",
            "--disable-doxygen-html",
            "--disable-doxygen-ps",
            "--disable-doxygen-pdf",
            "--disable-examples",
            "--disable-bdjava-jar",
            "--with-pic",
            "--enable-static",
            "--disable-shared",
            "--disable-fast-install",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
        ]
    }
}

private class BuildLuaJIT: BaseBuild {
    init() {
        super.init(library: .libluajit)

        // remove ABI version, xcframework with ABIVER can't build in swift 5.7.*
        let makefile = directoryURL + "Makefile"
        if let data = FileManager.default.contents(atPath: makefile.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "-$(ABIVER)", with: "")
            try! str.write(toFile: makefile.path, atomically: true, encoding: .utf8)
        }
        let srcmakefile = directoryURL + "src/Makefile"
        if let data = FileManager.default.contents(atPath: srcmakefile.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "-$(ABIVER)", with: "")
            try! str.write(toFile: srcmakefile.path, atomically: true, encoding: .utf8)
        }
        let pcfile = directoryURL + "etc/luajit.pc"
        if let data = FileManager.default.contents(atPath: pcfile.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "-${abiver}", with: "")
            try! str.write(toFile: pcfile.path, atomically: true, encoding: .utf8)
        }

    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        // maccatalyst暂时不支持
        if platform == .maccatalyst {
            return
        }
        let buildURL = scratch(platform: platform, arch: arch)
        try? FileManager.default.createDirectory(at: buildURL, withIntermediateDirectories: true, attributes: nil)
        var environ = [String: String]()
        var arguments = [
            "PREFIX=\(thinDir(platform: platform, arch: arch).path)"
        ]

        if platform == .macos {
            environ["MACOSX_DEPLOYMENT_TARGET"] = "10.15"
            arguments += [
                "TARGET_CFLAGS=--target=\(arch.rawValue)-apple-darwin",
                "TARGET_LDFLAGS=--target=\(arch.rawValue)-apple-darwin",
                "HOST_CFLAGS=--target=x86_64-apple-darwin",
                "HOST_LDFLAGS=--target=x86_64-apple-darwin",
            ]
        } else {
            environ["TARGET_FLAGS"] = "-arch \(arch.rawValue) -isysroot \(platform.isysroot)"
            arguments += [
                "DEFAULT_CC=clang",
                "CROSS=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/",
                "TARGET_SYS=iOS",
            ]
        }
        
        try Utility.launch(path: "/usr/bin/make", arguments: ["clean"] + arguments, currentDirectoryURL: directoryURL, environment: environ)
        try Utility.launch(path: "/usr/bin/make", arguments: ["-j8"] + arguments, currentDirectoryURL: directoryURL, environment: environ)
        try Utility.launch(path: "/usr/bin/make", arguments: ["-j8", "install"] + arguments, currentDirectoryURL:  directoryURL, environment: environ)
    }

    override func frameworks() throws -> [String] {
        ["libluajit"]
    }
}


private class BuildUchardet: BaseBuild {
    init() {
        super.init(library: .libuchardet)
    }
}

private class BuildGlslang: BaseBuild {
    init() {
        super.init(library: .libglslang)
        try! Utility.launch(executableURL: directoryURL + "./update_glslang_sources.py", arguments: [], currentDirectoryURL: directoryURL)
        var path = directoryURL + "External/spirv-tools/tools/reduce/reduce.cpp"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
              int res = std::system(nullptr);
              return res != 0;
            """, with: """
              FILE* fp = popen(nullptr, "r");
              return fp == NULL;
            """)
            str = str.replacingOccurrences(of: """
              int status = std::system(command.c_str());
            """, with: """
              FILE* fp = popen(command.c_str(), "r");
            """)
            str = str.replacingOccurrences(of: """
              return status == 0;
            """, with: """
              return fp != NULL;
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
        path = directoryURL + "External/spirv-tools/tools/fuzz/fuzz.cpp"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
              int res = std::system(nullptr);
              return res != 0;
            """, with: """
              FILE* fp = popen(nullptr, "r");
              return fp == NULL;
            """)
            str = str.replacingOccurrences(of: """
              int status = std::system(command.c_str());
            """, with: """
              FILE* fp = popen(command.c_str(), "r");
            """)
            str = str.replacingOccurrences(of: """
              return status == 0;
            """, with: """
              return fp != NULL;
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }
}

private class BuildShaderc: BaseBuild {
    init() {
        super.init(library: .libshaderc)
        try! Utility.launch(executableURL: directoryURL + "/utils/git-sync-deps", arguments: [], currentDirectoryURL: directoryURL)
        var path = directoryURL + "third_party/spirv-tools/tools/reduce/reduce.cpp"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
              int res = std::system(nullptr);
              return res != 0;
            """, with: """
              FILE* fp = popen(nullptr, "r");
              return fp == NULL;
            """)
            str = str.replacingOccurrences(of: """
              int status = std::system(command.c_str());
            """, with: """
              FILE* fp = popen(command.c_str(), "r");
            """)
            str = str.replacingOccurrences(of: """
              return status == 0;
            """, with: """
              return fp != NULL;
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
        path = directoryURL + "third_party/spirv-tools/tools/fuzz/fuzz.cpp"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
              int res = std::system(nullptr);
              return res != 0;
            """, with: """
              FILE* fp = popen(nullptr, "r");
              return fp == NULL;
            """)
            str = str.replacingOccurrences(of: """
              int status = std::system(command.c_str());
            """, with: """
              FILE* fp = popen(command.c_str(), "r");
            """)
            str = str.replacingOccurrences(of: """
              return status == 0;
            """, with: """
              return fp != NULL;
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "-DSHADERC_SKIP_TESTS=ON",
            "-DSHADERC_SKIP_EXAMPLES=ON",
            "-DSHADERC_SKIP_COPYRIGHT_CHECK=ON",
            "-DENABLE_EXCEPTIONS=ON",
            "-DENABLE_CTEST=OFF",
            "-DENABLE_GLSLANG_BINARIES=OFF",
            "-DSPIRV_SKIP_EXECUTABLES=ON",
            "-DSPIRV_TOOLS_BUILD_STATIC=ON",
            "-DBUILD_SHARED_LIBS=OFF",
        ]
    }

    override func frameworks() throws -> [String] {
        ["libshaderc_combined"]
    }
    
}

private class BuildDav1d: BaseBuild {
    init() {
        super.init(library: .libdav1d)
    }

    override func build(platform: PlatformType, arch: ArchType) throws {
        // TODO: maccatalyst平台会导致ffmpeg编译失败，暂时忽略
        if platform == .maccatalyst {
            return
        }
        try super.build(platform: platform, arch: arch)
    }

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-Denable_tests=false",
            "-Denable_tools=false", 
            "-Dxxhash_muxer=disabled",
        ]
    }
}


private class BuildLittleCms: BaseBuild {
    init() {
        super.init(library: .lcms2)
    }
}

private class BuildDovi: BaseBuild {
    init() throws {
        super.init(library: .libdovi)
    }

    override func buildALL() throws {
        // clear old build files
        try? FileManager.default.removeItem(at: URL.currentDirectory + self.library.rawValue)

        let version = self.library.version.replacingOccurrences(of: "libdovi-", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let downloadUrl = "https://github.com/cxfksword/libdovi-build/releases/download/v\(version)/libdovi-\(version).tar"
        let xcframeworkUrl = "https://github.com/cxfksword/libdovi-build/releases/download/v\(version)/Libdovi.xcframework.zip"
        let packageURL = directoryURL + "Package/"
        let releaseURL = packageURL + "Release/"
        try? FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: releaseURL)

        Utility.shell("wget \(downloadUrl) -q -O libdovi.tar", currentDirectoryURL: packageURL)
        Utility.shell("tar xvf libdovi.tar", currentDirectoryURL: packageURL)
        try? FileManager.default.moveItem(at: packageURL + "libdovi", to: releaseURL)

        Utility.shell("wget \(xcframeworkUrl) -q -O Libdovi.xcframework.zip", currentDirectoryURL: packageURL)
        Utility.shell("unzip Libdovi.xcframework.zip -d Release", currentDirectoryURL: packageURL)
        let oldXcframework = URL.currentDirectory + "../Sources/Libdovi.xcframework"
        let newXcframework = releaseURL + "Libdovi.xcframework"
        if FileManager.default.fileExists(atPath: newXcframework.path) {
            try? FileManager.default.removeItem(at: oldXcframework)
            try? FileManager.default.copyItem(at: newXcframework, to: oldXcframework)
        } else {
            throw NSError(domain: "xcframework not found", code: -1)
        }


        for platform in platforms() {
            for arch in platform.architectures {
                let path = directoryURL + "Package/Release/lib/\(platform.rawValue)/thin/\(arch.rawValue)/lib"
                if !FileManager.default.fileExists(atPath: path.path) {
                    continue
                }

                let prefix = thinDir(platform: platform, arch: arch) + "/lib/pkgconfig"
                try? FileManager.default.removeItem(at: prefix)
                try? FileManager.default.createDirectory(at: prefix, withIntermediateDirectories: true, attributes: nil)
                let pc = prefix + "dovi.pc"

                let content = """
                prefix=\((directoryURL + "Package/Release").path)
                exec_prefix=${prefix}
                libdir=${prefix}/lib/\(platform.rawValue)/thin/\(arch.rawValue)/lib
                includedir=${prefix}/include

                Name: libdovi
                Description: Dolby Vision metadata parsing and writing
                Version: \(version)
                Libs: -L${libdir} -ldovi
                Cflags: -I${includedir}
                Libs.private:  -liconv -lSystem -lobjc -framework Foundation -lc -lm
                """
                FileManager.default.createFile(atPath: pc.path, contents: content.data(using: .utf8), attributes: nil)
            }
        }
    }
}



private class BuildVulkan: BaseBuild {
    init() {
        super.init(library: .vulkan)

        // // switch to main branch, to pull newest code
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["remote", "set-branches", "--add", "origin", "main"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["fetch", "origin", "main:main"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "main"], currentDirectoryURL: directoryURL)
    }

    override func buildALL() throws {
        // // build from source code
        // let version = self.library.version.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        // var arguments = platforms().map {
        //     "--\($0.name)"
        // }
        // try Utility.launch(path: (directoryURL + "fetchDependencies").path, arguments: arguments, currentDirectoryURL: directoryURL)
        // arguments = platforms().map(\.name)
        // try Utility.launch(path: "/usr/bin/make", arguments: arguments, currentDirectoryURL: directoryURL)
        // try? FileManager.default.removeItem(at: URL.currentDirectory + "../Sources/MoltenVK.xcframework")
        // try? FileManager.default.copyItem(at: directoryURL + "Package/Release/MoltenVK/MoltenVK.xcframework", to: URL.currentDirectory + "../Sources/MoltenVK.xcframework")

        // compile is very slow, change to use github action build xciframework
        let version = self.library.version.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let downloadUrl = "https://github.com/KhronosGroup/MoltenVK/releases/download/v\(version)/MoltenVK-all.tar"
        let packageURL = directoryURL + "Package/"
        let releaseURL = packageURL + "Release/"
        try? FileManager.default.removeItem(at: releaseURL)
        try? FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        Utility.shell("wget \(downloadUrl) -q -O MoltenVK-all.tar", currentDirectoryURL: packageURL)
        Utility.shell("tar xvf MoltenVK-all.tar", currentDirectoryURL: packageURL)
        try? FileManager.default.moveItem(at: packageURL + "MoltenVK", to: releaseURL)
        let oldXcframework = URL.currentDirectory + "../Sources/MoltenVK.xcframework"
        let newXcframework = releaseURL + "MoltenVK/static/MoltenVK.xcframework"
        if FileManager.default.fileExists(atPath: newXcframework.path) {
            try? FileManager.default.removeItem(at: oldXcframework)
            try? FileManager.default.copyItem(at: newXcframework, to: oldXcframework)
        } else {
            throw NSError(domain: "xcframework not found", code: -1)
        }

        for platform in platforms() {
            var frameworks = ["CoreFoundation", "CoreGraphics", "Foundation", "IOSurface", "Metal", "QuartzCore"]
            if platform == .macos {
                frameworks.append("Cocoa")
            } 
            if platform != .macos {
                frameworks.append("UIKit")
            }
            if !(platform == .tvos || platform == .tvsimulator) {
                frameworks.append("IOKit")
            }
            let libframework = frameworks.map {
                "-framework \($0)"
            }.joined(separator: " ")
            for arch in platform.architectures {
                let prefix = thinDir(platform: platform, arch: arch) + "/lib/pkgconfig"
                try? FileManager.default.removeItem(at: prefix)
                try? FileManager.default.createDirectory(at: prefix, withIntermediateDirectories: true, attributes: nil)
                let vulkanPC = prefix + "vulkan.pc"

                let content = """
                prefix=\((directoryURL + "Package/Release/MoltenVK").path)
                includedir=${prefix}/include
                libdir=${prefix}/static/MoltenVK.xcframework/\(platform.frameworkName)

                Name: Vulkan-Loader
                Description: Vulkan Loader
                Version: \(version)
                Libs: -L${libdir} -lMoltenVK \(libframework)
                Cflags: -I${includedir}
                """
                FileManager.default.createFile(atPath: vulkanPC.path, contents: content.data(using: .utf8), attributes: nil)
            }
        }
    }
}


private class BuildSpirvCross: BaseBuild {
    init() {
        super.init(library: .spirvcross)
    }


    override func build(platform: PlatformType, arch: ArchType) throws {
        try super.build(platform: platform, arch: arch)

        let prefix = thinDir(platform: platform, arch: arch)
        let version = self.library.version.replacingOccurrences(of: "vulkan-sdk-", with: "").replacingOccurrences(of: "sdk-", with: "")
        let pcDir = prefix + "/lib/pkgconfig"
        try? FileManager.default.removeItem(at: pcDir)
        try? FileManager.default.createDirectory(at: pcDir, withIntermediateDirectories: true, attributes: nil)
        let pc = pcDir + "spirv-cross-c-shared.pc"

        let content = """
        prefix=\(prefix.path)
        exec_prefix=${prefix}
        includedir=${prefix}/include/spirv_cross
        libdir=${prefix}/lib

        Name: spirv-cross-c-shared
        Description: C API for SPIRV-Cross
        Version: \(version)
        Libs: -L${libdir} -lspirv-cross-c -lspirv-cross-glsl -lspirv-cross-hlsl -lspirv-cross-reflect -lspirv-cross-msl -lspirv-cross-util -lspirv-cross-core -lstdc++
        Cflags: -I${includedir}
        """
        FileManager.default.createFile(atPath: pc.path, contents: content.data(using: .utf8), attributes: nil)
    }

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-DSPIRV_CROSS_SHARED=OFF",
            "-DSPIRV_CROSS_STATIC=ON", 
            "-DSPIRV_CROSS_CLI=OFF", 
            "-DSPIRV_CROSS_ENABLE_TESTS=OFF",
            "-DSPIRV_CROSS_FORCE_PIC=ON", 
            "-Ddemos=false-DSPIRV_CROSS_ENABLE_CPP=OFF"
        ]
    }

    override func frameworks() throws -> [String] {
        // ignore generate xci framework
        return []
    }
}

private class BuildPlacebo: BaseBuild {
    init() {
        super.init(library: .libplacebo)
        
        // // switch to master branch, to pull newest code
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["remote", "set-branches", "--add", "origin", "master"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["fetch", "origin", "master:master"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "master"], currentDirectoryURL: directoryURL)

        // pull all submodules
        Utility.shell("git submodule update --init --recursive", currentDirectoryURL: directoryURL)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var args = ["-Dxxhash=disabled", "-Dunwind=disabled", "-Dglslang=disabled",  "-Ddemos=false"]

        let path = URL.currentDirectory + [Library.libdovi.rawValue, platform.rawValue, "thin", arch.rawValue]
        if FileManager.default.fileExists(atPath: path.path) {
            args += ["-Ddovi=enabled", "-Dlibdovi=enabled"]
        } else {
            args += ["-Ddovi=disabled", "-Dlibdovi=disabled"]
        }
        return args
    }
}

private class BuildMPV: BaseBuild {
    init() {
        super.init(library: .libmpv)
 
        let path = directoryURL + "meson.build"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "# ffmpeg", with: """
            add_languages('objc')
            #ffmpeg
            """)
            str = str.replacingOccurrences(of: """
            subprocess_source = files('osdep/subprocess-posix.c')
            """, with: """
            if host_machine.subsystem() == 'tvos' or host_machine.subsystem() == 'tvos-simulator'
                subprocess_source = files('osdep/subprocess-dummy.c')
            else
                subprocess_source =files('osdep/subprocess-posix.c')
            endif
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }

        // TODO: can delete after mpv 0.7.1
        let lavfi = directoryURL + "filters/f_lavfi.c"
        if let data = FileManager.default.contents(atPath: lavfi.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "AV_OPT_TYPE_CHANNEL_LAYOUT", with: "AV_OPT_TYPE_CHLAYOUT")
            try? str.write(toFile: lavfi.path, atomically: true, encoding: .utf8)
        }
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.gmp, .libsmbclient]
    }


    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var array = [
            "-Dlibmpv=true",
            "-Dgl=enabled",
            "-Dplain-gl=enabled",
            "-Diconv=enabled",
            "-Duchardet=enabled",
            "-Dvulkan=enabled",
            "-Dmoltenvk=enabled",  // from patch option

            "-Djavascript=disabled",
            "-Dzimg=disabled",
            "-Djpeg=disabled",
            "-Dvapoursynth=disabled",
            "-Drubberband=disabled",
        ]
        let blurayLibPath = URL.currentDirectory + [Library.libbluray.rawValue, platform.rawValue, "thin", arch.rawValue]
        if FileManager.default.fileExists(atPath: blurayLibPath.path) {
            array.append("-Dlibbluray=enabled")
        } else {
            array.append("-Dlibbluray=disabled")
        }
        if !(platform == .macos && arch.executable) {
            array.append("-Dcplayer=false")
        }
        if platform == .macos {
            array.append("-Dswift-flags=-sdk \(platform.isysroot) -target \(platform.deploymentTarget(arch))")
            array.append("-Dcocoa=enabled")
            array.append("-Dcoreaudio=enabled")
            array.append("-Dgl-cocoa=enabled")
            array.append("-Dvideotoolbox-gl=enabled")
            array.append("-Dlua=luajit")  // macos show video stats need enable 
        } else {
            array.append("-Dvideotoolbox-gl=disabled")
            array.append("-Dswift-build=disabled")
            array.append("-Daudiounit=enabled")
            array.append("-Dlua=disabled")
            if platform == .maccatalyst {
                array.append("-Dcocoa=disabled")
                array.append("-Dcoreaudio=disabled")
            } else {
                array.append("-Dios-gl=enabled")
            }
        }
        return array
    }

    override func buildALL() throws {
        try super.buildALL()

        // copy headers
        let includeSourceDirectory = URL.currentDirectory + "../Sources/Libmpv.xcframework/ios-arm64/Libmpv.framework/Headers/mpv"
        let includeDestDirectory = URL.currentDirectory + "../Sources/MPVKit/include"
        print("Copy libmpv headers to path: \(includeDestDirectory.path)")
        try? FileManager.default.removeItem(at: includeDestDirectory)
        try? FileManager.default.copyItem(at: includeSourceDirectory, to: includeDestDirectory)
    }

    // override func build(platform: PlatformType, arch: ArchType) throws {
    //     if platform != .macos {
    //         return
    //     }
    //     try super.build(platform: platform, arch: arch)
    // }
}

private enum PlatformType: String, CaseIterable {
    case maccatalyst, macos, isimulator, tvsimulator, ios, tvos
    var minVersion: String {
        switch self {
        case .ios, .isimulator:
            return "13.0"
        case .tvos, .tvsimulator:
            return "13.0"
        case .macos:
            return "10.15"
        case .maccatalyst:
            // return "14.0"
            return ""
        }
    }

    var name: String {
        switch self {
        case .ios, .tvos, .macos:
            return rawValue
        case .tvsimulator:
            return "tvossim"
        case .isimulator:
            return "iossim"
        case .maccatalyst:
            return "maccat"
        }
    }

    var frameworkName: String {
        switch self {
        case .ios:
            return "ios-arm64"
        case .maccatalyst:
            return "ios-arm64_x86_64-maccatalyst"
        case .isimulator:
            return "ios-arm64_x86_64-simulator"
        case .macos:
            return "macos-arm64_x86_64"
        case .tvos:
            // 保持和xcode一致：https://github.com/KhronosGroup/MoltenVK/issues/431#issuecomment-771137085
            return "tvos-arm64_arm64e"
        case .tvsimulator:
            return "tvos-arm64_x86_64-simulator"
        }
    }


    var architectures: [ArchType] {
        switch self {
        case .ios:
            return [.arm64]
        case .tvos:
            return [.arm64, .arm64e]
        case .isimulator, .tvsimulator:
            return [.arm64, .x86_64]
        case .macos:
            // macos 不能用arm64，不然打包release包会报错，不能通过
            #if arch(x86_64)
            return [.x86_64, .arm64]
            #else
            return [.arm64, .x86_64]
            #endif
        case .maccatalyst:
            return [.arm64, .x86_64]
        }
    }

    fileprivate func deploymentTarget(_ arch: ArchType) -> String {
        switch self {
        case .ios, .tvos, .macos:
            return "\(arch.targetCpu)-apple-\(rawValue)\(minVersion)"
        case .maccatalyst:
            return "\(arch.targetCpu)-apple-ios-macabi"
        case .isimulator:
            return PlatformType.ios.deploymentTarget(arch) + "-simulator"
        case .tvsimulator:
            return PlatformType.tvos.deploymentTarget(arch) + "-simulator"
        // case .watchsimulator:
        //     return PlatformType.watchos.deploymentTarget(arch) + "-simulator"
        // case .xrsimulator:
        //     return PlatformType.xros.deploymentTarget(arch) + "-simulator"
        }
    }


    private var osVersionMin: String {
        switch self {
        case .ios, .tvos:
            return "-m\(rawValue)-version-min=\(minVersion)"
        case .macos:
            return "-mmacosx-version-min=\(minVersion)"
        case .isimulator:
            return "-mios-simulator-version-min=\(minVersion)"
        case .tvsimulator:
            return "-mtvos-simulator-version-min=\(minVersion)"
        case .maccatalyst:
            return ""
            // return "-miphoneos-version-min=\(minVersion)"
        }
    }

    var sdk : String {
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

    var isysroot: String {
        xcrunFind(tool: "--show-sdk-path")
    }

    var mesonSubSystem: String {
        switch self {
        case .isimulator:
            return "ios-simulator"
        case .tvsimulator:
            return "tvos-simulator"
        // case .xrsimulator:
        //     return "xros-simulator"
        // case .watchsimulator:
        //     return "watchos-simulator"
        default:
            return rawValue
        }
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

    func ldFlags(arch: ArchType) -> [String] {
        // ldFlags的关键参数要跟cFlags保持一致，不然会在ld的时候不通过。
        var flags = ["-lc++", "-arch", arch.rawValue, "-isysroot", isysroot, "-target", deploymentTarget(arch), osVersionMin]
        // maccatalyst的vulkan库需要加载UIKit框架
        if self == .maccatalyst {
            flags += ["-iframework", "\(isysroot)/System/iOSSupport/System/Library/Frameworks"]
        }
        return flags
    }


    func cFlags(arch: ArchType) -> [String] {
        var cflags = ["-arch", arch.rawValue, "-isysroot", isysroot, "-target", deploymentTarget(arch), osVersionMin]
//        if self == .macos || self == .maccatalyst {
        // 不能同时有强符合和弱符号出现
        // cflags.append("-fno-common")
//        }
        if self == .tvos || self == .tvsimulator {
            cflags.append("-DHAVE_FORK=0")
        }
        return cflags
    }

    func xcrunFind(tool: String) -> String {
        try! Utility.launch(path: "/usr/bin/xcrun", arguments: ["--sdk", sdk.lowercased(), "--find", tool], isOutput: true)
    }

    func pkgConfigPath(arch: ArchType) -> String {
        var pkgConfigPath = ""
        for lib in Library.allCases {
            let path = URL.currentDirectory + [lib.rawValue, rawValue, "thin", arch.rawValue]
            if FileManager.default.fileExists(atPath: path.path) {
                pkgConfigPath += "\(path.path)/lib/pkgconfig:"
            }
        }
        return pkgConfigPath
    }
}

enum ArchType: String, CaseIterable {
    // swiftlint:disable identifier_name
    case arm64, x86_64, arm64e
    // swiftlint:enable identifier_name
    var executable: Bool {
        guard let architecture = Bundle.main.executableArchitectures?.first?.intValue else {
            return false
        }
        // NSBundleExecutableArchitectureARM64
        if architecture == 0x0100_000C, self == .arm64 {
            return true
        } else if architecture == NSBundleExecutableArchitectureX86_64, self == .x86_64 {
            return true
        }
        return false
    }

    var cpuFamily: String {
        switch self {
        case .arm64, .arm64e:
            return "aarch64"
        case .x86_64:
            return "x86_64"
        }
    }

    var targetCpu: String {
        switch self {
        case .arm64, .arm64e:
            return "arm64"
        case .x86_64:
            return "x86_64"
        }
    }
}


private enum Constants {
    static let defaultPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
}

enum Utility {
    @discardableResult
    static func shell(_ command: String, isOutput : Bool = false, currentDirectoryURL: URL? = nil, environment: [String: String] = [:]) -> String? {
        do {
            return try launch(executableURL: URL(fileURLWithPath: "/bin/bash"), arguments: ["-c", command], isOutput: isOutput, currentDirectoryURL: currentDirectoryURL, environment: environment)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    @discardableResult
    static func launch(path: String, arguments: [String], isOutput: Bool = false, currentDirectoryURL: URL? = nil, environment: [String: String] = [:]) throws -> String {
        try launch(executableURL: URL(fileURLWithPath: path), arguments: arguments, isOutput: isOutput, currentDirectoryURL: currentDirectoryURL, environment: environment)
    }

    @discardableResult
    static func launch(executableURL: URL, arguments: [String], isOutput: Bool = false, currentDirectoryURL: URL? = nil, environment: [String: String] = [:]) throws -> String {
        #if os(macOS)
        let task = Process()
        var environment = environment
        // for homebrew 1.12
        if ProcessInfo.processInfo.environment.keys.contains("HOME") {
            environment["HOME"] = ProcessInfo.processInfo.environment["HOME"]
        }
        if !environment.keys.contains("PATH") {
            environment["PATH"] = Constants.defaultPath
        }
        task.environment = environment

        var outputFileHandle: FileHandle?
        var logURL: URL?
        var outputBuffer = Data()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        if let curURL = currentDirectoryURL {
            // output to file
            logURL = curURL.appendingPathExtension("log")
            if !FileManager.default.fileExists(atPath: logURL!.path) {
                FileManager.default.createFile(atPath: logURL!.path, contents: nil)
            }

            outputFileHandle = try FileHandle(forWritingTo: logURL!)
            outputFileHandle?.seekToEndOfFile()
        }
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData

            if !data.isEmpty {
                outputBuffer.append(data)
                if let outputString = String(data: data, encoding: .utf8) {
                    if isOutput {
                        print(outputString.trimmingCharacters(in: .newlines))
                    }

                    // Write to file simultaneously.
                    outputFileHandle?.write(data)
                }
            } else {
                // Close the read capability processing program and clean up resources.
                fileHandle.readabilityHandler = nil
                fileHandle.closeFile()
            }
        }
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData

            if !data.isEmpty {
                if let outputString = String(data: data, encoding: .utf8) {
                    print(outputString.trimmingCharacters(in: .newlines))

                    // Write to file simultaneously.
                    outputFileHandle?.write(data)
                }
            } else {
                // Close the read capability processing program and clean up resources.
                fileHandle.readabilityHandler = nil
                fileHandle.closeFile()
            }
        }
    
        task.arguments = arguments
        var log = executableURL.path + " " + arguments.joined(separator: " ") + " environment: " + environment.description
        if let currentDirectoryURL {
            log += " url: \(currentDirectoryURL)"
        }
        print(log)
        outputFileHandle?.write("\(log)\n".data(using: .utf8)!)
        task.currentDirectoryURL = currentDirectoryURL
        task.executableURL = executableURL
        try task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            if isOutput {
                let result = String(data: outputBuffer, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
                return result
            } else {
                return ""
            }
        } else {
            if let logURL = logURL {
                print("please view log file for detail: \(logURL)\n")
            }
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
