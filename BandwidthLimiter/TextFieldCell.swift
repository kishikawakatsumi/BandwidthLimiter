import AppKit

final class TextFieldCell: NSTextFieldCell {
    func adjustedRect(forBounds rect: NSRect) -> NSRect {
        let offset: CGFloat = floor((rect.height - ((font?.ascender ?? 0.0) - (font?.descender ?? 0.0))) / 2)
        return rect.insetBy(dx: 0, dy: offset)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedRect(forBounds: rect), in: controlView, editor: textObj, delegate: textObj, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedRect(forBounds: cellFrame), in: controlView)
    }
}
