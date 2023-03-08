//
//  Classes_New.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias on 11/06/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreMedia

// MARK: -Categoría Enum
enum Categoría: String, Codable, Equatable, CaseIterable, Identifiable {
    
    case Abarrotes
    case Bebidas
    case Congelados
    case FrutasYVerduras = "Frutas y Verduras"
    case Higiene
    case Lácteos
    case Limpieza
    case Medicamentos
    case PanaderíaYTortillería = "Panadería y Tortillería"
    case Salchichonería
    
    var id: String { self.rawValue }
}

// MARK: -ItemNewS
//@available(iOS 15.0, *)
struct ItemNewS: Hashable, Codable, Identifiable {
    
    var id: Identifier = Identifier(string: String(length: 20))
    
    static func == (lhs: ItemNewS, rhs: ItemNewS) -> Bool {
        return lhs.id == rhs.id && lhs.nombre == rhs.nombre && lhs.categoría == rhs.categoría && lhs.contenido == rhs.contenido && lhs.barcode == rhs.barcode && lhs.variedades == rhs.variedades && lhs.favorito == rhs.favorito && lhs.alert == rhs.alert && lhs.itemStatus == rhs.itemStatus && lhs.quantityAlertString == rhs.quantityAlertString && lhs.expiryDateAlertString == rhs.expiryDateAlertString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case nombre
        case categoría
        case contenido
        case barcode
        case variedades
        case quantityAlert = "cantAlert"
        case expiryDateAlert = "cadAlert"
        case favorito
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        nombre = try values.decode(String.self, forKey: .nombre)
        categoría = try values.decode(Categoría.self, forKey: .categoría)
        contenido = try values.decode(String.self, forKey: .contenido)
        barcode = try values.decode(String.self, forKey: .barcode)
        variedades = try values.decode([VariedadNewS].self, forKey: .variedades)
        quantityAlert = try values.decode(Int.self, forKey: .quantityAlert)
        expiryDateAlert = try values.decode(Int.self, forKey: .expiryDateAlert)
        favorito = try values.decode(Bool.self, forKey: .favorito)
    }
    
    init(id: String, nombre: String, categoría: Categoría, contenido: String, barcode: String? = "", variedades: [VariedadNewS] = [], favorito: Bool = false, quantityAlert: Int = 2, expiryDateAlert: Int? = 10) {
        self.id = Identifier(string: id)
        self.nombre = nombre
        self.categoría = categoría
        self.contenido = contenido
        if let barcode = barcode {
            self.barcode = barcode
        }
        self.variedades = variedades
        self.favorito = favorito
        self.quantityAlert = quantityAlert
        self.expiryDateAlert = expiryDateAlert
        
        self.setStatusForVarieties()
    }
    
    mutating func update(_ new: ItemNewS) {
        self.nombre = new.nombre
        self.categoría = new.categoría
        self.contenido = new.contenido
        if let barcode = new.barcode {
            self.barcode = barcode
        }
        self.variedades = new.variedades
        self.favorito = new.favorito
        self.quantityAlert = new.quantityAlert
        self.expiryDateAlert = new.expiryDateAlert
        
        self.setStatusForVarieties()
    }
    
    init() {
        
    }
    
    var nombre: String!
    var categoría: Categoría!
    var contenido: String!
    var barcode: String!
    var variedades: [VariedadNewS] = []
    var favorito = false
    
    var itemStatus: [Estado: Int] = [
        .Rojo: 0,
        .Naranja: 0,
        .Teal: 0,
        .Verde: 0
    ]
    
    var alert: Bool = false
    var quantityAlert: Int!
    var quantityAlertString: String {
        get {
            if quantityAlert != nil {
                return String(quantityAlert)
            } else {
                return ""
            }
        }
        set {
            if (newValue != "" || newValue != nil) {
                quantityAlert = Int(newValue)
            } else {
                quantityAlert = 0
            }
        }
    }
    
    var expiryDateAlert: Int!
    var expiryDateAlertString: String {
        get {
            if expiryDateAlert != nil {
                return String(expiryDateAlert)
            } else {
                return ""
            }
        }
        set {
            if (newValue != "" || newValue != nil) {
                expiryDateAlert = Int(newValue)
            } else {
                expiryDateAlert = 0
            }
        }
    }
    
