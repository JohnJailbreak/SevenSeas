//
//  UpdateViews.swift
//  SevenSeas
//
//  The update flow, Octopus's and Caz's, drawn like Dopamine's: the changelog sits in the centred window frame with no
//  card behind it, only the dimmed backdrop (DOUpdateViewController, DOModalTransitionPush).
//  Dopamine: Copyright (c) 2023-2024 Lars Fröder (opa334), MIT License (see NOTICE.md).
//

import SwiftUI

/// A borderless menu-style button (DOActionMenuButton without a chevron): "Update Available" on the main screen and
/// "Update" under the changelog.
struct UpdateLinkButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .medium))
                Text(title)
                    .font(.system(size: 17))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
    }
}

/// DOUpdateViewController: a 24 pt title 20 pt from the top, the release notes centred at 70% under a fade mask
/// (0, 1%, 50%, 87%), and a 30 pt Update button 20 pt from the bottom.
struct ChangelogView: View {
    @ObservedObject var updater: Updater

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text("Changelog")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .accessibilityAddTraits(.isHeader)
                ScrollView(.vertical, showsIndicators: false) {
                    ChangelogText.make(updater.updates)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                .opacity(0.7)
                .mask(
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.01),
                        .init(color: .black, location: 0.5),
                        .init(color: .clear, location: 0.87)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .padding(.top, 20)
            }
            if updater.isAvailable {
                UpdateLinkButton(title: updater.handingOff ? "Opening TrollStore..." : "Update",
                                 symbol: "arrow.down") {
                    updater.install()
                }
                .frame(height: 30)
                .padding(.bottom, 20)
                .disabled(updater.handingOff)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum ChangelogText {
    /// Each release: its name in bold 18 pt, a blank line, its notes at 16 pt, then three blank lines.
    static func make(_ releases: [AppRelease]) -> Text {
        guard !releases.isEmpty else {
            return Text("Changelog Unavailable").font(.system(size: 18))
        }
        var text = Text("")
        for release in releases {
            text = text + Text(release.name + "\n").font(.system(size: 18, weight: .bold))
            text = text + Text("\n")
            text = text + Text(markdown(release.body)).font(.system(size: 16))
            text = text + Text("\n\n\n")
        }
        return text + Text(String(repeating: "\n", count: 10))
    }

    /// Inline markdown only, keeping line breaks, like Dopamine's parsing options.
    static func markdown(_ source: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true,
                                                             interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: source, options: options)) ?? AttributedString(source)
    }
}
