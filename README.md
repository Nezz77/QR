# QR Generator for macOS

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-black?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Language-Swift%205.9-FA7343?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/Framework-SwiftUI%20%2B%20AppKit-0078D6?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" />
  <img src="https://img.shields.io/badge/Built%20by-Futuretech%20%7C%20NH-blueviolet?style=flat-square" />
</p>

A **premium, native macOS QR Code Generator** built with SwiftUI and CoreImage. Generate high-resolution QR codes instantly from any URL or text, customise their appearance, and export them in multiple formats — all in a gorgeous liquid-glass interface.

---

## ✨ Features

| Feature | Detail |
|---|---|
| **Real-time Generation** | QR code renders as you type with a 120 ms debounce — no lag, no wasted CPU cycles |
| **High-Resolution Output** | All QR codes are rendered at 1200 × 1200 px using CoreImage's GPU pipeline |
| **Custom Colours** | Full foreground and background colour pickers via `CIFalseColor` filter |
| **Error Correction** | Choose between L / M / Q / H correction levels |
| **Copy to Clipboard** | One-click copy via `NSPasteboard` with a visual success indicator |
| **Multi-Format Export** | Save as **PNG**, **JPEG**, **HEIC**, or **PDF** via a native `NSSavePanel` |
| **Theme Engine** | Toggle between Light, Dark, and System appearance on the fly |
| **Liquid Glass UI** | `NSVisualEffectView` vibrancy + `.ultraThinMaterial` across the entire window |
| **Collapsible Panels** | Spring-animated expandable control cards to keep the UI uncluttered |
| **Minimal Footprint** | Single GPU-backed `CIContext`, serial render queue, zero redundant state |

---

## 🖥 Screenshots

> _Open the project in Xcode, run it, and it will look like this:_

```
┌─────────────────────────────────────┬──────────────┐
│  🔲  QR Generator                   │ Appearance ▸ │
│  Instant · High-Res · Private        │ Export     ▸ │
│                                     │ Reset      ▸ │
│  ┌─────────────────────────────┐    │              │
│  │ Paste a URL or any text…    │    │              │
│  └─────────────────────────────┘    │              │
│                                     │              │
│  ┌─────────────────────────────┐    │              │
│  │                             │    │              │
│  │         [QR CODE]           │    │              │
│  │                             │    │              │
│  └─────────────────────────────┘    │              │
│                                     │              │
│       Developed by Futuretech | NH  │              │
└─────────────────────────────────────┴──────────────┘
```

---

## 🏗 Architecture

```
QRGenerator/
├── project.yml                    # XcodeGen spec — source of truth for the project
├── QRGenerator.xcodeproj/         # Generated Xcode project (do not edit manually)
└── QRGenerator/
    ├── QRGeneratorApp.swift       # @main entry point, window style, appearance binding
    ├── QRCodeManager.swift        # ObservableObject: CI render pipeline, export, clipboard
    └── ContentView.swift          # SwiftUI layout, sub-views, animations, vibrancy
```

### Key Design Decisions

- **`QRCodeManager` is `@MainActor`** — all `@Published` mutations happen on the main thread automatically; the heavy rendering work is dispatched to a private serial `DispatchQueue`.
- **Single `CIContext`** — allocated once at startup and reused for every render, avoiding the expensive GPU context setup on each keystroke.
- **`DispatchWorkItem` cancellation** — a pending render is cancelled when a new one is scheduled, so only the final keystroke triggers a GPU pass.
- **Isolated `QRPreviewView`** — the QR image is in its own `View` struct so SwiftUI only diffs that node when the image changes; the rest of the layout is untouched.
- **`CGImageDestination` export** — exports operate directly on the `CGImage` reference already in memory; no second render pass is needed.

---

## 🚀 Getting Started

### Requirements

| Tool | Version |
|---|---|
| macOS | 13.0 Ventura or later |
| Xcode | 15.0 or later |
| XcodeGen | 2.40+ (for project regeneration) |

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/QRGenerator.git
cd QRGenerator
```

### 2. (Optional) Regenerate the Xcode project

The `.xcodeproj` is committed for convenience. If you ever change `project.yml`, regenerate with:

```bash
brew install xcodegen   # first time only
xcodegen generate
```

### 3. Open and run

```bash
open QRGenerator.xcodeproj
```

Press **⌘R** in Xcode to build and run.

> **First-time only:** If `xcodebuild` complains about the developer directory, run:
> ```bash
> sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
> ```

---

## 📦 Packaging a DMG

### Step 1 — Build a Release archive

```bash
xcodebuild \
  -project QRGenerator.xcodeproj \
  -scheme QRGenerator \
  -configuration Release \
  -archivePath ./build/QRGenerator.xcarchive \
  archive
```

### Step 2 — Export the `.app`

```bash
xcodebuild \
  -exportArchive \
  -archivePath ./build/QRGenerator.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ExportOptions.plist
```

> Create `ExportOptions.plist` with `method` set to `mac-application` for a direct distribution build.

### Step 3 — Create a distributable DMG

```bash
brew install create-dmg   # first time only

create-dmg \
  --volname "QR Generator" \
  --volicon "QRGenerator/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "QRGenerator.app" 175 190 \
  --hide-extension "QRGenerator.app" \
  --app-drop-link 425 190 \
  "QRGenerator.dmg" \
  "./build/export/"
```

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI + AppKit |
| QR Generation | `CIQRCodeGenerator` (CoreImage) |
| Colour Tinting | `CIFalseColor` (CoreImage) |
| Export | `CGImageDestination`, `CGContext` (CoreGraphics) |
| Clipboard | `NSPasteboard` |
| Save Dialog | `NSSavePanel` |
| Vibrancy | `NSVisualEffectView` |
| Project | XcodeGen (`project.yml`) |

---

## 📄 License

This project is licensed under the **MIT License** — see [`LICENSE`](LICENSE) for details.

---

<p align="center">
  Developed with ♥ by <strong>Futuretech | NH</strong>
</p>