    var remainingDays = [VariedadNewS: Int]()
    
    mutating func setStatusForVarieties() {
        var useful = 0 //Amount of useful varieties
        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        
        //Quantities for each status
        var red = 0
        var orange = 0
        var teal = 0
        var green = 0
        
        self.variedades = self.variedades.map({ variedad in
            var tmp = variedad
            
            //Check for expiry date
            if variedad.caducidad != nil { //Check if there is an expiry date
                print("EXPIRY DATE AVAILABLE")
                let caducidad = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: variedad.caducidad!)!
                
                if (caducidad < today) { //1. Check if variety has expired
                    print("Expired")
                    tmp.status = Estado.Rojo
                    red += variedad.cantidad
                } else {
                    let días = calendar.dateComponents([.day], from: today, to: caducidad).day
                    
                    if let días = días {
                        self.remainingDays[tmp] = días
                        
                        if let expiryDateAlert = expiryDateAlert { //2. Check if variety is about to expire
                            if (días < expiryDateAlert) {
                                print("About to expire")
                                tmp.status = Estado.Naranja
                                useful += variedad.cantidad
                                orange += variedad.cantidad
                            } else {
                                useful += variedad.cantidad
                                if (variedad.abierto == true) { //3. Check if variety is  open
                                    print("Open")
                                    tmp.status = Estado.Teal
                                    useful += variedad.cantidad
                                    teal += variedad.cantidad
                                } else { //4. Variety is not open
                                    print("Okay")
                                    tmp.status = Estado.Verde
                                    useful += variedad.cantidad
                                    green += variedad.cantidad
                                }
                            }
                        }
                    }
                }
            } else { //There is no expiry date
                print("NO EXPIRY DATE")
                if (variedad.abierto == true) { //3. Check if variety is  open
                    print("Open")
                    tmp.status = Estado.Teal
                    useful += variedad.cantidad
                    teal += variedad.cantidad
                } else { //4. Variety is not open
                    print("Okay")
                    tmp.status = Estado.Verde
                    useful += variedad.cantidad
                    green += variedad.cantidad
                }
            }
            
            print("\(tmp.status)")
            return tmp
        })
        
        //Check if there are more useful items than the alert quantity
        if (useful < quantityAlert) {
            alert = true
        }
        
        self.itemStatus[.Verde] = green
        self.itemStatus[.Teal] = teal
        self.itemStatus[.Naranja] = orange
        self.itemStatus[.Rojo] = red
        
        //self.variedades.sort(by: >)
    }
}

// MARK: VariedadNewS
//@available(iOS 15.0, *)
struct VariedadNewS: Hashable, Codable, Identifiable {
    
    init(cantidad: Int = 1, abierto: Bool = false, caducidad: Date? = nil, id: String = "") {
        self.cantidad = cantidad
        self.abierto = abierto
        if let caducidad = caducidad {
            self.caducidadFB = Timestamp(date: caducidad)
        } else {
            self.caducidadFB = nil
        }
        
        if id != "" {
            self.id = Identifier(string: id)
        } else {
            self.id = Identifier(string: String(length: 20))
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cantidad = try values.decode(Int.self, forKey: .cantidad)
        abierto = try values.decode(Bool.self, forKey: .abierto)
        let idStr = try values.decode(String.self, forKey: .id)
        
        id = Identifier(string: idStr)
        
        do {
            caducidadFB = try values.decode(Timestamp.self, forKey: .caducidadFB)
            print("\(id): \(caducidadFB?.dateValue())")
        } catch {
            caducidadFB = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cantidad, forKey: .cantidad)
        try container.encode(abierto, forKey: .abierto)
        try container.encode(id.string, forKey: .id)
        if let caducidadFB = caducidadFB {
            try container.encode(caducidadFB, forKey: .caducidadFB)
        }
    }
    
    static func == (lhs: VariedadNewS, rhs: VariedadNewS) -> Bool {
        return lhs.caducidad == rhs.caducidad && lhs.cantidad == rhs.cantidad && lhs.abierto == rhs.abierto && lhs.id == rhs.id && lhs.status == rhs.status && lhs.color == rhs.color
    }
    /*
    static func < (lhs: VariedadNewS, rhs: VariedadNewS) -> Bool {
        if let lhsStat = lhs.status, let rhsStat = rhs.status {
            if let lhsCad = lhs.caducidad, let rhsCad = lhs.caducidad {
                return (lhsCad, lhsStat) < (rhsCad, rhsStat)
            } else {
                return lhsStat < rhsStat
            }
        } else {
            return true
        }
    }
     */
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case caducidadFB
        case cantidad
        case abierto = "open"
        case id
    }
    
