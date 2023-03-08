//
//  ShoppingCart.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 28/12/20.
//

import SwiftUI
import CodeScanner

struct SelectSwitch: View {
    
    @State var selected = false
    var action: closure
    
    var body: some View {
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.selected.toggle()
                action()
            }
        }) {
            if self.selected == false {
                Circle()
                    .stroke(lineWidth: 1.5)
                    .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.blue)
            } else if self.selected == true {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 1.5)
                        .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 25))
                        .padding(0)
                }
                .frame(width: 25, height: 25, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
        }
        
    }
    
}

struct ShoppingCart: View {
    
    @State var vm = ItemsViewModel()
    @State var cartVM = CartViewModel()
    
    @State var itemsFull = [Item]()
    @State var items = [ItemShort]()
    @State var selectedItems = [Item]()
    
    @State var addingItems = false
    @State var scanning = false
    
    @State var selectingQuantity = false
    @State var quantity = 1
    @State var item = Item()
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.scanning = false
        
        switch result {
        case .success(let code):
            //barcode = code
            print("Scan success, barcode: \(code)")
            
            vm.getItemFromBarcode(barcode: code, errorF: {
                //Error
                
                print("Error searching item.")
            }, noDocF: {
                //No doc found
                
            }, success: {
                //Success
                print(vm.item.iD)
                var it = ItemShort(item: vm.item, cantidad: self.quantity)
                print(it.iD)
                
                cartVM.addItem(item: it)
            })
            break
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    func delete (_ item: ItemShort) {
        cartVM.deleteItem(item: item)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    
                    if (self.items.count == 0) {
                        Text("¡La lista está vacía!")
                    }
                    
                    ForEach (items) { item in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(item.nombre)
                                    .bold()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Text(item.contenido)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                numInCircle(number: item.cantidad, color: .black)
                                //Text(String(item.cantidad))
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                self.delete(item)
                            }) {
                                Image(systemName: "trash")
                                Text("Eliminar de la lista")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle(Text("Lista de Compra"))
            .toolbar {
                //Add Item
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.addingItems = true
                    }, label: {
                        Image(systemName: "plus.circle")
                    })
                    .sheet(isPresented: $addingItems, content: {
                        AddItemsSheet(itemsFull: $itemsFull, selectedItems: $selectedItems)
                    })
                }
                
                //Scan Barcode
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        //self.scanning = true
                        self.selectingQuantity = true
                    }, label: {
                        Image(systemName: "barcode.viewfinder")
                    })
                    .sheet(isPresented: $scanning, content: {
                        CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: self.handleScan)
                    })
                }
            }
            .sheet(isPresented: $selectingQuantity, onDismiss: {
                print(self.quantity)
                self.selectingQuantity = false
                
                self.scanning = true
            }, content: {
                QuantitySelector(cartVM: $cartVM, selectingQuantity: $selectingQuantity, quantity: $quantity, item: self.item)
            })
            
        }
        .onAppear {
            self.itemsFull = []
            
            vm.fetchData(errorF: {
                print("Error accediendo a la información.")
            }, success: {
                self.itemsFull = []
                self.itemsFull = vm.items.sorted(by: {$0.nombre < $1.nombre})
            })
            
            self.items = []
            
            cartVM.fetchData(errorF: {
                //Error
                
            }, success: {
                //Success
                self.items = []
                
                self.items = cartVM.items.sorted(by: {$0.nombre < $1.nombre})
            })
        }
    }
}

struct AddItemsSheet: View {
    
    @Binding var itemsFull: [Item]
    @Binding var selectedItems: [Item]
    @State var itemsTest = [Item: State<Int>]()
    
    var body: some View {
        List {
            Section(header: VStack {
                Spacer()
                    .padding(.bottom, 20)
                Text("Seleccione un artículo")
                
            }) {
                ForEach (itemsFull) { item in
                    VStack(alignment: .leading) {
                        HStack {
                            HStack {
                                SelectSwitch(action: {
                                    
                                    item.selected.toggle()
                                    
                                    var sItems = [Item]()
                                    for itemToCheck in itemsFull {
                                        if itemToCheck.selected == true {
                                            sItems.append(itemToCheck)
                                        }
                                    }
                                    self.selectedItems = sItems
                                    
                                })
                                
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
/*
                        if (item.selected == true) {
//                            HStack {
//                                TextField("", value: item.$quantity, formatter: NumberFormatter())
//                                    .keyboardType(.numberPad)
//                                    .disabled(true)
//                                Spacer()
//                                Stepper("", value: item.$quantity, in: 1...2000)
//                                    .labelsHidden()
//                            }
                            HStack {
                                
                            }
                            
                        }
 */
                    }
                }
            }
            
            Section(header: Text("Selected items")) {
                ForEach (selectedItems) { item in
                    Text(item.nombre)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct QuantitySelector: View {
    
    @Binding var cartVM: CartViewModel
    
    @Binding var selectingQuantity: Bool
    
    @Binding var quantity: Int
    var item: Item
    
    var body: some View {
        Form {
            Section(header: Text("Cantidad por comprar")) {
                HStack {
                    TextField("", value: $quantity, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .disabled(true)
                    Spacer()
                    Stepper("", value: $quantity, in: 1...2000)
                        .labelsHidden()
                }
            }
            
            Section(footer: Boton(action: {
                //Action
                
                self.selectingQuantity = false
            }, text: "Escanear artículo")) {
                EmptyView()
            }
        }
    }
}

struct Boton: View {
    
    var action: closure
    var text: String
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                action()
            }) {
                Text(text)
                    .font(.headline)
            }
            .frame(width: 200, height: 40)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
    }
    
}

struct ShoppingCart_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingCart()
    }
}
