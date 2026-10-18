# Swift implementation behavior and current coverage

`FreeDEdit` is a native AppKit document editor built with `NSDocument`, `NSTextView`, and `NSAttributedString`. It includes File, Edit, Format, View, Window, and Help menus, a formatting toolbar, native find plus a dedicated find-and-replace panel, a two-section Settings window, undo support, and rich/plain conversion. New documents now use the saved rich/plain preference both at launch and from File > New. The Open panel exposes encoding selection, an option to ignore rich-text commands, and multi-selection; the Save panel exposes plain-text encodings.

The editor uses the system attributed-string readers and writers for RTF, HTML, RTFD, Apple web archive, Word 97, Word 2003 XML, Word Open XML, and ODT. Plain text checks a selected encoding first, then UTF-8, UTF-16 variants, and MacRoman; invalid UTF-8 is used as a final replacement fallback. RTFD uses AppKit file-wrapper APIs and preserves attachment payloads in the verified authored fixture.

## Verified behavior

- `swift build` and the production app-bundle build complete. The bundle build now signs the copied executable so macOS code-signature validation allows launch.
- The app launches as a native macOS document editor. Its formatting toolbar and Open panel controls are visible in Accessibility state.
- AppKit `NSAttributedString` read/write probes succeeded for the authored RTF, HTML, web archive, DOC, DOCX, WordML, and ODT fixtures. These API probes show that the system text engine accepts and emits each document type; they do not establish full app-level fidelity.
- FreeDEdit opened TextEdit's saved RTFD package, displayed its attachment and surrounding text, and wrote another RTFD package that TextEdit reopened with the same attachment payload.
- TextEdit opened the authored DOCX fixture in the UI and saved a separate DOCX copy. Extracted text from source and output matched; the output remained DOCX and its serialized bytes differed from the source.
- TextEdit's scripted differential run can save ordinary RTF, HTML, and plain-text fixtures. App Sandbox access prompts prevent the unattended script from opening RTFD and some office/web-archive inputs; those need UI-driven file selection.

## Newly implemented paths

- Find and Replace has its own panel with forward/backward search, optional case matching, single replacement, and grouped Replace All undo.
- Open accepts multiple selected files and processes them sequentially so the selected encoding and source-display options apply to each document.
- When `PreserveWhitespace` is enabled, HTML export encodes repeated, leading, and trailing spaces and tabs in text nodes so browsers retain them. Disable the setting to use the serializer's original whitespace.

These paths compile, but still need interactive comparison against TextEdit for exact menu behavior, replacement formatting, document error handling, and HTML whitespace edge cases.

## Printing, recovery, and richer rich text

- Print now creates an `NSPrintOperation` from the active text view with fit-to-page-width and automatic vertical pagination. PDF export uses the same print settings and writes a multipage PDF through a Save panel.
- The app opts into secure AppKit state restoration. Document windows save their frame, selection, and vertical scroll position; saved documents use `NSDocument` in-place autosaving.
- Rich-text editing now applies native `NSTextList` bullets or numbering to selected paragraphs, can remove list formatting, creates tables with user-selected dimensions up to 20 by 20, and can attach multiple files in one action. Existing RTFD read/write remains backed by AppKit file wrappers.

These changes compile, but printing/PDF pagination, restoration across relaunch, and RTFD round trips for complex lists/tables/multiple attachments still need end-to-end comparison on macOS.

## Settings stored by this implementation

The controls use the app's own defaults domain. Values do not modify `com.apple.TextEdit` preferences. A missing value uses the default shown here.

| Preference | Type | Default | Effect |
| --- | --- | --- | --- |
| `DefaultRichText` | Boolean | true | Starts new documents in rich text when true and plain text when false. |
| `WrapToPage` | Boolean | false | Gives new text containers a fixed page-like width when enabled. |
| `ShowRuler` | Boolean | true | Shows the ruler for new rich-text documents and after switching to rich text. |
| `CheckSpellingAsYouType` | Boolean | true | Enables continuous spelling checks in new documents. |
| `CheckGrammarWithSpelling` | Boolean | false | Enables grammar checks in new documents. |
| `CorrectSpellingAutomatically` | Boolean | true | Enables automatic spelling correction in new documents. |
| `SmartQuotes` | Boolean | true | Enables automatic quote substitution in new documents. |
| `SmartDashes` | Boolean | true | Enables automatic dash substitution in new documents. |
| `SmartLinks` | Boolean | false | Enables automatic link detection in new documents. |
| `TextReplacement` | Boolean | true | Enables system text replacements in new documents. |
| `DataDetectors` | Boolean | false | Enables automatic data detection in new documents. |
| `SmartCopyPaste` | Boolean | true | Enables smart insertion/deletion behavior in new documents. |
| `WidthInChars` | Integer | 96 | Approximate initial plain-text window width. |
| `HeightInChars` | Integer | 30 | Approximate initial plain-text window height. |
| `DefaultPlainFont`, `DefaultPlainSize` | String, integer | Menlo, 11 | Plain-text font and size for new documents. |
| `DefaultRichFont`, `DefaultRichSize` | String, integer | Helvetica, 12 | Rich-text font and size for new documents. |
| `PlainTextEncoding` | Integer | Automatic | Preferred encoding for plain-text import. |
| `PlainTextEncodingForWrite` | Integer | UTF-8 | Encoding selected by default in the plain-text save accessory. |
| `IgnoreRichText`, `IgnoreHTML` | Boolean | false | Opens RTF or HTML source as plain text when enabled. |
| `AddExtensionToNewPlainTextFiles` | Boolean | true | Adds `.txt` to a plain-text Save As name when it has no extension. |
| `PreserveWhitespace` | Boolean | true | Preserves repeated, leading, and trailing spaces and tabs in HTML text during export. |
| `UseTransitionalDocType`, `UseXHTMLDocType` | Boolean | false / false | Selects HTML 4.01 Strict, HTML 4.01 Transitional, XHTML 1.0 Strict, or XHTML 1.0 Transitional output. |
| `HTMLExportEncoding` | String | Unicode (UTF-8) | Sets the encoding used for HTML output. |

## Remaining parity work

This is a working editor, not a 1:1 TextEdit replacement. The current comparison does not cover document versions, full restoration of prior windows and unsaved documents, TextEdit's first-run and default window states, all menu enablement and shortcuts, exact toolbar customization, exact font and page metrics, all encoding fallback cases, complex RTFD layout fidelity, or malformed-document recovery. Printing, PDF pagination, state restoration, and richer RTFD content have implementation paths but still need end-to-end comparison. DOC/ODT/WordML/web-archive behavior has not been fully measured in the running TextEdit app. Plain-text dimensions are pixel approximations based on character and line counts. The settings UI and menu wording are approximations and the app uses its own preference domain. XHTML output and whitespace preservation still need broad document validation.