    var caducidadFB: Timestamp?
    var cantidad: Int!
    var abierto = false
    
    var id: Identifier
    
    var cantidadString: String {
        set {
            if let cantidad = Int(newValue) {
                self.cantidad = cantidad
            } else {
                self.cantidad = 0
            }
        }
        
        get {
            return String(cantidad)
        }
    }
    
    var caducidad: Date? {
        get {
            if caducidadFB != nil {
                return caducidadFB?.dateValue()
            } else { return nil }
        }
        set {
            if let caducidad = newValue {
                caducidadFB = Timestamp(date: caducidad)
            }
        }
    }
    
    var status: Estado?
    
    var color: Color {
        if let status = status {
            switch status {
            case .Rojo:
                return .red
            case .Naranja:
                return .orange
            case .Teal:
                if #available(iOS 15.0, *) {
                    return .teal
                } else {
                    // Fallback on earlier versions
                    return Color(.systemTeal)
                }
            case .Verde:
                return .green
            }
        } else {
            return .green
        }
    }
    
    var caducidadString: String? {
        if let caducidad = caducidad {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            
            return dateFormatter.string(from: caducidad)
        } else {
            return nil
        }
    }
}

struct Identifier: Hashable, Codable {
    let string: String
}

extension Identifier: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        string = value
    }
}

extension Identifier: CustomStringConvertible {
    var description: String {
        return string
    }
}

// MARK: Estado
enum Estado: Int, Codable, Comparable {
    static func < (lhs: Estado, rhs: Estado) -> Bool {
        return lhs.comparisonValue < rhs.comparisonValue
    }
    
    case Rojo
    case Naranja
    case Teal
    case Verde
    
    private var comparisonValue: Int {
        switch self {
        case .Rojo:
            return 0
        case .Naranja:
            return 3
        case .Teal:
            return 2
        case .Verde:
            return 1
        }
    }
}

// MARK: ItemStoreS
//@available(iOS 15.0, *)
struct ItemStoreS {
    var _all: [ItemNewS]
    
    var all: [ItemNewS] {
        get { _all }
        set {
            _all = newValue
            sortAll()
        }
    }
    
    func matchesCount(searchText: String) -> Int {
        return all.filter({$0.nombre.contains(searchText)}).count
    }
    
    func favouritesFiltered(searchText: String) -> [ItemNewS] {
        return favoritos.filter({$0.nombre.contains(searchText)})
    }
    
    func sectionFiltered(category: Categoría, searchText: String) -> [ItemNewS] {
        switch(category) {
        case .Abarrotes:
            return abarrotes.filter({$0.nombre.contains(searchText)})
        case .Bebidas:
            return bebidas.filter({$0.nombre.contains(searchText)})
        case .Congelados:
            return congelados.filter({$0.nombre.contains(searchText)})
        case .FrutasYVerduras:
            return frutasYVerduras.filter({$0.nombre.contains(searchText)})
        case .Higiene:
            return higiene.filter({$0.nombre.contains(searchText)})
        case .Lácteos:
            return lácteos.filter({$0.nombre.contains(searchText)})
        case .Limpieza:
            return limpieza.filter({$0.nombre.contains(searchText)})
        case .Medicamentos:
            return medicamentos.filter({$0.nombre.contains(searchText)})
        case .PanaderíaYTortillería:
            return panaderíaYTortillería.filter({$0.nombre.contains(searchText)})
        case .Salchichonería:
            return salchichonería.filter({$0.nombre.contains(searchText)})
        }
    }
    
    var favoritos: [ItemNewS] {
        get {
            all.filter({$0.favorito == true})
        }
        set {
            all.removeAll(where: {$0.favorito == true})
            all.append(contentsOf: newValue)
        }
    }
    
