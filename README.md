# MPVKit

[![ffmpeg](https://img.shields.io/badge/ffmpeg-n6.1-blue.svg)](https://github.com/FFmpeg/FFmpeg)
[![mpv](https://img.shields.io/badge/mpv-v0.37.0-blue.svg)](https://github.com/mpv-player/mpv)
[![license](https://img.shields.io/github/license/cxfksword/MPVKit)](https://github.com/cxfksword/MPVKit/main/LICENSE)

> MPVKit is only suitable for learning `libmpv` and will not be maintained too frequently. For production purposes, [kingslay/KSPlayer](https://github.com/kingslay/KSPlayer) may be a better choice.

`MPVKit` is a collection of tools to use `mpv` in `iOS`, `macOS`, `tvOS` applications.

It includes scripts to build `mpv` native libraries.

Ported from [kingslay/FFmpegKit](https://github.com/kingslay/FFmpegKit)

## Installation

### SwiftPM

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