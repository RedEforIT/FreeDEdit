import AppKit
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: "/Users/colin/textedit-re/spec/corpus")
let cases: [(String, NSAttributedString.DocumentType)] = [
    ("sample.doc", .docFormat), ("sample.docx", .officeOpenXML), ("sample.odt", .openDocument), ("sample.wordml", .wordML), ("sample.webarchive", .webArchive), ("sample.rtf", .rtf), ("sample.html", .html)
]
for (name, type) in cases {
    let input = root.appendingPathComponent(name)
    do {
        let data = try Data(contentsOf: input)
        let value = try NSAttributedString(data: data, options: [.documentType: type], documentAttributes: nil)
        let saved = try value.data(from: NSRange(location: 0, length: value.length), documentAttributes: [.documentType: type])
        print("\(name): read OK chars=\(value.length) text=\(value.string.prefix(50).debugDescription) write=\(saved.count) bytes")
    } catch { print("\(name): FAILED \(error)") }
}
