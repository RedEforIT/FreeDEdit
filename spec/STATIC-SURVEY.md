# Static survey: TextEdit document types and runtime dependencies

This note records metadata visible in the installed app bundle on macOS 27.0.1 (build 26A434). The bundle declares an executable named `TextEdit` and identifies itself with the `com.apple.TextEdit` application identifier.

TextEdit advertises editing support for RTF (`public.rtf`), RTFD (`com.apple.rtfd`), HTML (`public.html`), Apple web archive (`com.apple.webarchive`), OpenDocument Text (`org.oasis-open.opendocument.text`), Microsoft Word 2007 (`org.openxmlformats.wordprocessingml.document`), Microsoft Word 2003 XML (`com.microsoft.word.wordml`), Microsoft Word 97 (`com.microsoft.word.doc`), and plain text (`public.text`). It advertises viewing, rather than editing, for OpenDocument Text templates and the listed OpenOffice text/template types. The metadata names a document handler called `Document` for these types. The RTF and RTFD entries are marked as Apple's default handler; the plain text entry is also marked as the default handler. Word formats have alternate handler rank.

The executable links to Cocoa, Foundation, AppKit, CoreFoundation, CoreGraphics, and Uniform Type Identifiers, as well as a private performance testing framework. The observed entitlements include app sandboxing, read/write access to user-selected files, printing, and a TextEdit ubiquity container. These observations describe bundle metadata; they do not establish behavior for each format.

The installed bundle could not be copied into the analysis directory by the available account (`ditto` reported “Operation not permitted”). The installed app was only read for metadata; it was not modified. A static executable copy is therefore not available for class-dump or disassembly in this session.
