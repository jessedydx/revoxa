#!/usr/bin/env swift

import AppKit
import Foundation

private struct ScreenshotSpec {
    enum Platform {
        case iphone
        case ipad
        case mac
    }

    let platform: Platform
    let input: String
    let output: String
    let title: String
    let subtitle: String
}

private let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let baseURL = rootURL.appendingPathComponent("docs/app-store-assets/screenshots")

private let specs: [ScreenshotSpec] = [
    .init(
        platform: .iphone,
        input: "raw/iphone/01-dashboard.png",
        output: "final/iphone/01-dashboard.png",
        title: "See spending at a glance",
        subtitle: "Track recurring subscriptions before they renew."
    ),
    .init(
        platform: .iphone,
        input: "raw/iphone/02-subscriptions.png",
        output: "final/iphone/02-subscriptions.png",
        title: "Every subscription organized",
        subtitle: "Keep services, prices, cycles, and status in one list."
    ),
    .init(
        platform: .iphone,
        input: "raw/iphone/03-calendar.png",
        output: "final/iphone/03-calendar.png",
        title: "Know what renews when",
        subtitle: "Use the calendar to plan upcoming payments."
    ),
    .init(
        platform: .iphone,
        input: "raw/iphone/04-day-modal.png",
        output: "final/iphone/04-day-modal.png",
        title: "Review any payment day",
        subtitle: "Tap a date to see every subscription due that day."
    ),
    .init(
        platform: .iphone,
        input: "raw/iphone/05-edit-form.png",
        output: "final/iphone/05-edit-form.png",
        title: "Capture the details",
        subtitle: "Track cycles, reminders, categories, and notes."
    ),
    .init(
        platform: .iphone,
        input: "raw/iphone/06-settings.png",
        output: "final/iphone/06-settings.png",
        title: "Your data stays portable",
        subtitle: "Export local records whenever you need them."
    ),
    .init(
        platform: .ipad,
        input: "raw/ipad/01-dashboard.png",
        output: "final/ipad/01-dashboard.png",
        title: "A wider view of recurring costs",
        subtitle: "See totals, upcoming renewals, and categories together."
    ),
    .init(
        platform: .ipad,
        input: "raw/ipad/02-calendar.png",
        output: "final/ipad/02-calendar.png",
        title: "Plan renewals on a larger calendar",
        subtitle: "Review payment timing with more room to scan."
    ),
    .init(
        platform: .ipad,
        input: "raw/ipad/03-subscriptions.png",
        output: "final/ipad/03-subscriptions.png",
        title: "Browse and edit comfortably",
        subtitle: "Manage subscriptions with an iPad-friendly layout."
    ),
    .init(
        platform: .ipad,
        input: "raw/ipad/04-settings.png",
        output: "final/ipad/04-settings.png",
        title: "Local preferences and export",
        subtitle: "Keep control of theme, language, reminders, and CSV."
    ),
    .init(
        platform: .mac,
        input: "raw/macos/01-dashboard.png",
        output: "final/macos/01-dashboard.png",
        title: "A focused desktop view",
        subtitle: "Track recurring costs from a clean Mac dashboard."
    ),
    .init(
        platform: .mac,
        input: "raw/macos/02-subscriptions.png",
        output: "final/macos/02-subscriptions.png",
        title: "Search and manage local records",
        subtitle: "Review subscriptions, categories, renewals, and status."
    ),
    .init(
        platform: .mac,
        input: "raw/macos/03-calendar.png",
        output: "final/macos/03-calendar.png",
        title: "A monthly payment view",
        subtitle: "See upcoming renewals in a desktop calendar."
    ),
    .init(
        platform: .mac,
        input: "raw/macos/04-settings.png",
        output: "final/macos/04-settings.png",
        title: "Portable CSV export",
        subtitle: "Keep subscription data local and export it anytime."
    )
]

