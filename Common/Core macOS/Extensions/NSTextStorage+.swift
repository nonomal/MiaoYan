import Foundation

import Cocoa

public extension NSTextStorage {
    func updateFont() {
        beginEditing()
        enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { value, range, _ in
            if let font = value as? NSFont, let familyName = UserDefaultsManagement.noteFont.familyName {
                let newFontDescriptor = font.fontDescriptor
                    .withFamily(familyName)
                    .withSymbolicTraits(font.fontDescriptor.symbolicTraits)

                if let newFont = NSFont(descriptor: newFontDescriptor, size: CGFloat(UserDefaultsManagement.fontSize)) {
                    removeAttribute(.font, range: range)
                    addAttribute(.font, value: newFont, range: range)
                    fixAttributes(in: range)
                }
            }
        }
        endEditing()
    }

    func updateParagraphStyle() {
        beginEditing()

        let attachmentParagraph = NSMutableParagraphStyle()
        attachmentParagraph.lineSpacing = CGFloat(UserDefaultsManagement.editorLineSpacing)
        attachmentParagraph.alignment = .left
        attachmentParagraph.lineHeightMultiple = CGFloat(UserDefaultsManagement.editorLineHeight)

        mutableString.enumerateSubstrings(in: NSRange(0..<length), options: .byParagraphs) { _, range, _, _ in
            let rangeNewline = range.upperBound == self.length ? range : NSRange(range.location..<range.upperBound + 1)
            self.addAttribute(.paragraphStyle, value: attachmentParagraph, range: rangeNewline)
            self.addAttribute(.kern, value: UserDefaultsManagement.DefaultEditorLetterSpacing, range: rangeNewline)
        }

        endEditing()
    }

    func sizeAttachmentImages() {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length)) { value, range, _ in
            if let attachment = value as? NSTextAttachment,
               attribute(.todo, at: range.location, effectiveRange: nil) == nil {
                if let imageData = attachment.fileWrapper?.regularFileContents, var image = NSImage(data: imageData) {
                    if let rep = image.representations.first {
                        var maxWidth = UserDefaultsManagement.imagesWidth
                        if maxWidth == Float(1000) {
                            maxWidth = Float(rep.pixelsWide)
                        }

                        let ratio = Float(maxWidth) / Float(rep.pixelsWide)
                        var size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
                        if ratio < 1 {
                            size = NSSize(width: Int(maxWidth), height: Int(Float(rep.pixelsHigh) * Float(ratio)))
                        }

                        image = image.resize(to: size)!

                        let cell = NSTextAttachmentCell(imageCell: NSImage(size: size))
                        cell.image = image
                        attachment.attachmentCell = cell

                        addAttribute(.link, value: String(), range: range)
                    }
                }
            }
        }
    }
}
