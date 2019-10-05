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
            color = .confirmed
        case .unconfirmed:
            iconName = "questionmark.circle.fill"
            color = .unconfirmed
        case .declined:
            iconName = "xmark.circle.fill"
            color = .declined
        }
    }
}

extension PresentableStatus {
    static let confirmed = Self(iconName: "checkmark.circle.fill", color: .confirmed)
    static let unconfirmed = Self(iconName: "questionmark.circle.fill", color: .unconfirmed)
    static let declined = Self(iconName: "xmark.circle.fill", color: .declined)
}
extension PresentableStatus: CaseIterable {
    static var allCases: [PresentableStatus] {
        [.confirmed, .unconfirmed, .declined]
    }
}
