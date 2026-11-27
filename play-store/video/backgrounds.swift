// Renders per-scene 16:9 background PNGs (text + realistic smartphone frame + chapter bar)
// and rounded-rectangle screen mask for Ghost Play promo videos.
// Usage: backgrounds <height> <outDir> [iconPath]   (height 1080 => 1920x1080, 2160 => 3840x2160)
import AppKit

let H = CGFloat(Int(CommandLine.arguments[1])!)
let out = CommandLine.arguments[2]
let iconPath = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : ""
let k = H / 1080.0
let Wd = 1920 * k

func C(_ x: String, _ a: CGFloat = 1) -> NSColor {
    let v = UInt32(x.dropFirst(), radix: 16)!
    return NSColor(
        red: CGFloat(v >> 16 & 255) / 255,
        green: CGFloat(v >> 8 & 255) / 255,
        blue: CGFloat(v & 255) / 255,
        alpha: a
    )
}

struct Scene {
    let g0, g1, acc, tag, h1, h2, desc: String
    let bullets: [String]
}

let scenes: [Scene] = [
    Scene(
        g0: "#041c1b", g1: "#0e8a6a", acc: "#7cffb2",
        tag: "👻  INCOGNITO WA COMPANION",
        h1: "GHOST PLAY", h2: "Listen invisibly. Save everything.",
        desc: "Play voice & video notes with no blue ticks, read transcripts and save statuses.",
        bullets: ["🎧  No Blue Ticks", "✨  Instant Voice Transcripts", "💾  One-Tap Status Saver"]
    ),
    Scene(
        g0: "#05261b", g1: "#0fa36b", acc: "#7cffb2",
        tag: "🎧  INCOGNITO AUDIO PLAYER",
        h1: "Listen to voice notes", h2: "without blue ticks",
        desc: "Play any audio in secret with x1, x1.5 & x2 speed and instant speech-to-text.",
        bullets: ["Zero \"seen\" or \"played\" receipts", "Built-in voice note transcription", "Floating player with x2 speed"]
    ),
    Scene(
        g0: "#0a173d", g1: "#2452d4", acc: "#78d6ff",
        tag: "📅  SMART DATE FILTERS",
        h1: "Find any voice note", h2: "in seconds",
        desc: "Filter received audios from last week up to 5 weeks back with a single tap.",
        bullets: ["Filter 1 to 5 weeks back", "Clear timestamps & durations", "Instant & 100% offline"]
    ),
    Scene(
        g0: "#240a4a", g1: "#7b32d4", acc: "#ffd86b",
        tag: "👀  ANONYMOUS STATUS VIEWER",
        h1: "Browse all statuses", h2: "before they vanish",
        desc: "View every photo and video status privately — without leaving a trace.",
        bullets: ["Watch completely anonymously", "All photos & videos in one grid", "Never lose a 24h status again"]
    ),
    Scene(
        g0: "#470826", g1: "#c91e6b", acc: "#ffb8dc",
        tag: "🖼️  PHOTO STATUS SAVER",
        h1: "Save photos to gallery", h2: "in one tap",
        desc: "Preview every photo crisp and clear, then save directly to your phone.",
        bullets: ["Full original image quality", "Direct save to native gallery", "No more \"can you send me that?\""]
    ),
    Scene(
        g0: "#4d1703", g1: "#db5b12", acc: "#ffe066",
        tag: "🎬  HD VIDEO SAVER",
        h1: "Download video statuses", h2: "in full quality",
        desc: "Smooth built-in video playback with perfect aspect ratio before you save.",
        bullets: ["Original HD video & sound", "Built-in player & seek bar", "One-tap gallery export"]
    ),
    Scene(
        g0: "#052a3b", g1: "#0e8ea8", acc: "#7ef9ff",
        tag: "🎥  VIDEO NOTES & TRANSCRIPTS",
        h1: "Watch & save video notes", h2: "completely unseen",
        desc: "Play circular video notes secretly, read auto-transcripts and keep them forever.",
        bullets: ["Zero blue ticks on video notes", "Automatic speech transcription", "Save favorite moments forever"]
    ),
    Scene(
        g0: "#420736", g1: "#c92082", acc: "#ffe14d",
        tag: "🎨  THEMES & DYNAMIC COLORS",
        h1: "Make the app", h2: "match your style",
        desc: "Switch effortlessly between Light, Dark, System and 10+ vibrant accent colors.",
        bullets: ["Crisp Light & Dark themes", "10+ dynamic accent colors", "Instant live theme preview"]
    ),
    Scene(
        g0: "#13142e", g1: "#453aa3", acc: "#7cf5d4",
        tag: "🌍  FONTS & 6 LANGUAGES",
        h1: "Your font,", h2: "your language",
        desc: "Choose from 9 stylish fonts and switch between 6 languages with zero restart.",
        bullets: ["9 customizable typography styles", "🇬🇧 EN · 🇪🇸 ES · 🇮🇹 IT · 🇩🇪 DE · 🇫🇷 FR · 🇵🇹 PT", "Instant live UI switching"]
    ),
    Scene(
        g0: "#041c1b", g1: "#0e8a6a", acc: "#7cffb2",
        tag: "🔒  100% PRIVATE & OFFLINE",
        h1: "Install Ghost Play", h2: "Take back your privacy.",
        desc: "Zero data collected. Everything stays on your device. Free on Google Play.",
        bullets: ["🔒  Zero tracking, 100% local", "✈️  Works completely offline", "⬇️  Download free on Google Play"]
    ),
]