    var bebidas: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Bebidas && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Bebidas})
            all.append(contentsOf: newValue)
        }
    }
    
    var abarrotes: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Abarrotes && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Abarrotes})
            all.append(contentsOf: newValue)
        }
    }
    
    var lácteos: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Lácteos && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Lácteos})
            all.append(contentsOf: newValue)
        }
    }
    
    var frutasYVerduras: [ItemNewS] {
        get {
            all.filter({$0.categoría == .FrutasYVerduras && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .FrutasYVerduras})
            all.append(contentsOf: newValue)
        }
    }
    
    var salchichonería: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Salchichonería && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Salchichonería})
            all.append(contentsOf: newValue)
        }
    }
    
    var panaderíaYTortillería: [ItemNewS] {
        get {
            all.filter({$0.categoría == .PanaderíaYTortillería && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .PanaderíaYTortillería})
            all.append(contentsOf: newValue)
        }
    }
    
    var congelados: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Congelados && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Congelados})
            all.append(contentsOf: newValue)
        }
    }
    
    var limpieza: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Limpieza && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Limpieza})
            all.append(contentsOf: newValue)
        }
    }
    
    var medicamentos: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Medicamentos && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Medicamentos})
            all.append(contentsOf: newValue)
        }
    }
    
    var higiene: [ItemNewS] {
        get {
            all.filter({$0.categoría == .Higiene && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Higiene})
            all.append(contentsOf: newValue)
        }
    }
    
    init(_ items: [ItemNewS]) {
        _all = items
        sortAll()
    }
    
    mutating func sortAll() {
        _all.sort(by: {$0.nombre < $1.nombre})
    }
}

// MARK: - ItemStore (deprecated)
@available(iOS 15.0, *)
struct ItemStore {
    var _all: [ItemNew]
    
    var all: [ItemNew] {
        get { _all }
        set {
            _all = newValue
            sortAll()
        }
    }
    
    var allArray: [Categoría: [ItemNew]] {
        get {
            return [
                .Abarrotes: abarrotes,
                .Bebidas: bebidas,
                .Congelados: congelados,
                .FrutasYVerduras: frutasYVerduras,
                .Higiene: higiene,
                .Lácteos: lácteos,
                .Limpieza: limpieza,
                .Medicamentos: medicamentos,
                .PanaderíaYTortillería: panaderíaYTortillería,
                .Salchichonería: salchichonería,
            ]
        }
    }
    
    func matchesCount(searchText: String) -> Int {
        return all.filter({$0.nombre.contains(searchText)}).count
    }
    
    func favouritesFiltered(searchText: String) -> [ItemNew] {
        return favoritos.filter({$0.nombre.contains(searchText)})
    }
    
    func sectionFiltered(category: Categoría, searchText: String) -> [ItemNew] {
        switch(category) {
        case .Abarrotes:
            return abarrotes.filter({$0.nombre.contains(searchText)})
        case .Bebidas:
            return bebidas.filter({$0.nombre.contains(searchText)})
        case .Congelados:
            return congelados.filter({$0.nombre.contains(searchText)})
        case .FrutasYVerduras:
            return frutasYVerduras.filter({$0.nombre.contains(searchText)})
        case .Higiene:
            return higiene.filter({$0.nombre.contains(searchText)})
        case .Lácteos:
            return lácteos.filter({$0.nombre.contains(searchText)})
        case .Limpieza:
            return limpieza.filter({$0.nombre.contains(searchText)})
        case .Medicamentos:
            return medicamentos.filter({$0.nombre.contains(searchText)})
        case .PanaderíaYTortillería:
            return panaderíaYTortillería.filter({$0.nombre.contains(searchText)})
        case .Salchichonería:
            return salchichonería.filter({$0.nombre.contains(searchText)})
        }
    }
    
    var favoritos: [ItemNew] {
        get {
            all.filter({$0.favorito == true})
        }
        set {
            all.removeAll(where: {$0.favorito == true})
            all.append(contentsOf: newValue)
        }
    }
    
    var bebidas: [ItemNew] {
        get {
            all.filter({$0.categoría == .Bebidas && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Bebidas})
            all.append(contentsOf: newValue)
        }
    }
    
