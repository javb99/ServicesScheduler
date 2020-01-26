//
//  OperationStatusIndicator.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/25/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

public struct OperationStatusView: View {
    var status: OperationStatus
    
    public var body: some View {
        HStack {
            Text("\(status.text)")
                .foregroundColor(status.textColor)
            if status.shouldShowSpinner {
                IsVisibleView {
                    LoadingIndicator(isSpinning: $0){
                        Image(systemName: "arrow.2.circlepath")
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(
            Capsule().foregroundColor(status.fillColor)
        )
    }
}

struct AnimatedOperationStatus: View {
    var status: OperationStatus
    
    var body: some View {
        ZStack {
            ForEach(OperationStatus.allCases, id: \.self) { thisStatus in
                self.view(for: thisStatus)
            }
        }.padding()
    }
    
    func isVisible(_ thisStatus: OperationStatus) -> Bool {
        status == thisStatus && thisStatus != .notActive
    }
    
    func view(for thisStatus: OperationStatus) -> some View {
        OperationStatusView(status: thisStatus)
            .opacity(isVisible(thisStatus) ? 1 : 0)
            .offset(x: 0, y: isVisible(thisStatus) ? 0 : -100)
            .animation(.spring())
    }
}

extension OperationStatus {
    var fillColor: Color {
        switch self {
        case .notActive:
            return Color(.systemFill)
        case .errorDisplayed:
            return Color(.systemRed).opacity(0.5)
        case .successDisplayed:
            return Color(.systemGreen).opacity(0.5)
        case .active:
            return Color(.systemFill)
        }
    }
    var textColor: Color {
        switch self {
        case .notActive:
            return Color(.label)
        case .errorDisplayed:
            return Color(.label)
        case .successDisplayed:
            return Color(.label)
        case .active:
            return Color(.label)
        }
    }
    var text: String {
        switch self {
        case .notActive:
            return ""
        case .errorDisplayed:
            return "Failed"
        case .successDisplayed:
            return "Success"
        case .active:
            return "Loading"
        }
    }
    var shouldShowSpinner: Bool {
        switch self {
        case .notActive, .errorDisplayed, .successDisplayed:
            return false
        case .active:
            return true
        }
    }
}

extension OperationStatus: CaseIterable, Equatable {
    public static var allCases: [OperationStatus] {
        [.notActive, .active, .successDisplayed, .errorDisplayed]
    }
}

struct OperationStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ProvideState(initialValue: OperationStatus.notActive) { statusBinding in
            LightAndDark {
                VStack {
                    AnimatedOperationStatus(status: statusBinding.wrappedValue)
                    Button(action: { statusBinding.wrappedValue = OperationStatus.allCases.randomElement()! }) {
                        Text("Toggle").padding()
                    }
                    
                    ForEach(OperationStatus.allCases, id: \.self) { status in
                        OperationStatusView(status: status)
                    }.padding()
                }//.previewLayout(.sizeThatFits)
                   .background(Color(.systemBackground))
            }//.font(.largeTitle)
        }
    }
}
