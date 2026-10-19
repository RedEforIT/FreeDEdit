# FreeDEdit

A Swift and AppKit text editor inspired by macOS TextEdit, built from observed behavior and public macOS APIs. It supports editable plain and rich text, native find/replace, formatting controls, common text document formats, and preferences for new documents.

## Installation

### macOS (Homebrew)

Install FreeDEdit using Homebrew:

```sh
brew tap homebrew/fde https://git.initstack.org/homebrew/homebrew-fde
brew install --cask freededit
```

To uninstall:

```sh
brew uninstall --cask freededit
```

## Building from source

**Requirements:** macOS 14 or later and Swift 6.

FreeDEdit uses Apple's AppKit framework, so building the complete macOS application requires a macOS build environment.

Clone the repository, enter the project directory, and run:

```sh
./build-app.sh
```

This builds `FreeDEdit.app` in the project directory.

Alternatively, run:

```sh
swift build
```

This compiles the executable without creating an app bundle.

You can edit the source code and work on platform-independent components on FreeBSD, but compiling and testing the complete AppKit application requires macOS.

## Project contents

- `Sources/FreeDEdit/` — application source.
- `Info.plist` — app bundle metadata and document type registration.
- `spec/` — behavior survey, implementation notes, and input corpus.
- `research/` — observation and format-probing scripts.

## About

This is an independent implementation using public macOS APIs. It was developed from observing TextEdit's behavior and metadata; no Apple code was disassembled, decompiled, or copied.

It is not intended to be a 1:1 replacement for Apple TextEdit and differs from it in places by design. See [spec/SWIFT-IMPLEMENTATION.md](spec/SWIFT-IMPLEMENTATION.md) for implemented features and known differences.

FreeDEdit is not made by or affiliated with Apple.