    var abarrotes: [ItemNew] {
        get {
            all.filter({$0.categoría == .Abarrotes && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Abarrotes})
            all.append(contentsOf: newValue)
        }
    }
    
    var lácteos: [ItemNew] {
        get {
            all.filter({$0.categoría == .Lácteos && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Lácteos})
            all.append(contentsOf: newValue)
        }
    }
    
    var frutasYVerduras: [ItemNew] {
        get {
            all.filter({$0.categoría == .FrutasYVerduras && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .FrutasYVerduras})
            all.append(contentsOf: newValue)
        }
    }
    
    var salchichonería: [ItemNew] {
        get {
            all.filter({$0.categoría == .Salchichonería && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Salchichonería})
            all.append(contentsOf: newValue)
        }
    }
    
    var panaderíaYTortillería: [ItemNew] {
        get {
            all.filter({$0.categoría == .PanaderíaYTortillería && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .PanaderíaYTortillería})
            all.append(contentsOf: newValue)
        }
    }
    
    var congelados: [ItemNew] {
        get {
            all.filter({$0.categoría == .Congelados && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Congelados})
            all.append(contentsOf: newValue)
        }
    }
    
    var limpieza: [ItemNew] {
        get {
            all.filter({$0.categoría == .Limpieza && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Limpieza})
            all.append(contentsOf: newValue)
        }
    }
    
    var medicamentos: [ItemNew] {
        get {
            all.filter({$0.categoría == .Medicamentos && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Medicamentos})
            all.append(contentsOf: newValue)
        }
    }
    
    var higiene: [ItemNew] {
        get {
            all.filter({$0.categoría == .Higiene && !$0.favorito})
        }
        set {
            all.removeAll(where: {$0.categoría == .Higiene})
            all.append(contentsOf: newValue)
        }
    }
    
    init(_ items: [ItemNew]) {
        _all = items
        sortAll()
    }
    
    mutating func sortAll() {
        _all.sort(by: {$0.nombre < $1.nombre})
    }
}

// MARK: ItemNew (deprecated)
@available(iOS 15.0, *)
class ItemNew: Hashable, Codable, Identifiable, ObservableObject {
    
    init(id: String, nombre: String, categoría: Categoría, contenido: String, barcode: String? = "", variedades: [VariedadNew] = [], favorito: Bool = false, quantityAlert: Int = 2, expiryDateAlert: Int? = 10) {
        self.id = id
        self.nombre = nombre
        self.categoría = categoría
        self.contenido = contenido
        if let barcode = barcode {
            self.barcode = barcode
        }
        self.variedades = variedades
        self.favorito = favorito
        self.quantityAlert = quantityAlert
        self.expiryDateAlert = expiryDateAlert
        
        self.setStatusForVarieties()
    }
    
    init() {
        
    }
    
    static func == (lhs: ItemNew, rhs: ItemNew) -> Bool {
        return lhs.id == rhs.id && lhs.nombre == rhs.nombre && lhs.categoría == rhs.categoría && lhs.contenido == rhs.contenido && lhs.barcode == rhs.barcode && lhs.variedades == rhs.variedades && lhs.favorito == rhs.favorito
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case nombre
        case categoría
        case contenido
        case barcode
        case variedades
        case quantityAlert = "cantAlert"
        case expiryDateAlert = "cadAlert"
        case favorito
    }
    
    var id: String!
    
    var nombre: String!
    var categoría: Categoría!
    var contenido: String!
    var barcode: String!
    var variedades: [VariedadNew] = []
    var favorito = false
    
    var itemStatus: [Estado: Int] {
        get {
            var tmp: [Estado: Int] = [
                .Rojo: 0,
                .Naranja: 0,
                .Teal: 0,
                .Verde: 0
            ]
            for variedad in variedades {
                if let status = variedad.status {
                    if tmp[status] != nil {
                        tmp[status]! += variedad.cantidad
                    }
                }
            }
            
            return tmp
        }
    }
    
    var alert: Bool = false
    var quantityAlert: Int!
    var expiryDateAlert: Int?
    
