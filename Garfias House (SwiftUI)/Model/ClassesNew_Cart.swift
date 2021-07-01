//
//  ClassesNew_Cart.swift
//  G House (iOS 15, *)
//
//  Created by Gustavo Garfias on 28/06/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreMedia

struct CartItem: Hashable, Codable, Identifiable {
    
    var id: Identifier = Identifier(string: String(length: 20))
    
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.id == rhs.id && lhs.cantidad == rhs.cantidad && lhs.item == rhs.item
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var item: ItemNewS
    
    var cantidad: Int!
    
    init (_ item: ItemNewS = ItemNewS(empty: true), cantidad: Int = 1) {
        self.item = item
        self.id = item.id
        self.cantidad = cantidad
    }
    
    enum CodingKeys: String, CodingKey {
        case cantidad
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cantidad = try values.decode(Int.self, forKey: .cantidad)
        
        id = Identifier(string: String(length: 20))
        
        var tmp = ItemNewS(empty: true)
        tmp.id = id
        
        self.item = tmp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cantidad, forKey: .cantidad)
    }
}

extension CartItem {
    static let previewData: [CartItem] = [
        //Agua Evian
        CartItem(ItemNewS(id: "hbsdu78ayAVGAJ", nombre: "Evian", categoría: .Bebidas, contenido: "1 L", barcode: "061314000070", variedades: [VariedadNewS(cantidad: 18, abierto: false, caducidad: Date())], favorito: true)),
        //Agua Fiji
        CartItem(ItemNewS(id: "uduhc8w7agybj", nombre: "Fiji", categoría: .Bebidas, contenido: "1 L", barcode: "632565000029", variedades: [VariedadNewS(cantidad: 1, abierto: false, caducidad: Date())], favorito: false)),
        //Lala 100 Plata
        CartItem(ItemNewS(id: "osajdo8whd8an", nombre: "Lala 100 - Plata", categoría: .Lácteos, contenido: "1 L", barcode: "0750102054844", variedades: [VariedadNewS(cantidad: 1, abierto: true, caducidad: Date())], favorito: false)),
        //Paletas de limón
        CartItem(ItemNewS(id: "dhdiusdiuwh736", nombre: "Paletas de Limón", categoría: .Congelados, contenido: "4 pzs", barcode: "7500326536885", variedades: [VariedadNewS(cantidad: 1, abierto: true, caducidad: Date())], favorito: false)),
        //Axe
        CartItem(ItemNewS(id: "47723bhjwebhbdywe", nombre: "Axe Dark Temptation", categoría: .Higiene, contenido: "175 mL", barcode: "7506306217188", variedades: [VariedadNewS(cantidad: 1, abierto: true, caducidad: Date())], favorito: false))
    ]
}

struct CartStore {
    var _all: [CartItem]
    
    var all: [CartItem] {
        get { _all }
        set {
            _all = newValue
            sortAll()
        }
    }
    
    init(_ items: [CartItem]) {
        _all = items
        sortAll()
    }
    
    mutating func sortAll() {
        _all.sort(by: {$0.item.nombre < $1.item.nombre})
    }
}
