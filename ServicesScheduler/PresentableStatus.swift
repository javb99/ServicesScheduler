//
//  PresentableStatus.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI
import PlanningCenterSwift

struct PresentableStatus {
    var iconName: String
    var color: Color
}

extension PresentableStatus {
    init(_ status: Models.PlanPerson.Status) {
        switch status {
        case .confirmed:
            iconName = "checkmark.circle.fill"
            color = .green
        case .unconfirmed:
            iconName = "questionmark.circle.fill"
            color = .yellow
        case .declined:
            iconName = "xmark.circle.fill"
            color = .red
        }
    }
}

extension PresentableStatus {
    static let confirmed = Self(iconName: "checkmark.circle.fill", color: .green)
    static let unconfirmed = Self(iconName: "questionmark.circle.fill", color: .yellow)
    static let declined = Self(iconName: "xmark.circle.fill", color: .red)
}
extension PresentableStatus: CaseIterable {
    static var allCases: [PresentableStatus] {
        [.confirmed, .unconfirmed, .declined]
    }
}
