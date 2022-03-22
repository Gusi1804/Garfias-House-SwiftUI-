//
//  CartViewModel.swift
//  G House (iOS 15, *)
//
//  Created by Gustavo Garfias on 28/06/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import SwiftUI

class CartViewModelNew: ObservableObject {
    private var db = Firestore.firestore()
    
    private var items = ItemStoreS([ItemNewS()])
    @Published var cartItems = CartStore([])
    
    //@State var vm = ItemsViewModelNewS()
    @ObservedObject var vm = ItemsViewModelNewS()
    
    init() {
        vm.fetchData(errorF: {
            //Error
        }, success: {
            self.items = self.vm.items
        })
    }
    
    // MARK: addItem
    func addItem (_ item: CartItem) {
        do {
            try db.collection("cart").document(item.id.string).setData(from: item)
        } catch let error {
            print("Error writing item to Firestore: \(error)")
        }
        
    }
    
    // MARK: deleteItem
    func deleteItem(_ item: CartItem) {
        db.collection("cart").document(item.id.string).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    // MARK: fetchData
    func fetchData(errorF: @escaping closure, success: @escaping closure) {
        self.db.collection("cart")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    //Decode document as item
                    let result = Result {
                        try diff.document.data(as: CartItem.self)
                    }
                    
                    switch result {
                    case .success(var item):
                        // An `Item` value was successfully initialized from the DocumentSnapshot.
                        
                        item.id = Identifier(string: diff.document.documentID) //Set item id
                        print("ID: \(item.id.string)")
                        
                        if let itemNew = self.items.all.first(where: {$0.id == item.id}) {
                            item.item = itemNew
                            
                            if (diff.type == .added) {
                                print("New item: \(diff.document.data())")
                                if !self.cartItems.all.contains(item) {
                                    self.cartItems.all.append(item)
                                }
                            }
                            if (diff.type == .removed) {
                                print("Removed item: \(diff.document.data())")
                                
                                if let i = self.items.all.firstIndex(where: {$0.id == item.id}) {
                                    self.cartItems.all.remove(at: i)
                                }
                            }
                            if (diff.type == .modified) {
                                print("Modified item: \(diff.document.data())")
                                
                                if let i = self.items.all.firstIndex(where: {$0.id == item.id}) {
                                    self.cartItems.all[i] = item
                                } else {
                                    self.cartItems.all.append(item)
                                }
                            }
                            
                            success()
                        }
                    case .failure(_):
                        // An `ItemNew` value could not be initialized from the DocumentSnapshot.
                        errorF()
                    }
                }
            }
    }
    
    /*
    // MARK: fetchItems
    private func fetchItems(errorF: @escaping closure, success: @escaping closure) {
        db.collection("items")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    //Decode document as item
                    let result = Result {
                        try diff.document.data(as: ItemNewS.self)
                    }
                    
                    switch result {
                    case .success(let item):
                        if var item = item {
                            // An `Item` value was successfully initialized from the DocumentSnapshot.
                            
                            item.id = Identifier(string: diff.document.documentID) //Set item id
                            print("ID: \(item.id.string)")
                            item.setStatusForVarieties()
                            
                            if (diff.type == .added) {
                                print("New item: \(diff.document.data())")
                                self.items.all.append(item)
                            }
                            if (diff.type == .removed) {
                                print("Removed item: \(diff.document.data())")
                                
                                if let i = self.items.all.firstIndex(where: {$0.id == item.id}) {
                                    self.items.all.remove(at: i)
                                }
                            }
                            if (diff.type == .modified) {
                                print("Modified item: \(diff.document.data())")
                                
                                if let i = self.items.all.firstIndex(where: {$0.id == item.id}) {
                                    self.items.all[i] = item
                                } else {
                                    self.items.all.append(item)
                                }
                            }
                            
                            success()
                        } else {
                            // A nil value was successfully initialized from the DocumentSnapshot,
                            // or the DocumentSnapshot was nil.
                            print("Document does not exist")
                            
                            errorF()
                        }
                    case .failure(let error):
                        // An `ItemNew` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding city: \(error)")
                        errorF()
                    }
                }
            }
    }
     */
}
