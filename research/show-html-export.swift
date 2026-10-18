import AppKit
let html = try! Data(contentsOf: URL(fileURLWithPath: "/Users/colin/textedit-re/spec/corpus/sample.html"))
let value = try! NSAttributedString(data: html, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
let out = try! value.data(from: NSRange(location: 0, length: value.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue])
print(String(decoding: out, as: UTF8.self))
