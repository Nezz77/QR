import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

@MainActor
final class QRCodeManager: ObservableObject {

    @Published var inputText:  String          = ""    { didSet { scheduleGeneration() } }
    @Published var fgColor:    Color           = .black { didSet { scheduleGeneration() } }
    @Published var bgColor:    Color           = .white { didSet { scheduleGeneration() } }
    @Published var correction: ErrorCorrection = .high  { didSet { scheduleGeneration() } }
    @Published var qrImage:    NSImage?        = nil
    @Published var copySucceeded               = false

    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates:  false,
        .outputColorSpace:    CGColorSpaceCreateDeviceRGB() as Any
    ])

    private let renderQueue = DispatchQueue(label: "qr.render", qos: .userInitiated)
    private var pendingWork: DispatchWorkItem?

    private func scheduleGeneration() {
        pendingWork?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.render() }
        pendingWork = item
        renderQueue.asyncAfter(deadline: .now() + 0.12, execute: item)
    }

    private func render() {
        guard !inputText.isEmpty else {
            DispatchQueue.main.async { self.qrImage = nil }
            return
        }

        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return }
        qrFilter.setValue(Data(inputText.utf8), forKey: "inputMessage")
        qrFilter.setValue(correction.rawValue,  forKey: "inputCorrectionLevel")
        guard let raw = qrFilter.outputImage else { return }

        let scale  = 1200.0 / raw.extent.width
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let tinted: CIImage
        if let fc = CIFilter(name: "CIFalseColor") {
            fc.setValue(scaled,                                    forKey: kCIInputImageKey)
            fc.setValue(CIColor(cgColor: NSColor(fgColor).cgColor), forKey: "inputColor0")
            fc.setValue(CIColor(cgColor: NSColor(bgColor).cgColor), forKey: "inputColor1")
            tinted = fc.outputImage ?? scaled
        } else {
            tinted = scaled
        }

        guard let cg = ciContext.createCGImage(tinted, from: tinted.extent) else { return }
        let ns = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        DispatchQueue.main.async { self.qrImage = ns }
    }

    func copyToClipboard() {
        guard let image = qrImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        copySucceeded = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.copySucceeded = false }
    }

    func saveImage(as format: ExportFormat) {
        guard let image  = qrImage,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return }

        let panel = NSSavePanel()
        panel.title                = "Export QR Code"
        panel.nameFieldStringValue = "QRCode"
        panel.allowedContentTypes  = [format.utType]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }

        switch format {
        case .png:
            writeBitmap(cgImage, to: url, type: .png,  props: [:])
        case .jpeg:
            writeBitmap(cgImage, to: url, type: .jpeg, props: [kCGImageDestinationLossyCompressionQuality as String: 0.92])
        case .heic:
            writeBitmap(cgImage, to: url, type: .heic, props: [kCGImageDestinationLossyCompressionQuality as String: 0.92])
        case .pdf:
            writePDF(image: image, to: url)
        }
    }

    private func writeBitmap(_ cg: CGImage, to url: URL, type: UTType, props: [String: Any]) {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, cg, props as CFDictionary)
        CGImageDestinationFinalize(dest)
    }

    private func writePDF(image: NSImage, to url: URL) {
        var box = CGRect(origin: .zero, size: image.size)
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        ctx.beginPDFPage(nil)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        image.draw(in: box)
        NSGraphicsContext.restoreGraphicsState()
        ctx.endPDFPage()
        ctx.closePDF()
    }
}

enum ErrorCorrection: String, CaseIterable, Identifiable {
    case low = "L", medium = "M", quartile = "Q", high = "H"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low:      "Low (7%)"
        case .medium:   "Medium (15%)"
        case .quartile: "Quartile (25%)"
        case .high:     "High (30%)"
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG", jpeg = "JPEG", heic = "HEIC", pdf = "PDF"
    var id: String { rawValue }

    var utType: UTType {
        switch self {
        case .png:  .png
        case .jpeg: .jpeg
        case .heic: .heic
        case .pdf:  .pdf
        }
    }

    var icon: String {
        switch self {
        case .png:  "photo"
        case .jpeg: "photo.fill"
        case .heic: "sparkles"
        case .pdf:  "doc.richtext.fill"
        }
    }
}