    func setStatusForVarieties() {
        var useful = 0 //Amount of useful varieties
        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        
        for variedad in variedades {
            //Check for expiry date
            if variedad.caducidad != nil { //Check if there is an expiry date
                print("EXPIRY DATE AVAILABLE")
                let caducidad = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: variedad.caducidad!)!
                
                if (caducidad < today) { //1. Check if variety has expired
                    print("Expired")
                    variedad.status = .Rojo
                } else {
                    let días = calendar.dateComponents([.day], from: today, to: caducidad).day
                    if let expiryDateAlert = expiryDateAlert { //2. Check if variety is about to expire
                        if (días! <= expiryDateAlert) {
                            print("About to expire")
                            variedad.status = .Naranja
                            useful += variedad.cantidad
                        } else {
                            useful += variedad.cantidad
                            if (variedad.abierto == true) { //3. Check if variety is  open
                                print("Open")
                                variedad.status = .Teal
                            } else { //4. Variety is not open
                                print("Okay")
                                variedad.status = .Verde
                            }
                        }
                    }
                }
            } else { //There is no expiry date
                print("NO EXPIRY DATE")
                if (variedad.abierto == true) { //3. Check if variety is  open
                    print("Open")
                    variedad.status = .Teal
                } else { //4. Variety is not open
                    print("Okay")
                    variedad.status = .Verde
                }
            }
            
            print("\(variedad.status)")
        }
        
        //Check if there are more useful items than the alert quantity
        if (useful < quantityAlert) {
            self.alert = true
        }
    }
    
}

// MARK: VariedadNew (deprecated)
@available(iOS 15.0, *)
class VariedadNew: Hashable, Codable, Identifiable {
    
    init(cantidad: Int, abierto: Bool = false, caducidad: Date? = nil, id: String = "") {
        self.cantidad = cantidad
        self.abierto = abierto
        if let caducidad = caducidad {
            self.caducidadFB = Timestamp(date: caducidad)
        } else {
            self.caducidadFB = nil
        }
        
        if id != "" {
            self.id = id
        } else {
            self.id = String(length: 20)
        }
    }
    
    static func == (lhs: VariedadNew, rhs: VariedadNew) -> Bool {
        return lhs.caducidad == rhs.caducidad && lhs.cantidad == rhs.cantidad && lhs.abierto == rhs.abierto && lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case caducidadFB
        case cantidad
        case abierto = "open"
        case id
    }
    
    var caducidadFB: Timestamp?
    var cantidad: Int!
    var abierto = false
    
    var id: String
    
    var caducidad: Date? {
        get {
            if caducidadFB != nil {
                return caducidadFB?.dateValue()
            } else { return nil }
        }
        set {
            if let caducidad = newValue {
                caducidadFB = Timestamp(date: caducidad)
            }
        }
    }
    
    var status: Estado?
    
    var color: Color {
        if let status = status {
            switch status {
            case .Rojo:
                return .red
            case .Naranja:
                return .orange
            case .Teal:
                return .teal
            case .Verde:
                return .green
            }
        } else {
            return .green
        }
    }
    
    var caducidadString: String? {
        if let caducidad = caducidad {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            
            return dateFormatter.string(from: caducidad)
        } else {
            return nil
        }
    }
}

@available(iOS 15.0, *)
extension ItemNew {
    static let previewData: [ItemNew] = [
        //Agua Evian
        ItemNew(id: "hbsdu78ayAVGAJ", nombre: "Evian", categoría: .Bebidas, contenido: "1 L", barcode: "061314000070", variedades: [VariedadNew(cantidad: 18, abierto: false, caducidad: Date())], favorito: true),
        //Agua Fiji
        ItemNew(id: "uduhc8w7agybj", nombre: "Fiji", categoría: .Bebidas, contenido: "1 L", barcode: "632565000029", variedades: [VariedadNew(cantidad: 1, abierto: false, caducidad: Date())], favorito: false),
        //Lala 100 - Plata
        ItemNew(id: "osajdo8whd8an", nombre: "Lala 100 - Plata", categoría: .Lácteos, contenido: "1 L", barcode: "0750102054844", variedades: [VariedadNew(cantidad: 1, abierto: true, caducidad: Date())], favorito: false),
        //Paletas de Limón
        ItemNew(id: "dhdiusdiuwh736", nombre: "Paletas de Limón", categoría: .Congelados, contenido: "4 pzs", barcode: "7500326536885", variedades: [VariedadNew(cantidad: 1, abierto: true, caducidad: Date())], favorito: false),
        //Axe
        ItemNew(id: "47723bhjwebhbdywe", nombre: "Axe Dark Temptation", categoría: .Higiene, contenido: "175 mL", barcode: "7506306217188", variedades: [VariedadNew(cantidad: 1, abierto: true, caducidad: Date())], favorito: false),
    ]
    
