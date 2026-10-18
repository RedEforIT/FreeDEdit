# Swift implementation behavior and current coverage

`FreeDEdit` is a native AppKit document editor built with `NSDocument`, `NSTextView`, and `NSAttributedString`. It includes File, Edit, Format, View, Window, and Help menus, a formatting toolbar, native find plus a dedicated find-and-replace panel, a two-section Settings window, undo support, and rich/plain conversion. New documents now use the saved rich/plain preference both at launch and from File > New. The Open panel exposes encoding selection, an option to ignore rich-text commands, and multi-selection; the Save panel exposes plain-text encodings.

The editor uses the system attributed-string readers and writers for RTF, HTML, RTFD, Apple web archive, Word 97, Word 2003 XML, Word Open XML, and ODT. Plain text checks a selected encoding first, then BOM-aware Unicode detection, valid UTF-8, and MacRoman for unmarked legacy bytes; invalid UTF-8 is used as a final replacement fallback. Windows-1252 remains an explicit encoding choice to avoid guessing incorrectly when its byte stream is ambiguous with MacRoman. RTFD uses AppKit file-wrapper APIs and preserves attachment payloads in the verified authored fixture.

## Verified behavior

- `swift build` and the production app-bundle build complete. The bundle build now signs the copied executable so macOS code-signature validation allows launch.
- The app launches as a native macOS document editor. Its formatting toolbar and Open panel controls are visible in Accessibility state.
- **Interactive macOS check (2026-10-18):** rebuilt and launched the app, opened the RTF and WordML corpus files through the Open panel, and confirmed WordML now opens in the app with its fixture text. In an unsaved RTF session, Bold, Italic, Underline, and Strikethrough toolbar buttons changed the selected text and updated their accessibility state; Undo restored the pre-change formatting for each action. The test edits were discarded and the corpus RTF fixture was restored.
- **Interactive menu/conversion check:** the rich-text Format menu exposes Bold, Italic, Underline, and alignment actions as enabled with an editable rich-text document active. Make Rich Text/Make Plain Text converted the document and correctly hid/restored the formatting toolbar; plain-text style actions were disabled. Prevent Editing disabled text input and rich-text style actions. The menus still need comparison with TextEdit for exact validation states.
- **Session restoration check:** System Settings > Desktop & Dock > Windows has “When enabled, open documents and windows will not be restored when you re-open an application” turned on. After quitting FreeDEdit with a saved temporary document open, macOS relaunched it with a fresh Untitled window. This matches the system preference; it does not verify restoration when that preference is off. The user preference was left unchanged. Apple documents that macOS removes preserved state when configured to close app windows at quit ([`NSDocument.restoreState(with:)`](https://developer.apple.com/documentation/appkit/nsdocument/restorestate%28with%3A%29)).
- **First-run launch check (2026-10-18):** rebuilt and relaunched the app with no open documents. It now presents the native Open panel with its accessory options expanded, plus New Document and Settings actions. New Document opened a fresh Untitled window; Settings opened the existing Settings window. Initial panel location and exact geometry remain un-compared with TextEdit.
- **Rich/plain shortcut check (2026-10-18):** TextEdit uses one Format menu item that changes between Make Plain Text and Make Rich Text; Shift-Command-T toggles either way, while Command-T opens Fonts. FreeDEdit now uses a single dynamically titled toggle item with an explicit Shift-Command-T modifier mask. A direct AppKit probe showed uppercase `keyEquivalent` alone does not add Shift to the modifier mask. Mac UI checks confirmed FreeDEdit hides the rich-text toolbar after switching to plain text, restores it when switching back, and still opens Fonts with Command-T.
- **Select Line menu check (2026-10-18):** TextEdit's Edit > Find submenu exposes Select Line. FreeDEdit now uses the same text-system action; on temporary two-line text, invoking it selected only the current line.
- **Undo menu check (2026-10-18):** FreeDEdit's Edit menu now reads undo/redo action names from the text view's undo manager and disables unavailable actions. On a temporary edit, the menu showed Undo Typing, then after undo showed Redo Typing; the text content changed as expected.
- **Delete menu check (2026-10-18):** FreeDEdit now exposes Edit > Delete and disables it with no selection or when editing is locked. In the Mac UI it became enabled after selecting the temporary two-line test text, removed the selection, and left the document empty.
- **Selection-based menu state check (2026-10-18):** With no selection, FreeDEdit disables Cut, Copy, Delete, and Use Selection for Find. Selecting all in a restored RTF document enabled those commands; the test only changed selection and caret position, not document contents.
- **Conversion undo/redo check (2026-10-18):** In an isolated test copy of the production app, Shift-Command-T switched a blank document to plain text and showed Undo Make Plain Text. Undo restored rich mode and the toolbar; Redo Make Plain Text switched back and hid the toolbar. The test copy used a distinct bundle identifier and did not touch the restored user document.
- **Paste and Match Style menu check (2026-10-18):** Added the native `NSTextView.pasteAsPlainText:` action used for TextEdit's Paste and Match Style command. The AppKit selector is present on this macOS version. The live clipboard was left untouched, so paste behavior with actual clipboard payloads still needs a dedicated fixture-based comparison.
- **Highlight menu implementation (2026-10-18):** Format > Highlight offers Accent, Purple, Pink, Orange, Mint, and Blue for a selected range in editable rich text. FreeDEdit applies a translucent attributed-string background color and registers formatting undo. On the isolated Mac test document, Purple produced a visible purple background after the selection was collapsed. AppKit's semantic `NSTextView.highlight(_:)` action did not visibly render in this TextKit 1 editor, so this remains a visual/rich-text approximation; TextKit 2 highlight semantics and exact TextEdit color/serialization behavior remain unverified.
- **Copy/Paste Style implementation (2026-10-18):** Format now exposes AppKit's native `copyFont:` and `pasteFont:` actions. Copy Style is enabled only for a selection in rich text; Paste Style requires editable rich text. These actions use AppKit's system style pasteboard. Exact TextEdit style coverage, pasteboard interoperability, and undo grouping still need interactive comparison.
- **Copy/Paste Ruler implementation (2026-10-18):** Format now exposes AppKit's native `copyRuler:` and `pasteRuler:` actions for rich-text paragraph formatting. Copy Ruler is disabled in plain text; Paste Ruler also requires editing to be enabled. Clipboard interoperability, paragraph coverage, and undo behavior still need interactive comparison.
- **Baseline formatting implementation (2026-10-18):** Format > Baseline now routes Raise Baseline and Lower Baseline to `NSTextView`'s native actions, enabled for selected text in editable rich text. Exact step size, menu placement, and undo grouping still need live comparison with TextEdit.
- **Outline formatting implementation (2026-10-18):** Format now exposes the native `NSTextView.outline(_:)` action for selected text in editable rich text. Its rendered appearance, export/round-trip support, and undo behavior still need comparison with TextEdit.
- **Writing direction implementation (2026-10-18):** Format > Writing Direction offers Natural, Left to Right, and Right to Left via AppKit's native `NSResponder` actions for editable rich-text documents. Paragraph direction effects, mixed-direction selection behavior, and saved-format round trips still need live comparison.
- **Kerning implementation (2026-10-18):** Format > Kerning now exposes standard, tighten, loosen, and none choices through native `NSTextView` actions. The choices are enabled in editable rich text; glyph spacing, selection/caret application, and undo behavior need live comparison.
- **Ligatures implementation (2026-10-18):** Format > Ligatures now exposes standard, all, and none choices through native `NSTextView` actions for editable rich text. Font-specific rendering, caret versus selection behavior, and undo need live comparison.
- **Script formatting implementation (2026-10-18):** Format > Script now exposes native Subscript and Superscript actions for editable rich text. Baseline/size changes, caret behavior, and undo grouping need comparison with TextEdit.
- **Earlier interactive import checks:** FreeDEdit opened the authored RTF, DOC, DOCX, ODT, HTML, web archive, RTFD, UTF-16LE, and MacRoman fixtures. The MacRoman fixture displayed `café — naïve` after automatic fallback was changed. These checks establish successful opening and basic displayed content only, not full formatting or round-trip parity.
- AppKit `NSAttributedString` read/write probes succeeded for the authored RTF, HTML, web archive, DOC, DOCX, WordML, and ODT fixtures. These API probes show that the system text engine accepts and emits each document type; they do not establish full app-level fidelity.
- FreeDEdit opened TextEdit's saved RTFD package, displayed its attachment and surrounding text, and wrote another RTFD package that TextEdit reopened with the same attachment payload.
- TextEdit opened the authored DOCX fixture in the UI and saved a separate DOCX copy. Extracted text from source and output matched; the output remained DOCX and its serialized bytes differed from the source.
- TextEdit's scripted differential run can save ordinary RTF, HTML, and plain-text fixtures. App Sandbox access prompts prevent the unattended script from opening RTFD and some office/web-archive inputs; those need UI-driven file selection.

## Newly implemented paths

- Find and Replace has its own panel with forward/backward search, optional case matching, single replacement, and grouped Replace All undo.
- Open accepts multiple selected files and processes them sequentially so the selected encoding and source-display options apply to each document.
- When `PreserveWhitespace` is enabled, HTML export encodes repeated, leading, and trailing spaces and tabs in text nodes so browsers retain them. Disable the setting to use the serializer's original whitespace.

These paths compile. The checks above cover toolbar style toggles and their undo, but exact menu behavior, replacement formatting, document error handling, and HTML whitespace edge cases still need interactive comparison against TextEdit.

## Printing, recovery, and richer rich text

- Print now creates an `NSPrintOperation` from the active text view with fit-to-page-width and automatic vertical pagination. PDF export uses the same print settings and writes a multipage PDF through a Save panel.
- The app opts into secure AppKit state restoration. Document windows save their frame, selection, and vertical scroll position; saved documents use `NSDocument` in-place autosaving.
- Rich-text editing now applies native `NSTextList` bullets or numbering to selected paragraphs, can remove list formatting, creates tables with user-selected dimensions up to 20 by 20, and can attach multiple files in one action. Existing RTFD read/write remains backed by AppKit file wrappers.
- The formatting toolbar now hides for plain-text documents and returns after conversion to rich text. It includes font, style, size, color, alignment, list, and line-spacing controls; these are functional approximations and still need comparison with TextEdit's toolbar layout, state display, and exact paragraph metrics.

These changes compile, but printing/PDF pagination, restoration with the macOS close-windows preference turned off, and RTFD round trips for complex lists/tables/multiple attachments still need end-to-end comparison on macOS.

## Saved document versions

- `TextDocument` explicitly enables AppKit version preservation, and File > Browse All Versions opens the system document version browser. The item is managed by `NSDocument`, so documents without a saved URL or version history are disabled by AppKit.
- Version creation and restore behavior depend on the destination file system and require a saved document. The system browser still needs an interactive check with local files and autosaved edits.

## Recovering damaged rich-text files

- When RTF, RTFD, or HTML import fails, the Open flow offers to reopen readable source text. For RTFD packages it extracts the primary `TXT.rtf` member when available; embedded object data and formatting are not restored in this recovery view.
- Other unreadable formats continue to show the original AppKit error. The fallback is user-selected and never silently replaces the rich-text view.

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
| `PlainTextEncoding` | Integer | Automatic | Preferred encoding for plain-text import; supports Unicode, Western and Central European, Cyrillic, Greek, Turkish, Hebrew, Arabic, Baltic, Vietnamese, Thai, Japanese, Chinese, and Korean encodings. Automatic import checks Unicode BOMs, valid UTF-8, and UTF-16/32 zero-byte patterns, then falls back to MacRoman for unmarked legacy bytes. Windows-1252 remains available as an explicit choice because its bytes can be ambiguous with MacRoman. |
| `PlainTextEncodingForWrite` | Integer | UTF-8 | Encoding selected by default in the plain-text save accessory; uses the same explicit encoding choices as import except Automatic. |
| `IgnoreRichText`, `IgnoreHTML` | Boolean | false | Opens RTF or HTML source as plain text when enabled. |
| `AddExtensionToNewPlainTextFiles` | Boolean | true | Adds `.txt` to a plain-text Save As name when it has no extension. |
| `PreserveWhitespace` | Boolean | true | Preserves repeated, leading, and trailing spaces and tabs in HTML text during export. |
| `UseTransitionalDocType`, `UseXHTMLDocType` | Boolean | false / false | Selects HTML 4.01 Strict, HTML 4.01 Transitional, XHTML 1.0 Strict, or XHTML 1.0 Transitional output. |
| `HTMLExportEncoding` | String | Unicode (UTF-8) | Sets the encoding used for HTML output. |

## Remaining parity work

FreeDEdit is a working editor, not a 1:1 TextEdit replacement. The items below are the remaining gaps based on the current implementation and observations. “Compare” means the feature exists but its behavior has not been checked closely enough against TextEdit; “Implement” means additional behavior is still needed.

### Highest-priority interactive comparisons

- **Session restoration — Compare:** Relaunch with multiple saved documents, unsaved documents, and autosaved edits while the macOS “close windows when quitting” preference is off. Verify which windows reopen, document contents, window frames, selection, scroll position, and behavior when individual documents fail to restore. The current Mac has that preference enabled, so macOS deliberately discards restoration state; the app's restoration path still needs an end-to-end run under the opposite setting.
- **First-run and launch behavior — Compare:** Initial launch now presents the Open panel with New Document and Settings actions; both actions were confirmed on the Mac. Compare its default location, exact dimensions and accessory placement with TextEdit. Test launch with restored documents when macOS session restoration is enabled.
- **Menus and shortcuts — Compare / Implement:** Rich/plain conversion now uses TextEdit's single dynamic menu item and Shift-Command-T toggle; Command-T continues to open Fonts. Compare remaining menu commands, key equivalents, and enabled states with no selection, selected text, plain text, rich text, and protected editing.
- **Formatting toolbar and ruler — Compare / Implement:** The toolbar now hides for plain text and has font, style, size, color, alignment, list, and line-spacing controls. Compare item order, customization, control state feedback, available styles, ruler measurements, and formatting effects; adjust remaining layout and behavior differences.
- **Text layout and defaults — Compare / Implement:** Compare rich and plain font defaults, window dimensions, page width, margins, wrapping, ruler units, paragraph spacing, and pagination. Plain-text window dimensions are currently pixel approximations derived from character and line counts.
- **Printing and PDF — Compare:** Compare print-panel options, page setup, scaling, margins, headers/footers, page breaks, and multipage PDF output for both plain and rich documents. Current printing uses AppKit print operations with fit-to-width and automatic vertical pagination.
- **Saved versions — Compare:** With a saved local document, create edits, browse versions, restore an older version, and verify dirty state and saved contents. Version browsing delegates to AppKit and depends on the file system and saved-document history.

### Format and content fidelity

- **RTFD — Compare / Implement:** Round-trip documents containing multiple attachments, lists, tables, links, mixed fonts and colors, and large images. Compare attachment payloads, placement, sizing, wrapping, and surrounding paragraph formatting. Existing checks cover a simple attachment fixture, not complex layouts.
- **Office and web formats — Compare / Implement:** Compare DOC, DOCX, WordML, ODT, HTML, and Apple web archive imports and exports for text, styles, tables, images, links, metadata, and unsupported features. The WordML corpus fixture now opens through the app's explicit WordML document path; AppKit acceptance and basic text extraction do not establish TextEdit-level fidelity.
- **Malformed-document recovery — Implement / Compare:** Exercise damaged RTF, RTFD, and HTML files and add recoverable paths for other formats where possible. Current source recovery applies to RTF/RTFD/HTML; it does not restore rich formatting or embedded objects from recovered source.
- **HTML and XHTML — Compare:** Validate strict/transitional and XHTML output, charset declarations, embedded CSS, whitespace preservation, entities, and browser rendering across representative documents. Current options exist, but broad output validation remains outstanding.
- **Plain-text encodings — Compare:** Explicit import/export choices cover common Unicode, Windows, and Asian encodings. Automatic legacy fallback prefers MacRoman to match the observed MacRoman fixture; Windows-1252 remains explicit because the byte streams overlap. Compare other ambiguous legacy inputs with TextEdit and verify that unsupported characters produce a clear save error instead of silent substitution or fallback.

The settings window and some menu labels remain approximations, and FreeDEdit uses its own preferences domain rather than TextEdit's. Close parity work should be driven by repeatable side-by-side checks on the same fixtures and document states; system-backed format support alone does not establish matching behavior.