func newCtx(_ w: Int, _ h: Int) -> (NSBitmapImageRep, CGContext) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let g = NSGraphicsContext(bitmapImageRep: rep)!
    g.cgContext.translateBy(x: 0, y: CGFloat(h))
    g.cgContext.scaleBy(x: 1, y: -1)
    let f = NSGraphicsContext(cgContext: g.cgContext, flipped: true)
    NSGraphicsContext.current = f
    return (rep, f.cgContext)
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}

func fitText(
    _ s: String, maxSize: CGFloat, maxWidth: CGFloat,
    _ w: NSFont.Weight, _ col: NSColor, _ x: CGFloat, _ y: CGFloat, shadow: Bool = false
) {
    var sz = maxSize
    while sz > 30 {
        let test = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: sz * k, weight: w)])
        if test.size().width <= maxWidth * k { break }
        sz -= 2
    }
    var a: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: sz * k, weight: w),
        .foregroundColor: col,
    ]
    if shadow {
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(0.38)
        sh.shadowBlurRadius = 18 * k
        sh.shadowOffset = NSSize(width: 0, height: -5 * k)
        a[.shadow] = sh
    }
    let dy = (maxSize - sz) * 0.35
    NSAttributedString(string: s, attributes: a).draw(at: NSPoint(x: x * k, y: (y + dy) * k))
}

// Smartphone mockup geometry (design units @ 1080p, exact 1344:2992 source aspect ratio)
let sw: CGFloat = 426
let sh: CGFloat = 948
let bezel: CGFloat = 16
let pw = sw + 2 * bezel  // 458
let ph = sh + 2 * bezel  // 980
let pcx: CGFloat = 398
let pcy: CGFloat = 540
let innerR: CGFloat = 44
let outerR: CGFloat = 58

let vx = Int(round((pcx - sw / 2) * k))
let vy = Int(round((pcy - sh / 2) * k))
let vw = Int(round(sw * k))
let vh = Int(round(sh * k))
print("VIDEO_X \(vx) VIDEO_Y \(vy) VIDEO_W \(vw) VIDEO_H \(vh)")

let tx: CGFloat = 755
let maxColW: CGFloat = 1075  // right margin = 90px
let appIcon: NSImage? = (!iconPath.isEmpty && FileManager.default.fileExists(atPath: iconPath))
    ? NSImage(contentsOfFile: iconPath) : nil

