# TextEdit preference keys observed by changing Settings

Values below were checked with `defaults read com.apple.TextEdit` before and after changing controls in Settings. The controls were returned to their starting values after each check. For Boolean controls, the command-line representation was `0` or `1`; font and metadata fields were not fully mapped. An absent key is the observed state for the initial value unless a different default is stated. The common defaults in the database for the open-panel size and directory bookmark are unrelated to TextEdit editing behavior.

## New Document settings

| Settings control | Key | Stored type | Initial value | Effect |
| --- | --- | --- | --- | --- |
| Rich/plain starting format | `RichText` | Boolean | true (key absent) | Chooses the format used for new documents. |
| Wrap to page | `ShowPageBreaks` | Boolean | false (key absent) | Makes text wrap to document margins rather than window boundaries. |
| Plain-text width | `WidthInChars` | Integer | 96 (key absent) | Sets the starting plain-text window width in characters. |
| Plain-text height | `HeightInChars` | Integer | 30 (key absent) | Sets the starting plain-text window height in lines. |
| Show ruler | `ShowRuler` | Boolean | true (key absent) | Shows the ruler for rich-text documents. |
| Spell checking while typing | `CheckSpellingWhileTyping` | Boolean | true (key absent) | Turns continuous spelling checks on or off. |
| Grammar checking | `CheckGrammarWithSpelling` | Boolean | false (key absent) | Enables grammar checking with spelling. |
| Automatic spelling correction | `CorrectSpellingAutomatically` | Boolean | true (key absent) | Corrects spelling automatically. |
| Smart quotes | `SmartQuotes` | Boolean | true (key absent) | Replaces straight quotes with typographic quotes. |
| Smart dashes | `SmartDashes` | Boolean | true (key absent) | Applies automatic dash substitutions. |
| Smart links | `SmartLinks` | Boolean | false (key absent) | Detects links automatically. |
| Text replacement | `TextReplacement` | Boolean | true (key absent) | Applies system text replacements. |
| Data detectors | `DataDetectors` | Boolean | false (key absent) | Detects dates and other recognized data. |
| Smart copy/paste | `SmartCopyPaste` | Boolean | true (key absent) | Enables smart insertion/deletion behavior around copied text. |
| Punctuation only in rich text | `SmartSubstitutionsEnabledInRichTextOnly` | Boolean | true (key absent) | Limits smart quotes and dashes to rich-text documents. |
| Spelling only in rich text | `CheckSpellingAsYouTypeEnabledInRichTextOnly` | Boolean | false (key absent) | Limits spelling checks and correction to rich-text documents. |

The pane shows Menlo Regular 11 for the plain-text font and Helvetica 12 for the rich-text font. The corresponding stored keys and types have not been determined. The author field wrote a string preference named `company`; the organization field wrote a string preference named `copyright`. The separate copyright field's stored key has not been determined.

## Open and Save settings

| Settings control | Key | Stored type | Initial value | Effect |
| --- | --- | --- | --- | --- |
| Show RTF source | `IgnoreRichText` | Boolean | false (key absent) | When enabled, displays RTF source instead of formatted content. |
| Show HTML source | `IgnoreHTML` | Boolean | false (key absent) | When enabled, displays HTML source instead of formatted content. |
| Add `.txt` extension | `AddExtensionToNewPlainTextFiles` | Boolean | true (key absent) | Adds the extension to plain-text saves that lack a known extension. |
| Open encoding | `PlainTextEncoding` | Integer | Automatic (key absent) | Sets the default encoding for opening plain-text files. The observed UTF-8 selection stored 4. |
| Save encoding | `PlainTextEncodingForWrite` | Integer | Automatic (key absent) | Sets the default encoding for saving plain-text files. The observed UTF-16 selection stored 10. |
| Preserve white space in HTML | `PreserveWhitespace` | Boolean | true (key absent) | Emits HTML code that preserves formatted-text whitespace. |
| HTML transitional type | `UseTransitionalDocType` | Boolean | false (key absent) | Selects an HTML 4.01 Transitional or XHTML 1.0 Transitional export type when enabled. |
| XHTML export | `UseXHTMLDocType` | Boolean | false (key absent) | Selects an XHTML 1.0 export type when enabled. |

The HTML encoding selector initially showed Unicode UTF-8. Its stored key was not changed. The settings changes above were returned to the initial displayed values; after removing the two HTML export type flags created during the experiment, `defaults read` returned to the pre-test preference set.
