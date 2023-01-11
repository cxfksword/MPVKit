Pod::Spec.new do |s|
    s.name             = 'MPVKit'
    s.version          = '0.35.0'
    s.summary          = 'MPVKit'

    s.description      = <<-DESC
    MPVKit
    DESC

    s.homepage         = 'https://github.com/cxfksword/MPVKit'
    s.authors = { 'kintan' => '554398854@qq.com' }
    s.license          = 'MIT'
    s.source           = { :git => 'https://github.com/cxfksword/MPVKit.git', :tag => s.version.to_s }

    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    # s.watchos.deployment_target = '2.0'
    s.tvos.deployment_target = '13.0'
    s.default_subspec = 'MPVKit'
    s.static_framework = true
    s.source_files = 'Sources/MPVKit/**/*.{h,c,m}'
    s.subspec 'MPVKit' do |mpv|
        mpv.libraries   = 'bz2', 'z', 'iconv', 'xml2', 'c++'
        mpv.vendored_frameworks = 'Sources/Libmpv.xcframework','Sources/Libavcodec.xcframework','Sources/Libavfilter.xcframework','Sources/Libavformat.xcframework','Sources/Libavutil.xcframework','Sources/Libswresample.xcframework','Sources/Libswscale.xcframework','Sources/Libass.xcframework','Sources/Libfreetype.xcframework','Sources/Libfribidi.xcframework','Sources/Libharfbuzz.xcframework','Sources/Libharfbuzz-subset.xcframework'
        mpv.dependency 'OpenSSL'
    end
end
