//
//  SelectableList.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

/// A drop in replacement for `List` to handles selection with checkmarks on the trailing edge.
struct SelectableList<Elements, Selection, RowContent>: View where Elements: RandomAccessCollection, Elements.Element: Identifiable, RowContent: View {
    
    typealias Element = Elements.Element
    
    var selection: Binding<Selection>
    var isElementSelected: (Binding<Selection>, Element.ID)->Binding<Bool>
    var elements: Elements
    var content: (Element) -> RowContent
    
    private init(_ elements: Elements, selection: Binding<Selection>, isElementSelected: @escaping (Binding<Selection>, Element.ID)->Binding<Bool>, @ViewBuilder content: @escaping (Element) -> RowContent) {
        self.elements = elements
        self.selection = selection
        self.isElementSelected = isElementSelected
        self.content = content
    }
    
    var body: some View {
        List(elements) { element in
            Toggle(isOn: self.isElementSelected(self.selection, element.id)) {
                self.content(element)
            }
            //.toggleStyle(CheckmarkStyle())
        }
    }
}

extension SelectableList where Selection == Set<Element.ID> {
    /// Configure for muli selection.
    init(_ elements: Elements, selection: Binding<Set<Element.ID>>, @ViewBuilder content: @escaping (Element) -> RowContent) {
        
        self.init(elements, selection: selection, isElementSelected: does(_:contain:), content: content)
    }
}

extension SelectableList where Selection == Element.ID? {
    /// Configure for single selection.
    init(_ elements: Elements, selection: Binding<Element.ID?>, @ViewBuilder content: @escaping (Element) -> RowContent) {
        
        self.init(elements, selection: selection, isElementSelected: does(_:equal:), content: content)
    }
}

/// The UITableView checkmark style.
struct CheckmarkStyle: ToggleStyle {
    
    func makeBody(configuration: ToggleStyleConfiguration) -> some View {
        Toggle(isOn: configuration.$isOn, label: {configuration.label})
    }
    
    struct Toggle<Label: View>: View {
        @Binding var isOn: Bool
        var label: ()->Label
        
        var body: some View {
            Button(action: { self.isOn.toggle() }) {
                HStack {
                    label()
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isOn {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
}

struct SelectableListPreviews: PreviewProvider {
    static var people = ["Joe", "Sam", "Bob"]
    
    static var previews: some View {
        Group {
            ProvideState(initialValue: Optional<String>.some("Joe")) { selectedPerson in
                singleSelectList(people, selectedPerson)
            }.previewDisplayName("Single-select")

            ProvideState(initialValue: Set(["Joe"])) { selectedPeople in
                multiSelectList(people, selectedPeople)
            }.previewDisplayName("Multi-select")
        }
    }
    
    static func singleSelectList(_ people: [String], _ selection: Binding<String?>) -> some View {
        SelectableList(people.map { Identified($0, id: $0) }, selection: selection) { person in
            Text(verbatim: person.value)
        }
    }
    
    static func multiSelectList(_ people: [String], _ selection: Binding<Set<String>>) -> some View {
        SelectableList(people.map { Identified($0, id: $0) }, selection: selection) { person in
            Text(verbatim: person.value)
        }
    }
}
