//
//  ShoppingCartNew.swift
//  G House (iOS 15, *)
//
//  Created by Gustavo Garfias on 28/06/21.
//

import SwiftUI

struct ShoppingCartNew: View {
    @State var vm = CartViewModelNew()
    @State var items = CartStore(CartItem.previewData)
    //@Binding var items: CartStore
    
    @State var itemsVM = ItemsViewModelNewS()
    
    func saveChanges(item: ItemNewS) {
        itemsVM.updateItem(item)
    }
    
    /*
    init(itemsVM: Binding<ItemsViewModelNewS>, cartVM: Binding<CartViewModelNew>, cartItems: Binding<CartStore>) {
        self._itemsVM = itemsVM
        self._vm = cartVM
        self._items = cartItems
    }
     */
    
    var body: some View {
        NavigationView {
            List {
                ForEach($items.all) { $item in
                    ItemRowCart(item: $item, vm: $itemsVM, onDisappear: saveChanges(item:))
                }
                .navigationBarTitle("Lista de Compra")
            }
        }
        .onAppear {
            vm.fetchData(errorF: {
                //Error while fetching data
            }, success: {
                //Success
                self.items = vm.cartItems
            })
        }
        .onDisappear {
            vm.cartItems.all = []
        }
    }
}

struct ItemRowCart: View {
    @Binding var item: CartItem
    @Binding var vm: ItemsViewModelNewS
    var onDisappear: (ItemNewS) -> Void
    
    var body: some View {
        NavigationLink(destination: DetailViewS(item: $item.item, categoría: $item.item.wrappedValue.categoría, vm: $vm, onDisappear: { item in
            onDisappear(item)
        }), label: {
            HStack {
                HStack {
                    Text(item.item.nombre)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(item.item.contenido)
                        .font(.subheadline)
                    if (item.item.alert) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                
                HStack {
                    numInCircle(number: item.cantidad, color: .accentColor)
                }
            }
        })
    }
}

/*
struct ShoppingCartNew_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingCartNew()
    }
}
 */
