//
//  ContentView.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 29/10/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            if (UIDevice.current.model.hasPrefix("iPhone")) {
                Scan()
                    .tabItem {
                        Image(systemName: "barcode.viewfinder")
                        Text("Escanear")
                    }
            }
            
            
            if #available(iOS 15.0, *) {
                //Articulos_New()
                ItemsNewS()
                    .tabItem {
                        Image(systemName: "archivebox")
                        Text("Artículos")
                    }
            } else {
                ItemsNewSCompatible()
                    .tabItem {
                        Image(systemName: "archivebox")
                        Text("Artículos")
                    }
            }
            
            /*
            ShoppingCart()
                .tabItem {
                    Image(systemName: "cart")
                    Text("Lista de Compra")
                }
             */
            ShoppingCartNew()
                .tabItem {
                    Image(systemName: "cart")
                    Text("Lista de Compra")
                }
        }
    }
}
