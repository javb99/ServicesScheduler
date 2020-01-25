//
//  PlanBreakdownView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/23/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct PlanBreakdownView: View {
    var breakdown: FeedBreakdown
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                VStack {
                    PersonCircle(image: Image(systemName: "person.circle"), status: .confirmed)
                        .frame(width: 50)
                    ThreeDigitLabel(number: breakdown.confirmed)
                }
                VStack {
                    PersonCircle(image: Image(systemName: "person.circle"), status: .unconfirmed)
                    .frame(width: 50)
                    ThreeDigitLabel(number: breakdown.unconfirmed)
                }
                VStack {
                    PersonCircle(image: Image(systemName: "person.circle"), status: .declined)
                        .frame(width: 50)
                    ThreeDigitLabel(number: breakdown.declined)
                }
                VStack {
                    PersonCircle(image: Image(systemName: "plus.circle"), status: .unconfirmed)
                        .frame(width: 50)
                    ThreeDigitLabel(number: breakdown.needed)
                }
                VStack {
                    PersonCircle(image: Image(systemName: "envelope.circle"), status: .unconfirmed)
                        .frame(width: 50)
                    ThreeDigitLabel(number: breakdown.unsent)
                }
            }.font(.title)
        }
    }
}

struct PersonCircle: View {
    var image: Image
    var status: PresentableStatus
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(
                Circle().foregroundColor(Color(.systemFill))
            )
            .overlay(GeometryReader { geo in
                StatusCircle(status: self.status)
                    .frame(width: 0.4 * geo.size.width, height: 0.4 * geo.size.height)
                    .frame(maxWidth: .greatestFiniteMagnitude,
                           maxHeight: .greatestFiniteMagnitude,
                           alignment: .bottomTrailing)
            })
    }
}

struct ThreeDigitLabel: View {
    
    var number: Int
    
    var clampedNumber: Int {
        min(max(number, 0), 999)
    }
    
    var body: some View {
        ZStack {
            styleText("000")
                .opacity(0)
            
            styleText("\(clampedNumber)")
                .layoutPriority(-1) // Size based on text with 000
        }
    }
    
    func styleText(_ text: String) -> some View {
        Text(text)
    }
}

struct LabeledCountCircle: View {
    var color: Color
    var count: Int
    
    var body: some View {
        ThreeDigitLabel(number: count)
            .font(.headline)
            .padding()
            .background(Circle().fill(color))
    }
}

struct PlanBreakdownView_Previews: PreviewProvider {
    static var previews: some View {
        PlanBreakdownView(breakdown: FeedBreakdown(confirmed: 2, unconfirmed: 3, declined: 1, needed: 5, unsent: 2))
            .frame(height: 200)
            .previewLayout(.sizeThatFits)
    }
}
