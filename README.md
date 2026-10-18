# FreeDEdit

A clean-room Swift and AppKit text editor inspired by macOS TextEdit. It supports editable plain and rich text, native find/replace, formatting controls, common text document formats, and preferences for new documents.

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
- `research/` — clean-room observation and format-probing scripts.

This is an independent implementation using public macOS APIs. It is not a complete 1:1 replacement for Apple TextEdit; see [spec/SWIFT-IMPLEMENTATION.md](spec/SWIFT-IMPLEMENTATION.md) for current coverage and known gaps.