private extension ScreenshotSpec.Platform {
    var canvasSize: CGSize {
        switch self {
        case .iphone:
            return CGSize(width: 1290, height: 2796)
        case .ipad:
            return CGSize(width: 2048, height: 2732)
        case .mac:
            return CGSize(width: 2880, height: 1800)
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .iphone:
            return 72
        case .ipad:
            return 88
        case .mac:
            return 88
        }
    }

    var subtitleSize: CGFloat {
        switch self {
        case .iphone:
            return 34
        case .ipad:
            return 42
        case .mac:
            return 38
        }
    }

    var screenTop: CGFloat {
        switch self {
        case .iphone:
            return 610
        case .ipad:
            return 545
        case .mac:
            return 390
        }
    }

    var screenMaxWidth: CGFloat {
        switch self {
        case .iphone:
            return 970
        case .ipad:
            return 1430
        case .mac:
            return 2200
        }
    }

    var screenMaxHeight: CGFloat {
        switch self {
        case .iphone:
            return 2100
        case .ipad:
            return 2080
        case .mac:
            return 1320
        }
    }

    var screenshotCornerRadius: CGFloat {
        switch self {
        case .iphone:
            return 76
        case .ipad:
            return 34
        case .mac:
            return 20
        }
    }

    var framePadding: CGFloat {
        switch self {
        case .iphone:
            return 28
        case .ipad:
            return 22
        case .mac:
            return 18
        }
    }
}

private func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvas: CGSize) -> CGRect {
    CGRect(x: x, y: canvas.height - y - height, width: width, height: height)
}

private func aspectFit(size: CGSize, in rect: CGRect) -> CGRect {
    let scale = min(rect.width / size.width, rect.height / size.height)
    let width = floor(size.width * scale)
    let height = floor(size.height * scale)
    return CGRect(
        x: rect.midX - width / 2,
        y: rect.midY - height / 2,
        width: width,
        height: height
    )
}

private func drawBackground(in rect: CGRect) {
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.94, green: 0.98, blue: 0.96, alpha: 1.0),
        NSColor(calibratedRed: 0.72, green: 0.91, blue: 0.91, alpha: 1.0),
        NSColor(calibratedRed: 0.97, green: 0.84, blue: 0.72, alpha: 1.0)
    ])
    gradient?.draw(in: rect, angle: 238)

    NSColor(calibratedRed: 0.08, green: 0.13, blue: 0.23, alpha: 0.08).setFill()
    NSBezierPath(ovalIn: CGRect(x: rect.maxX * 0.62, y: rect.maxY * 0.62, width: rect.width * 0.55, height: rect.height * 0.38)).fill()

    NSColor(calibratedRed: 0.10, green: 0.62, blue: 0.55, alpha: 0.10).setFill()
    NSBezierPath(ovalIn: CGRect(x: -rect.width * 0.18, y: -rect.height * 0.10, width: rect.width * 0.70, height: rect.height * 0.36)).fill()
}

private func drawText(_ spec: ScreenshotSpec, canvas: CGSize) {
    let sidePadding = canvas.width * 0.095
    let titleRect = topRect(x: sidePadding, y: 92, width: canvas.width - sidePadding * 2, height: 210, canvas: canvas)
    let subtitleRect = topRect(x: sidePadding, y: spec.platform == .iphone ? 315 : 310, width: canvas.width - sidePadding * 2, height: 120, canvas: canvas)

    let titleStyle = NSMutableParagraphStyle()
    titleStyle.alignment = .center
    titleStyle.lineBreakMode = .byWordWrapping

    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: spec.platform.titleSize, weight: .heavy),
        .foregroundColor: NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.16, alpha: 1.0),
        .paragraphStyle: titleStyle
    ]

    let subtitleStyle = NSMutableParagraphStyle()
    subtitleStyle.alignment = .center
    subtitleStyle.lineBreakMode = .byWordWrapping

    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: spec.platform.subtitleSize, weight: .medium),
        .foregroundColor: NSColor(calibratedRed: 0.25, green: 0.30, blue: 0.38, alpha: 1.0),
        .paragraphStyle: subtitleStyle
    ]

    (spec.title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
    (spec.subtitle as NSString).draw(in: subtitleRect, withAttributes: subtitleAttributes)
}