    static let previewItem: ItemNew = ItemNew(id: "hbsdu78ayAVGAJ", nombre: "Evian", categoría: .Bebidas, contenido: "1 L", barcode: "061314000070", variedades: [VariedadNew(cantidad: 18, abierto: false, caducidad: Date())], favorito: true)
    
    static let emptyItem: ItemNew = ItemNew(id: "", nombre: "", categoría: .Abarrotes, contenido: "", barcode: "", variedades: [], favorito: false)
}

// MARK: ItemNewS previewData, previewItem, emptyItem, init(empty: Bool = true)
//@available(iOS 15.0, *)
extension ItemNewS {
    static let previewData: [ItemNewS] = [
        //Agua Evian
        ItemNewS(id: "hbsdu78ayAVGAJ", nombre: "Evian", categoría: .Bebidas, contenido: "1 L", barcode: "061314000070", variedades: [VariedadNewS(cantidad: 18, abierto: false, caducidad: Date())], favorito: false),
        //Agua Fiji
        ItemNewS(id: "uduhc8w7agybj", nombre: "Fiji", categoría: .Bebidas, contenido: "1 L", barcode: "632565000029", variedades: [VariedadNewS(cantidad: 1, abierto: false, caducidad: Date())], favorito: false),
        //Lala 100 - Plata
        ItemNewS(id: "osajdo8whd8an", nombre: "Lala 100 - Plata", categoría: .Lácteos, contenido: "1 L", barcode: "0750102054844", variedades: [VariedadNewS(cantidad: 1, abierto: true, caducidad: Date())], favorito: false),
        //Paletas de Limón
        ItemNewS(id: "dhdiusdiuwh736", nombre: "Paletas de Limón", categoría: .Congelados, contenido: "4 pzs", barcode: "7500326536885", variedades: [VariedadNewS(cantidad: 1, abierto: true, caducidad: Date())], favorito: false),
        //Axe
        ItemNewS(id: "47723bhjwebhbdywe", nombre: "Axe Dark Temptation", categoría: .Higiene, contenido: "175 mL", barcode: "7506306217188", variedades: [VariedadNewS(cantidad: 1, abierto: true, caducidad: Date())], favorito: false),
    ]
    
    static let previewItem: ItemNewS = ItemNewS(id: "hbsdu78ayAVGAJ", nombre: "Evian", categoría: .Bebidas, contenido: "1 L", barcode: "061314000070", variedades: [VariedadNewS(cantidad: 18, abierto: false, caducidad: Date())], favorito: true)
    
    static let emptyItem: ItemNewS = ItemNewS(id: String(length: 20), nombre: "", categoría: .Abarrotes, contenido: "", barcode: "", variedades: [], favorito: false)
    
    init(empty: Bool = true) {
        if empty {
            self = ItemNewS(id: String(length: 20), nombre: "", categoría: .Abarrotes, contenido: "", barcode: "", variedades: [], favorito: false)
        }
    }
}

extension Color {
    //@available(iOS 15.0, *)
    func fromStatus(_ status: Estado) -> Color {
        switch(status) {
        case .Rojo:
            return .red
        case .Naranja:
            return .orange
        case .Teal:
            if #available(iOS 15.0, *) {
                return .teal
            } else {
                // Fallback on earlier versions
                return Color(UIColor.systemTeal)
            }
        case .Verde:
            return .green
        }
    }
    
    //@available(iOS 15.0, *)
    init(status: Estado) {
        switch(status) {
        case .Rojo:
            self = .red
        case .Naranja:
            self = .orange
        case .Teal:
            if #available(iOS 15.0, *) {
                self = .teal
            } else {
                // Fallback on earlier versions
                self = Color(UIColor.systemTeal)
            }
        case .Verde:
            self = .green
        }
    }
}

extension String {
    init (length: Int) {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      self = String((0..<length).map{ _ in letters.randomElement()! })
    }
}
