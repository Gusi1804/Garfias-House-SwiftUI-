//
//  Articulo.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 29/10/20.
//

import SwiftUI

struct Articulo: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Evian")
                        .bold()
                    Text("1 L")
                        .font(.subheadline)
                }
            }
            Spacer()
            HStack {
                numInCircle(number: 4, color: .red)
                numInCircle(number: 5, color: .orange)
                numInCircle(number: 1, color: Color(UIColor.systemTeal))
                numInCircle(number: 2, color: .green)
            }
        }.padding()
    }
}

@ViewBuilder
func numInCircle(number: Int?, color: Color) -> some View {
    ZStack {
        Circle()
            .foregroundColor(color)
        Text(String(number ?? 0))
            .foregroundColor(.white)
            .font(.system(.caption, design: .rounded))
            .bold()
    }
    .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    .padding(.trailing, 0)
}


/*
@available(iOS 15.0, *)
@ViewBuilder
func numInCircle(for item: Binding<ItemNewS>, status: Estado) -> some View {
    ZStack {
        Circle()
            .foregroundColor(status.color())
        if (status == .Rojo) {
            Text(String(item.wrappedValue.red))
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
        if (status == .Naranja) {
            Text(String(item.wrappedValue.orange))
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
        if (status == .Teal) {
            Text(String(item.wrappedValue.teal))
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
        if (status == .Verde) {
            Text(String(item.wrappedValue.green))
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
    }
    .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    .padding(.trailing, 0)
}
 */

@available(iOS 15.0, *)
extension Estado {
    func color() -> Color {
        switch(self) {
        case .Rojo:
            return .red
        case .Naranja:
            return .orange
        case .Teal:
            return .teal
        case .Verde:
            return .green
        }
    }
}

/*
struct numInCircle: View {
    @State var number: Int?
    @State var color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(color)
            Text(String(number ?? 0))
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
            .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .padding(.trailing, 0)
    }
}
 */

struct strInCircle: View {
    
    var str: String!
    var color: Color!
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(color)
            Text(str)
                .foregroundColor(.white)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
        .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

struct Articulo_Previews: PreviewProvider {
    static var previews: some View {
        Articulo()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
