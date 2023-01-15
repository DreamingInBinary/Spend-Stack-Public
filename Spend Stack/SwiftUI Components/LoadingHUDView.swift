//
//  LoadingHUDView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 3/10/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI

struct LoadingHUDView: View {
    var loadingHudText: String
    private let heightWidth:CGFloat = 220.0
    private let chromeColorView = Color(UIColor.secondaryLabel)
    
    @State private var animScale:CGFloat = 0.8
    @State private var hudOpacity = 0.0
    
    
    var body: some View {
        VStack(spacing: 26.0) {
            SpinnerView(preferredTint: UIColor.secondaryLabel)
            Text(loadingHudText)
              .font(.system(size: 24, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
                
        }
        .foregroundColor(chromeColorView)
        .background(
            BlurView(style: .systemThinMaterial)
                .frame(width: heightWidth, height: heightWidth)
        )
        .scaleEffect(animScale)
        .opacity(hudOpacity)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation {
                self.animScale = 1.0
                self.hudOpacity = 1.0
            }
        }
    }
}

struct LoadingHUDView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingHUDView(loadingHudText: "Dowloading\nShared List")
    }
}

// MARK: UIKit blur

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        blurView.layer.cornerCurve = .continuous
        blurView.layer.cornerRadius = 8
        blurView.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<BlurView>) {

    }

}

struct SpinnerView: UIViewRepresentable {
    let preferredTint:UIColor
    
    func makeUIView(context: UIViewRepresentableContext<SpinnerView>) -> UIView {
        let view = UIActivityIndicatorView(style: .large)
        view.tintColor = preferredTint
        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<SpinnerView>) {
        let spinner:UIActivityIndicatorView = uiView as! UIActivityIndicatorView
        spinner.startAnimating()
    }

}
