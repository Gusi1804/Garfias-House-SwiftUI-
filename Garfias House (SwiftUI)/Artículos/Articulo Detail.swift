//
//  Articulo Detail.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 29/10/20.
//

import SwiftUI
import CodeScanner
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Articulo_Detail: View {
    
    @State var catVM = categoríasViewModel()
    
    @State var categorías: [String] = []
    @State var selectedCategory = 0
    
    @State var name: String = ""
    @State var contenido = ""
    @State var categoria = ""
    @State var barcode = ""
    @State var cantAlert = ""
    @State var cadAlert = ""
    
    @State var nuevaFecha = Date()
    
    @State var isShowingSheet = false
    @State var isShowingScanner = false
    @State var isAddingVariant = false
    
    @State var isAddingItem = false
    
    var id: String
    @Binding var items: [Item]
    @Binding var vm: ItemsViewModel
    @State var index = 0
    
    @State var variants = [Variedad]()
    
    @State var newDate = Date()
    @State var newCantidad = 1
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingSheet = false
        self.isShowingScanner = false
       
        switch result {
        case .success(let code):
            barcode = code
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    func colorFromStatus (status: Status) -> Color {
        switch status {
        case .Red:
            return .red
        case .Orange:
            return .orange
        case .Teal:
            return Color(UIColor.systemTeal)
        case .Green:
            return .green
        }
    }
    
    func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: date)
    }
    
    func open(_ variedad: Variedad) {
        var index = 0
        var new = Variedad()
        
        for variant in self.variants {
            if (variant == variedad) {
                self.variants[index].cantidad += -1
                
                if (self.variants[index].cantidad == 0) {
                    self.delete(self.variants[index])
                }
                
                new.caducidadFB = variedad.caducidadFB
                new.cantidad = 1
                new.open = true
                new.status = .Teal
                
                self.variants.append(new)
                break
            }
            index += 1
        }
    }
    
    func delete(_ variedad: Variedad) {
        var index = 0
        
        for variant in self.variants {
            if (variant == variedad) {
                self.variants.remove(at: index)
                break
            }
            index += 1
        }
    }
    
    var body: some View {
        
        if (self.items.count != 0) {
            Form {
                //Basic Data
                Section(header: Text("Nombre")) {
                    HStack {
                        TextField("", text: $name)
                        Spacer()
                        if (items[index].alert == true) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                }
                Section(header: Text("Contenido")) {
                    TextField("", text: $contenido)
                }
                Section(header: Text("Categoría")) {
                    TextField("", text: $categoria)
                }
                if (items[index].barcode != nil && items[index].barcode != "") {
                    Section(header: Text("Código de Barras")) {
                        HStack {
                            TextField("", text: $barcode)
                                .keyboardType(.numberPad)
                            Spacer()
                            Button(action: {
                                //Action
                                self.isShowingScanner = true
                            }, label: {
                                Image(systemName: "barcode.viewfinder")
                            })
                            .sheet(isPresented: $isShowingScanner) {
                                CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: self.handleScan)
                            }
                        }
                    }
                }
                
                //Variants
                Section(header: HStack {
                    Text("Variantes")
                    Button(action: {
                        self.isAddingVariant = true
                        self.isShowingSheet = true
                    }, label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            .padding(.trailing, 10)
                    })
                }) {
                    ForEach(self.variants.sorted(by: {$0.caducidad ?? Date() < $1.caducidad ?? Date()})) { variedad in
                        HStack {
                            if (variedad.caducidad != nil) {
                                Text(dateString(date: variedad.caducidad!))
                            }
                            Spacer()
                            numInCircle(number: variedad.cantidad, color: colorFromStatus(status: variedad.status!))
                        }
                        .contextMenu {
                            //Open
                            Button(action: {
                                //Action
                                open(variedad)
                            }, label: {
                                Text("Abrir una unidad")
                            })
                            
                            //Delete
                            Button(action: {
                                //Action
                                delete(variedad)
                            }, label: {
                                Image(systemName: "trash")
                                Text("Borrar variedad")
                            })
                            
                        }
                    }
                    
    //                HStack {
    //                    DatePicker("Ingresa la fecha de caducidad.", selection: $nuevaFecha, in: Date()..., displayedComponents: .date)
    //                        .labelsHidden()
    //                }
                }
                
                //Alerts
                Section(header: Text("Alertas")) {
                    HStack {
                        Text("Cant. para alertas:")
                        Spacer()
                        TextField("", text: $cantAlert)
                            .frame(width: 35)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    if (items[index].cadAlert != nil) {
                        HStack {
                            Text("Cad. para alertas:")
                            Spacer()
                            TextField("", text: $cadAlert)
                                .frame(width: 35)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                            Text("días")
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddingVariant) {
                AddVariant(caducidad: $newDate, cantidad: $newCantidad)
                .onDisappear(perform: {
                    let variant = Variedad()
                    
                    variant.caducidadFB = Timestamp.init(date: newDate)
                    variant.cantidad = newCantidad
                    variant.open = false
                    
                    let calendar = Calendar.current
                    let today = Date()
                    let cantAlert = items[index].cantAlert!
                    var useful = 0
                    if variant.open != true {
                        if variant.caducidad != nil {
                            let caducidad = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: variant.caducidad!)!
                            
                            if (caducidad < today) {
                                variant.status = .Red
                                //break
                            } else {
                                let días = calendar.dateComponents([.day], from: today, to: caducidad).day
                                if (días! <= cantAlert) {
                                    variant.status = .Orange
                                    useful += variant.cantidad
                                    //break
                                } else {
                                    useful += variant.cantidad
                                    if (variant.open != true) {
                                        variant.status = .Green
                                    } else {
                                        variant.status = .Teal
                                    }
                                    //break
                                }
                            }
                        } else {
                            variant.status = .Green
                        }
                    } else if (variant.open == true) {
                        variant.status = .Teal
                    }
                    print (variant.status)
                    
                    variants.append(variant)
                    newDate = Date()
                    newCantidad = 1
                    
                    self.isShowingSheet = false
                    self.isAddingVariant = false
                })
            }
            .onAppear(perform: {
                if (id != "new" && id != "") {
                    var i = 0
                    for art in items {
                        if (art.iD == id) {
                            index = i
                            self.name = items[index].nombre
                            self.contenido = items[index].contenido
                            self.categoria = items[index].categoría
                            self.barcode = items[index].barcode ?? ""
                            self.cantAlert = String(items[index].cantAlert)
                            self.cadAlert = String(items[index].cadAlert ?? 0)
                            self.variants = items[index].variedades ?? [Variedad]()
                            return
                        }
                        i += 1
                    }
                } else if (id == "new") {
                    
                }
            })
            .navigationTitle(Text(items[index].nombre + " " + items[index].contenido))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                //Action
                var newItem = Item()
                newItem.iD = items[index].iD
                newItem.barcode = self.barcode
                newItem.nombre = self.name
                newItem.contenido = self.contenido
                newItem.categoría = self.categoria
                newItem.cantAlert = Int(self.cantAlert)
                newItem.cadAlert = Int(self.cadAlert)
                newItem.variedades = self.variants
                //newItem.variedades?.append(contentsOf: self.newVariants)
                
                if (self.id != "new") {
                    vm.updateItem(item: newItem)
                } else if (self.id == "new") {
                    newItem.iD = ""
                    vm.addItem(item: newItem)
                }
            }, label: {
                Image(systemName: "square.and.arrow.down")
            }))
        }
        
    }
}

//struct Articulo_Detail_Previews: PreviewProvider {
//    static var previews: some View {
//        Articulo_Detail()
//            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//    }
//}
