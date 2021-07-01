//
//  Classes.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 29/10/20.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI

class ItemShort: Hashable, Codable, Identifiable {
    
    static func == (lhs: ItemShort, rhs: ItemShort) -> Bool {
        return lhs.iD == rhs.iD
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(iD)
    }
    
    init(item: Item, cantidad: Int) {
        self.nombre = item.nombre
        self.categoría = item.categoría
        self.contenido = item.contenido
        if let bc = item.barcode {
            self.barcode = bc
        }
        self.iD = item.iD
        self.cantidad = cantidad
    }
    
    enum CodingKeys: String, CodingKey {
        case nombre
        case categoría
        case contenido
        case barcode
        case cantidad
    }
    
    var nombre: String!
    var categoría: String!
    var contenido: String!
    
    var barcode: String?
    
    var iD: String!
    
    var cantidad: Int!
    
}

class Item: Hashable, Codable, Identifiable, ObservableObject {
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.nombre == rhs.nombre && lhs.contenido == lhs.contenido && lhs.categoría == rhs.categoría && lhs.barcode == rhs.barcode && lhs.cantAlert == rhs.cantAlert && lhs.cadAlert == rhs.cantAlert && lhs.variedades == rhs.variedades
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(iD)
    }
    
    enum CodingKeys: String, CodingKey {
        case nombre
        case categoría
        case contenido
        case barcode
        case cantAlert
        case cadAlert
        case variedades
    }
    
    var nombre: String!
    var categoría: String!
    var contenido: String!
    
    var barcode: String?
    
    var cantAlert: Int!
    var alert = false
    var cadAlert: Int?
    
    var iD: String!
    
    var variedades: [Variedad]?
    
    @Published var selected = false
    @Published var quantity = 0
    
    func getGlobalNumbers() {
        var res = [Status:Int]()
        
        var green = 0
        var teal = 0
        var orange = 0
        var red = 0
        
        for variedad in self.variedades ?? [Variedad]() {
            switch (variedad.status) {
            case .Red:
                red += variedad.cantidad
            case .Orange:
                orange += variedad.cantidad
            case .Teal:
                teal += variedad.cantidad
            case .Green:
                green += variedad.cantidad
            case .none:
                break
            }
        }
        
        //res[.Red] = red
        self.redN = red
        self.orangeN = orange
        self.tealN = teal
        self.greenN = green
        //res[.Orange] = orange
        //res[.Teal] = teal
        //res[.Green] = green
        
    }
    
    var redN: Int = 0
    var orangeN: Int = 0
    var tealN: Int = 0
    var greenN: Int = 0
    
    func getStatus() {
        var useful = 0 //Cantidad de objetos útiles, en estado verde o naranja
        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        
        if let varieties = self.variedades {
            for variedad in varieties {
                print("Caducidad: \(variedad.caducidad), Cantidad: \(variedad.cantidad)")
                if (variedad.open != true) {
                    if variedad.caducidad != nil {
                        let caducidad = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: variedad.caducidad!)!
                        
                        if (caducidad < today) {
                            variedad.status = .Red
                            //break
                        } else {
                            let días = calendar.dateComponents([.day], from: today, to: caducidad).day
                            if (días! <= cantAlert) {
                                variedad.status = .Orange
                                useful += variedad.cantidad
                                //break
                            } else {
                                useful += variedad.cantidad
                                if (variedad.open != true) {
                                    variedad.status = .Green
                                } else {
                                    variedad.status = .Teal
                                }
                                //break
                            }
                        }
                    } else {
                        variedad.status = .Green
                    }
                } else if (variedad.open == true) {
                    variedad.status = .Teal
                }
                print (variedad.status)
            }
            if (useful <= cantAlert) {
                self.alert = true
            }
        }
    }
}

class Variedad: Hashable, Codable, Identifiable {
    
    static func == (lhs: Variedad, rhs: Variedad) -> Bool {
        lhs.cantidad == rhs.cantidad && lhs.caducidadFB == rhs.caducidadFB && lhs.open == rhs.open
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(cantidad)
        if caducidadFB != nil {
            hasher.combine(caducidadFB)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case caducidadFB
        case cantidad
        case open
    }
    
    var caducidadFB: Timestamp?
    var cantidad: Int!
    var open = false
    
    var caducidad: Date? {
        if let cad = caducidadFB {
            return caducidadFB?.dateValue()
        } else {
            return nil
        }
    }
    
    var status: Status?
}

enum Status: Int, Codable {
    case Red
    case Orange
    case Teal
    case Green
}
