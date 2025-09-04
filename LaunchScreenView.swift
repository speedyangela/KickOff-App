//
//  LaunchScreenView.swift
//  Kickoff
//
//  Created by Angela Lagache on 04/09/2025.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.90) // ton beige de fond
                .ignoresSafeArea()
            Image("KickoffLogo") // ajoute ton logo dans Assets.xcassets
                .resizable()
                .scaledToFit()
                .frame(width: 220) // ajuste la taille
        }
    }
}
