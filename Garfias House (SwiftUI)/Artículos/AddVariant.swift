//
//  AddVariant.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 30/10/20.
//

import SwiftUI

struct AddVariant: View {
    
    @Binding var caducidad: Date
    @Binding var cantidad: Int
    
    var body: some View {
        Form {
            Section(header: Text("Caducidad")) {
                DatePicker("Ingresa la fecha de caducidad.", selection: $caducidad, in: Date()..., displayedComponents: .date)
                    .labelsHidden()
            }

            Section(header: Text("Cantidad")) {
                HStack {
                    TextField("", value: $cantidad, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                    Spacer()
                    Stepper("", value: $cantidad, in: 1...2000)
                        .labelsHidden()
                }
            }
        }
    }
}

//struct AddVariant_Previews: PreviewProvider {
//    static var previews: some View {
//        AddVariant()
//    }
//}