private func drawBrandPill(canvas: CGSize) {
    let width: CGFloat = 252
    let height: CGFloat = 58
    let rect = topRect(x: canvas.width / 2 - width / 2, y: canvas.height - 118, width: width, height: height, canvas: canvas)
    let path = NSBezierPath(roundedRect: rect, xRadius: 29, yRadius: 29)
    NSColor.white.withAlphaComponent(0.55).setFill()
    path.fill()

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
        .foregroundColor: NSColor(calibratedRed: 0.08, green: 0.13, blue: 0.23, alpha: 0.92)
    ]
    let string = "Revoxa" as NSString
    let textSize = string.size(withAttributes: attributes)
    string.draw(at: CGPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2), withAttributes: attributes)
}

private func drawScreenshot(_ screenshot: NSImage, for platform: ScreenshotSpec.Platform, canvas: CGSize) {
    let available = topRect(
        x: (canvas.width - platform.screenMaxWidth) / 2,
        y: platform.screenTop,
        width: platform.screenMaxWidth,
        height: platform.screenMaxHeight,
        canvas: canvas
    )
    let imageRect = aspectFit(size: screenshot.size, in: available)
    let frameRect = imageRect.insetBy(dx: -platform.framePadding, dy: -platform.framePadding)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowOffset = CGSize(width: 0, height: -20)
    shadow.shadowBlurRadius = 48

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.white.withAlphaComponent(0.80).setFill()
    NSBezierPath(roundedRect: frameRect, xRadius: platform.screenshotCornerRadius + platform.framePadding, yRadius: platform.screenshotCornerRadius + platform.framePadding).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.10, alpha: 0.92).setFill()
    NSBezierPath(roundedRect: frameRect, xRadius: platform.screenshotCornerRadius + platform.framePadding, yRadius: platform.screenshotCornerRadius + platform.framePadding).fill()

    NSGraphicsContext.saveGraphicsState()
    let clipPath = NSBezierPath(roundedRect: imageRect, xRadius: platform.screenshotCornerRadius, yRadius: platform.screenshotCornerRadius)
    clipPath.addClip()
    screenshot.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.18).setStroke()
    let strokePath = NSBezierPath(roundedRect: imageRect, xRadius: platform.screenshotCornerRadius, yRadius: platform.screenshotCornerRadius)
    strokePath.lineWidth = 2
    strokePath.stroke()
}

private func render(_ spec: ScreenshotSpec) throws {
    let inputURL = baseURL.appendingPathComponent(spec.input)
    guard FileManager.default.fileExists(atPath: inputURL.path) else {
        print("Skipping missing input: \(spec.input)")
        return
    }

    guard let screenshot = NSImage(contentsOf: inputURL) else {
        throw NSError(domain: "ScreenshotRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not read \(inputURL.path)"])
    }

    let canvas = spec.platform.canvasSize
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width),
        pixelsHigh: Int(canvas.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "ScreenshotRenderer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.setFill()
    CGRect(origin: .zero, size: canvas).fill()
    drawBackground(in: CGRect(origin: .zero, size: canvas))
    drawText(spec, canvas: canvas)
    drawBrandPill(canvas: canvas)
    drawScreenshot(screenshot, for: spec.platform, canvas: canvas)
    NSGraphicsContext.restoreGraphicsState()

    let outputURL = baseURL.appendingPathComponent(spec.output)
    try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ScreenshotRenderer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not encode \(outputURL.path)"])
    }

    try pngData.write(to: outputURL)
    print("Generated \(spec.output)")
}

for spec in specs {
    try render(spec)
}
