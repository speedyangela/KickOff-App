//
//  DirectView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct DirectView: View {
    var body: some View {
        NavigationStack {
            Text("Le chat en direct arrive bientôt.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .navigationTitle("Direct")
                .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

