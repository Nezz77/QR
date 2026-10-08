import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var manager: QRCodeManager
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system

    @State private var showTheme    = false
    @State private var showExport   = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            VisualEffectBackground().ignoresSafeArea()

            HStack(spacing: 0) {
                VStack(spacing: 20) {
                    headerView
                    inputField
                    QRPreviewView()
                    Spacer(minLength: 0)
                    attributionView
                }
                .padding(24)
                .frame(maxWidth: .infinity)

                Divider().opacity(0.25)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        themeSection
                        exportSection
                        settingsSection
                        Spacer(minLength: 0)
                    }
                    .padding(20)
                }
                .frame(width: 240)
            }
        }
        .frame(width: 700, height: 520)
    }

    private var headerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "qrcode")
                .font(.system(size: 28, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text("QR Generator")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text("Instant · High-Res · Private")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextEditor(text: $manager.inputText)
                .font(.system(size: 13, design: .monospaced))
                .frame(height: 90)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if manager.inputText.isEmpty {
                        Text("Paste a URL or any text…")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 14)
                            .padding(.top, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var themeSection: some View {
        PanelCard(title: "Appearance", icon: "paintpalette.fill", isExpanded: $showTheme) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("App Theme", systemImage: "display")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { a in
                            Label(a.label, systemImage: a.icon).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider().opacity(0.3)

                VStack(alignment: .leading, spacing: 8) {
                    Label("QR Colours", systemImage: "eyedropper.halffull")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack {
                        ColorPicker("Foreground", selection: $manager.fgColor).labelsHidden()
                        Text("Foreground").font(.system(size: 12))
                        Spacer()
                        ColorPicker("Background", selection: $manager.bgColor).labelsHidden()
                        Text("Background").font(.system(size: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("Error Correction", systemImage: "shield.checkered")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $manager.correction) {
                        ForEach(ErrorCorrection.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var exportSection: some View {
        PanelCard(title: "Export", icon: "square.and.arrow.up.fill", isExpanded: $showExport) {
            VStack(spacing: 8) {
                GlassButton(
                    label: manager.copySucceeded ? "Copied!" : "Copy to Clipboard",
                    icon: manager.copySucceeded ? "checkmark.circle.fill" : "doc.on.clipboard",
                    accent: manager.copySucceeded ? .green : .accentColor,
                    disabled: manager.qrImage == nil
                ) { manager.copyToClipboard() }

                Divider().opacity(0.3)

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                    ForEach(ExportFormat.allCases) { fmt in
                        GlassButton(label: fmt.rawValue, icon: fmt.icon, accent: .accentColor,
                                    disabled: manager.qrImage == nil) {
                            manager.saveImage(as: fmt)
                        }
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        PanelCard(title: "Reset", icon: "arrow.counterclockwise", isExpanded: $showSettings) {
            GlassButton(label: "Clear All", icon: "trash", accent: .red,
                        disabled: manager.inputText.isEmpty && manager.qrImage == nil) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    manager.inputText  = ""
                    manager.fgColor    = .black
                    manager.bgColor    = .white
                    manager.correction = .high
                }
            }
        }
    }

    private var attributionView: some View {
        Text("Developed by **Futuretech | NH**")
            .font(.system(size: 10, weight: .regular))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)
    }
}

struct QRPreviewView: View {
    @EnvironmentObject private var manager: QRCodeManager

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.quaternary, lineWidth: 1))

            if let img = manager.qrImage {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(20)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 52))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tertiary)
                    Text("Type something to generate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: manager.qrImage == nil)
    }
}

struct PanelCard<Content: View>: View {
    let title: String
    let icon:  String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: icon).symbolRenderingMode(.hierarchical).frame(width: 18)
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().opacity(0.25)
                content()
                    .padding(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
        .clipped()
    }
}

struct GlassButton: View {
    let label:    String
    let icon:     String
    let accent:   Color
    let disabled: Bool
    let action:   () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).symbolRenderingMode(.hierarchical)
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 8).fill(accent.opacity(isHovered ? 0.22 : 0.12)))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(accent.opacity(0.3), lineWidth: 1))
            .foregroundStyle(accent.opacity(disabled ? 0.3 : 1.0))
            .scaleEffect(isHovered && !disabled ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material     = .sidebar
        v.blendingMode = .behindWindow
        v.state        = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}
