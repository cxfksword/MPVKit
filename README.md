# MPVKit

[![mpv](https://img.shields.io/badge/mpv-v0.37.0-blue.svg)](https://github.com/mpv-player/mpv)
[![ffmpeg](https://img.shields.io/badge/ffmpeg-n6.1.1-blue.svg)](https://github.com/FFmpeg/FFmpeg)
[![license](https://img.shields.io/github/license/cxfksword/MPVKit)](https://github.com/cxfksword/MPVKit/main/LICENSE)

> MPVKit is only suitable for learning `libmpv` and will not be maintained too frequently.

`MPVKit` is a collection of tools to use `mpv` in `iOS`, `macOS`, `tvOS` applications.

It includes scripts to build `mpv` native libraries.

Ported from [kingslay/FFmpegKit](https://github.com/kingslay/FFmpegKit)

## Installation

### Swift Package Manager

```
https://github.com/cxfksword/MPVKit.git
```

## How to build

```bash
swift run build enable-openssl enable-libass enable-ffmpeg enable-mpv
```


## Run default mpv player

```bash
swift run mpv --script-opts=osc-visibility=always [url]
swift run mpv --list-options
```

> Use <kbd>Shift</kbd>+<kbd>i</kbd> to show stats overlay

## License
Because MPVKit compiles FFmpeg and mpv with the GPL license enabled. So MPVKit follow the GPL license.
