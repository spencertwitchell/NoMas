//
//  LibraryMarkdownStyle.swift
//  NoMas
//
//  Custom markdown styling for library articles using MarkdownUI
//

import SwiftUI
import MarkdownUI

extension View {
    func appMarkdownStyle() -> some View {
        self
            .markdownTextStyle {
                ForegroundColor(.white.opacity(0.9))
                FontSize(16)
            }
            .markdownBlockStyle(\.heading1) { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("HelveticaNeue-Medium"))
                        FontWeight(.semibold)
                        FontSize(28)
                        ForegroundColor(.white)
                    }
            }
            .markdownBlockStyle(\.heading2) { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("HelveticaNeue-Medium"))
                        FontWeight(.semibold)
                        FontSize(22)
                        ForegroundColor(.white)
                    }
            }
            .markdownBlockStyle(\.heading3) { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("HelveticaNeue-Medium"))
                        FontWeight(.semibold)
                        FontSize(18)
                        ForegroundColor(.white)
                    }
            }
            .markdownBlockStyle(\.paragraph) { configuration in
                configuration.label
                    .foregroundColor(.white.opacity(0.9))
            }
            .markdownBlockStyle(\.listItem) { configuration in
                configuration.label
                    .foregroundColor(.white.opacity(0.9))
            }
            .background(Color.clear)
    }
}
