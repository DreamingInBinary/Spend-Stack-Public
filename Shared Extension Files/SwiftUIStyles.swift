//
//  SwiftUIStyles.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 9/14/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: Custom view modifiers
struct DebugBorder: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content.overlay(Rectangle().stroke(color))
    }
}

// MARK: Modifiers applied to view
extension View {
    func debugBorder(color: Color = .blue) -> some View {
        self.modifier(DebugBorder(color: color))
    }
}

extension Text {
    func primaryColor() -> some View {
        self.foregroundColor(Color("PrimaryFont"))
    }
    
    func lightPrimaryColor() -> some View {
        self.foregroundColor(Color("LightPrimary"))
    }
    
    func secondaryColor() -> some View {
        self.foregroundColor(Color("SecondaryFont"))
    }
}
