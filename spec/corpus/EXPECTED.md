# Authored corpus: observed opening and saving behavior

Observations were made with the installed TextEdit application on macOS 27.0.1. The test files were authored for this corpus. The AppleScript harness opened each supported plain/rich file and saved a separate copy to `analysis/saved-output/corpus-run3/`; RTFD was opened and saved manually because scripted access to a package directory returned a permission alert. The authored corpus files were left unchanged. The malformed RTF case was skipped by the harness because opening it presents a modal rejection alert; that alert was observed manually. `sample.rtf` was also edited in a duplicate document and saved to `analysis/saved-output/roundtrip.rtf` as a separate behavior check.

| File | Observed open behavior | Save observation |
| --- | --- | --- |
| `sample.rtf` | Opens as rich text. Bold and italic styling and paragraph breaks appear as formatted text. | Saving an unchanged copy produces valid RTF 1.0, ANSI/code page 1252, 491 bytes. An edited duplicate produced valid RTF 1.0, ANSI/code page 1252, 507 bytes; text and bold/italic styling survived. |
| `attachment.rtfd` | Opens as rich text with the “Before attachment” and “After attachment.” paragraphs surrounding an embedded attachment. | Saving a separate copy produces an RTFD package at `analysis/saved-output/textedit-rtfd-roundtrip.rtfd/` containing a 741-byte RTF body and the 51-byte attachment payload. |
| `sample.html` | Opens as formatted text rather than markup. The heading appears large and bold; emphasis and list items render as formatting. | Saving an unchanged copy produces HTML in UTF-8, 1,132 bytes. |
| `utf8.txt` | Opens as plain text and preserves the accented and CJK characters. | Saving produces UTF-8 text, 53 bytes; the output bytes match the source. |
| `utf16le.txt` | Opens as plain text and preserves the characters; the UTF-16 little-endian byte-order mark is recognized. | Saving preserves UTF-16 little-endian, 70 bytes; the output bytes match the source. |
| `macroman.txt` | Opens as plain text and displays the MacRoman punctuation and accented characters correctly. No encoding prompt appeared. | Saving preserves the source bytes, 30 bytes. |
| `empty.txt` | Opens as an empty plain-text document. | Saving produces an empty file, 0 bytes. |
| `malformed.rtf` | Does not open. TextEdit presents an alert explaining that the file is not in the expected format and may be damaged or incomplete. | Not applicable; opening was rejected. |
| `huge.txt` | The 17.25 MB authored plain-text file opens and displays its repeated first lines. No warning appeared during this observation. | Saving produces UTF-8 text, 17,250,000 bytes; the output bytes match the source. |
| `sample.docx` | Opened through TextEdit's file picker as formatted text. Bold and italic runs and both paragraphs appeared. | TextEdit saved a separate DOCX copy in `analysis/saved-output/corpus-run-office3/sample.docx`. It remains a DOCX; extracted plain text matches the source byte-for-byte after text conversion. The DOCX serialization itself changed. |

## Not yet covered

`sample.doc`, `sample.wordml`, `sample.odt`, and `sample.webarchive` still lack successful UI-driven open/save observations. The unattended office-format harness reached an OS permission alert on `sample.odt`; the web-archive harness reached the same kind of alert. These are automation access failures, not recorded format rejection behavior. RTFD remains UI-tested separately because the AppleScript process cannot open the package directly. Encoding fallback cases without recognized markers and additional HTML/plain-text save options also remain unmeasured. File size and latency observations are qualitative and limited to this machine and run.
