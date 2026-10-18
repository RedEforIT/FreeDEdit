import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let attachmentURL = URL(fileURLWithPath: CommandLine.arguments[2])
let fileWrapper = try FileWrapper(url: attachmentURL, options: [])
let attachment = NSTextAttachment(fileWrapper: fileWrapper)
let document = NSMutableAttributedString(string: "Before attachment\n")
document.append(NSAttributedString(attachment: attachment))
document.append(NSAttributedString(string: "\nAfter attachment.\n"))
let wrapper = try document.fileWrapper(from: NSRange(location: 0, length: document.length),
                                       documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
try wrapper.write(to: outputURL, options: .atomic, originalContentsURL: nil)
