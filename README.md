# FreeDEdit

A Swift and AppKit text editor inspired by macOS TextEdit, built from observed behavior and public macOS APIs. It supports editable plain and rich text, native find/replace, formatting controls, common text document formats, and preferences for new documents.

## Build

Requires macOS 14 or later and Swift 6. Run:

```sh
./build-app.sh
```

This builds `FreeDEdit.app` in the project directory. `swift build` compiles the executable without creating an app bundle.

## Project contents

- `Sources/FreeDEdit/` — application source.
- `Info.plist` — app bundle metadata and document type registration.
- `spec/` — behavior survey, implementation notes, and input corpus.
- `research/` — observation and format-probing scripts.

This is an independent implementation using public macOS APIs. It was developed from observing TextEdit's behavior and metadata; no Apple code was disassembled, decompiled, or copied. It is not meant to be a 1:1 replacement for Apple TextEdit and differs from it in places by design. See [spec/SWIFT-IMPLEMENTATION.md](spec/SWIFT-IMPLEMENTATION.md) for what is implemented and the known differences.

FreeDEdit is not made by or affiliated with Apple.
