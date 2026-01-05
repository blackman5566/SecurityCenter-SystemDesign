//
//  OptionAlertView.swift
//  SecurityCenter-SystemDesign
//
//  Created by 許佳豪 on 2026/1/5.
//

import SwiftUI

struct AlertViewItem {
    let text: String
    let description: String?
    let selected: Bool
    let disabled: Bool

    init(text: String, description: String? = nil, selected: Bool = false, disabled: Bool = false) {
        self.text = text
        self.description = description
        self.selected = selected
        self.disabled = disabled
    }
}

struct OptionAlertView: View {
    let title: String
    let viewItems: [AlertViewItem]
    let onSelect: (Int) -> Void
    @Binding var isPresented: Bool

    @State private var opacity: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                dimView

                view
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .frame(width: 240)
                    .frame(maxHeight: max(0, proxy.size.height - 4 * 32))
            }
            .ignoresSafeArea()
            .transition(.opacity)
            .task {
                animate(isShown: true)
            }
        }
    }

    private var view: some View {
        VStack {
            Text(title)
                .frame(alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            ForEach(Array(viewItems.enumerated()), id: \.offset) { index, viewItem in
                Divider()
                HStack {
                    Button(action: {
                        animate(isShown: false) {
                            onSelect(index)
                        }
                    }, label: {
                        view(viewItem: viewItem)
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(.plain)
                    .disabled(viewItem.disabled)
                }
            }
        }.background(Color(.secondarySystemBackground)).shadow(radius: 12)
    }

    private func view(viewItem: AlertViewItem) -> some View {
        HStack {
            VStack(spacing: 1) {
                Text(viewItem.text)

                if let description = viewItem.description {
                    Text(description)
                }
            }
        }
    }

    private var dimView: some View {
        Color(white: 0)
            .opacity(0.5)
            .opacity(backgroundOpacity)
            .onTapGesture {
                animate(isShown: false)
            }
    }

    func animate(isShown: Bool, completion: (() -> Void)? = nil) {
        switch isShown {
        case true:
            opacity = 0

            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1
                backgroundOpacity = 1
                scale = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion?()
            }

        case false:
            withAnimation(.easeOut(duration: 0.2)) {
                backgroundOpacity = 0
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion?()
                isPresented = false
            }
        }
    }
}
