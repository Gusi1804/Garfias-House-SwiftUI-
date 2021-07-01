//
//  Artículos.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 29/10/20.
//

import SwiftUI
import CodeScanner

struct Arti_culos: View {
    
    @State var vm = ItemsViewModel()
    
    @State var items = [Item]()
    
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
    
    @State var scanning = false
    @State var adding = false
    @State var iD = ""
    
    @State var addingItem = false
    
    @State var showingActionSheet = false
    @State var buttons = [ActionSheet.Button]()
    
    @State var confirmAdd = false
    @State var barcode = ""
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.scanning = false
        
        switch result {
        case .success(let code):
            //barcode = code
            print("Scan success, barcode: \(code)")
            
            vm.getID(barcode: code, errorF: {
                //Error
                print("Error searching item.")
            }, noDocF: {
                //No doc found
                //self.addingItem = true
                self.barcode = code
                self.confirmAdd = true
            }) {
                //Success
                self.iD = vm.iD
                //print("Scan success, id: \(code)")
                self.adding = true
            }
        break
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    func delete (_ item: Item) {
        self.vm.deleteItem(item: item)
    }
    
    func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                //Items
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: Articulo_Detail(id: item.iD, items: $items, vm: self.$vm).onDisappear {
                            
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(item.nombre)
                                            .bold()
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                        Text(item.contenido)
                                            .font(.subheadline)
                                        if (item.alert == true) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                Spacer()
                                HStack {
                                    if (item.redN != 0) {
                                        numInCircle(number: item.redN, color: .red)
                                    }
                                    
                                    if (item.orangeN != 0) {
                                        numInCircle(number: item.orangeN, color: .orange)
                                    }
                                    
                                    if (item.tealN != 0) {
                                        numInCircle(number: item.tealN, color: Color(UIColor.systemTeal))
                                    }
                                    
                                    if (item.greenN != 0) {
                                        numInCircle(number: item.greenN, color: .green)
                                    }
                                }
                            }
                            .contextMenu {
                                //Open
                                
                                
                                //Delete
                                Button(action: {
                                    self.delete(item)
                                }) {
                                    Image(systemName: "trash")
                                    Text("Eliminar artículo")
                                }
                            }
                        }
                    }
                }
                .navigationTitle(Text("Artículos"))
                .listStyle(InsetGroupedListStyle())
                .toolbar {
                    //Add Item
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            //Action
                            self.addingItem = true
                        }, label: {
                            Image(systemName: "plus.circle")
                        })
                    }
                    
                    //Scan Barcode
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            //Action
                            self.scanning = true
                        }, label: {
                            Image(systemName: "barcode.viewfinder")
                        })
                    }
                }
                .sheet(isPresented: $scanning, content: {
                    CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: self.handleScan)
                })
                .alert(isPresented: $confirmAdd) {
                    Alert(title: Text("No se encontró este artículo"), message: Text("No hay ningún artículo en la base de datos correspondiente a ese código de barras. ¿Desea agregarlo?"), primaryButton: .default(Text("Agregar")) {
                        //self.confirmAdd = false
                        self.addingItem = true
                    }, secondaryButton: .cancel())
                }
                
                //Add Item
                NavigationLink(destination: Articulo_Detail(barcode: self.barcode, id: "new", items: $items, vm: self.$vm)
                                .onDisappear {
                                    self.addingItem = false
                                }, isActive: $addingItem) {
                                    EmptyView()
                                }
                //Show Scanned Item
                NavigationLink(destination: Articulo_Detail(id: iD, items: $items, vm: self.$vm).onDisappear {
                    self.adding = false
                    self.iD = ""
                    vm.iD = ""
                    print("Modal Disappeared")
                }, isActive: $adding) {
                    EmptyView()
                }
            }
        }
        .onAppear {
            self.items = []
            
            vm.fetchData(errorF: {
                print("Error accediendo a la información.")
            }, success: {
                self.items = []
                self.items = vm.items.sorted(by: {$0.nombre < $1.nombre})
            })
        }
        .navigationTitle(Text("Artículos"))
    }
}

struct Arti_culos_Previews: PreviewProvider {
    static var previews: some View {
        Arti_culos()
    }
}