for (i, s) in scenes.enumerated() {
    let (rep, cg) = newCtx(Int(Wd), Int(H))

    // Rich radial gradient backdrop
    NSGradient(starting: C(s.g1), ending: C(s.g0))!.draw(
        fromCenter: NSPoint(x: 340 * k, y: 140 * k), radius: 0,
        toCenter: NSPoint(x: 340 * k, y: 140 * k), radius: 2150 * k,
        options: [.drawsAfterEndingLocation]
    )

    // Subtle ambient bokeh circles
    for (x, y, z, a) in [
        (1780.0, 120.0, 560.0, 0.08),
        (1340.0, 1000.0, 680.0, 0.06),
        (90.0, 980.0, 440.0, 0.07),
    ] {
        C("#ffffff", CGFloat(a)).setFill()
        NSBezierPath(ovalIn: NSRect(x: (x - z / 2) * k, y: (y - z / 2) * k, width: z * k, height: z * k)).fill()
    }

    // Subtle accent halo arc behind phone
    C(s.acc, 0.10).setStroke()
    let deco = NSBezierPath(ovalIn: NSRect(x: (pcx - 420) * k, y: (pcy - 420) * k, width: 840 * k, height: 840 * k))
    deco.lineWidth = 2 * k
    deco.stroke()

    let px = (pcx - pw / 2) * k
    let py = (pcy - ph / 2) * k

    // Side hardware buttons (right side of phone: volume rocker + power)
    let btnX = px + pw * k - 2 * k
    for (by, bh) in [(250.0, 96.0), (376.0, 58.0)] {
        let br = NSRect(x: btnX, y: (pcy - ph / 2 + CGFloat(by)) * k, width: 7 * k, height: CGFloat(bh) * k)
        NSGradient(starting: C("#7b8290"), ending: C("#2b2f38"))!.draw(
            in: NSBezierPath(roundedRect: br, xRadius: 3 * k, yRadius: 3 * k), angle: 0
        )
    }

    // Phone outer body + accent ambient shadow glow
    let outerRect = NSRect(x: px, y: py, width: pw * k, height: ph * k)
    let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: outerR * k, yRadius: outerR * k)
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 18 * k), blur: 84 * k, color: C(s.acc, 0.45).cgColor)
    C("#181b21").setFill()
    outerPath.fill()
    cg.restoreGState()

    // Metallic titanium/graphite chassis gradient
    NSGradient(starting: C("#555c68"), ending: C("#15181e"))!.draw(in: outerPath, angle: 135)

    // Crisp outer rim highlight
    C("#c2c9d4", 0.48).setStroke()
    let rimPath = NSBezierPath(
        roundedRect: outerRect.insetBy(dx: 2.5 * k, dy: 2.5 * k),
        xRadius: (outerR - 2) * k, yRadius: (outerR - 2) * k
    )
    rimPath.lineWidth = 2.5 * k
    rimPath.stroke()

    // Inner dark bezel surround
    let midPath = NSBezierPath(
        roundedRect: outerRect.insetBy(dx: 6 * k, dy: 6 * k),
        xRadius: (outerR - 6) * k, yRadius: (outerR - 6) * k
    )
    C("#090b0e").setFill()
    midPath.fill()

    // Inner pitch-black screen cutout
    let screenRect = NSRect(x: CGFloat(vx), y: CGFloat(vy), width: CGFloat(vw), height: CGFloat(vh))
    C("#000000").setFill()
    NSBezierPath(roundedRect: screenRect, xRadius: innerR * k, yRadius: innerR * k).fill()

    // Right column: Tag pill
    let tagAt: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 25 * k, weight: .heavy),
        .foregroundColor: C("#ffffff", 0.96),
    ]
    let tagStr = NSAttributedString(string: s.tag, attributes: tagAt)
    let tagSz = tagStr.size()
    C("#ffffff", 0.14).setFill()
    NSBezierPath(
        roundedRect: NSRect(x: tx * k, y: 145 * k, width: tagSz.width + 42 * k, height: 50 * k),
        xRadius: 25 * k, yRadius: 25 * k
    ).fill()
    tagStr.draw(at: NSPoint(x: tx * k + 21 * k, y: 155 * k))

    // Optional Ghost Play icon next to hero title on Intro (0) and Outro (last)
    var titleX = tx
    var titleMaxW = maxColW
    if (i == 0 || i == scenes.count - 1), let icon = appIcon {
        let iconSz: CGFloat = i == 0 ? 114 : 94
        let iconY: CGFloat = i == 0 ? 232 : 222
        icon.draw(in: NSRect(x: tx * k, y: iconY * k, width: iconSz * k, height: iconSz * k))
        titleX = tx + iconSz + 22
        titleMaxW = maxColW - iconSz - 22
    }

    // Headlines (auto-fitted so they never clip)
    let h1Size: CGFloat = i == 0 ? 116 : 86
    let h2Size: CGFloat = i == 0 ? 60 : 86
    fitText(s.h1, maxSize: h1Size, maxWidth: titleMaxW, .black, .white, titleX, 220, shadow: true)
    fitText(s.h2, maxSize: h2Size, maxWidth: maxColW, .black, C(s.acc), tx, i == 0 ? 356 : 320, shadow: true)

    // Description
    let dy: CGFloat = i == 0 ? 452 : 444
    let para = NSMutableParagraphStyle()
    para.lineBreakMode = .byWordWrapping
    para.lineSpacing = 7 * k
    NSAttributedString(
        string: s.desc,
        attributes: [
            .font: NSFont.systemFont(ofSize: 34 * k, weight: .medium),
            .foregroundColor: C("#ffffff", 0.92),
            .paragraphStyle: para,
        ]
    ).draw(in: NSRect(x: tx * k, y: dy * k, width: maxColW * k, height: 120 * k))

    // Feature pills
    let startY: CGFloat = 592
    for (j, b) in s.bullets.enumerated() {
        let by = (startY + CGFloat(j) * 78) * k
        let label = (i == 0 || i == scenes.count - 1) ? b : "✓  " + b
        let at: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 30 * k, weight: .heavy),
            .foregroundColor: C("#07261c"),
        ]
        let a = NSAttributedString(string: label, attributes: at)
        let z = a.size()
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: 6 * k), blur: 16 * k, color: NSColor.black.withAlphaComponent(0.32).cgColor)
        C("#ffffff", 0.96).setFill()
        NSBezierPath(
            roundedRect: NSRect(x: tx * k, y: by, width: z.width + 48 * k, height: 58 * k),
            xRadius: 29 * k, yRadius: 29 * k
        ).fill()
        cg.restoreGState()
        a.draw(at: NSPoint(x: tx * k + 24 * k, y: by + 12 * k))
    }

    // Chapter progress indicator at bottom right
    let dotY: CGFloat = 955 * k
    var dotX: CGFloat = tx * k
    for idx in 0..<scenes.count {
        let active = (idx == i)
        let dw: CGFloat = (active ? 46 : 16) * k
        let dh: CGFloat = 10 * k
        (active ? C(s.acc) : C("#ffffff", idx < i ? 0.45 : 0.2)).setFill()
        NSBezierPath(roundedRect: NSRect(x: dotX, y: dotY, width: dw, height: dh), xRadius: 5 * k, yRadius: 5 * k).fill()
        dotX += dw + 12 * k
    }

    save(rep, "bg_\(i).png")
}

// Rounded-rectangle mask for the smartphone screen (white rounded rect on black), size = vw x vh
let (mrep, _) = newCtx(vw, vh)
C("#000000").setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: vw, height: vh)).fill()
C("#ffffff").setFill()
NSBezierPath(
    roundedRect: NSRect(x: 0, y: 0, width: vw, height: vh),
    xRadius: innerR * k, yRadius: innerR * k
).fill()
save(mrep, "mask.png")
