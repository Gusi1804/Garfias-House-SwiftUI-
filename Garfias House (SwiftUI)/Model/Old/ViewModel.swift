//
//  ViewModel.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias García on 29/10/20.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

typealias closure = () -> ()

class CartViewModel: ObservableObject {
    @Published var items = [ItemShort]()
    
    private var db = Firestore.firestore()
    
    func fetchData(errorF: @escaping closure, success: @escaping closure) {
        
        self.items = []
        
        db.collection("cart")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                
                self.items = []
                
                for document in documents {
                    let result = Result {
                        try document.data(as: ItemShort.self)
                    }
                    switch result {
                    case .success(let item):
                        if let item = item {
                            // An `Item` value was successfully initialized from the DocumentSnapshot.
                            //print("Item: \(item)")
                            var index = 0
                            
                            item.iD = document.documentID
                            
                            //item.getStatus()
                            //item.getGlobalNumbers()
                            //print("\(item.greenN)")
                            self.items.append(item)
                            
                            success()
                        } else {
                            // A nil value was successfully initialized from the DocumentSnapshot,
                            // or the DocumentSnapshot was nil.
                            print("Document does not exist")
                            
                            errorF()
                        }
                    case .failure(let error):
                        // A `City` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding city: \(error)")
                        errorF()
                    }
                }
            }
        
    }
    
    func addItem (item: ItemShort) {
        do {
            //try db.collection("cart").addDocument(from: item)
            try db.collection("cart").document(item.iD).setData(from: item)
        } catch let error {
            print("Error writing item to Firestore: \(error)")
        }
    }
    
    func deleteItem (item: ItemShort) {
        db.collection("cart").document(item.iD).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
}

class ItemsViewModel: ObservableObject {
    @Published var items = [Item]()
    @Published var iD = ""
    @Published var item = Item()
    
    @Published var listener: ListenerRegistration!
    
    private var db = Firestore.firestore()
    
    func fetchData(errorF: @escaping closure, success: @escaping closure) {
        
        self.items = []
        
        db.collection("items")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                
                self.items = []
                
                for document in documents {
                    let result = Result {
                        try document.data(as: Item.self)
                    }
                    switch result {
                    case .success(let item):
                        if let item = item {
                            // An `Item` value was successfully initialized from the DocumentSnapshot.
                            //print("Item: \(item)")
                            var index = 0
                            
                            item.iD = document.documentID
                            
                            item.getStatus()
                            item.getGlobalNumbers()
                            print("\(item.greenN)")
                            self.items.append(item)
                            
                            success()
                        } else {
                            // A nil value was successfully initialized from the DocumentSnapshot,
                            // or the DocumentSnapshot was nil.
                            print("Document does not exist")
                            
                            errorF()
                        }
                    case .failure(let error):
                        // A `City` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding city: \(error)")
                        errorF()
                    }
                }
            }
        
    }
    
    func addItem (item: Item) {
        do {
            try db.collection("items").addDocument(from: item)
        } catch let error {
            print("Error writing city to Firestore: \(error)")
        }
    }
    
    func updateItem (item: Item) {
        do {
            try db.collection("items").document(item.iD).setData(from: item)
        } catch let error {
            print("Error writing city to Firestore: \(error)")
        }
    }
    
    func deleteItem (item: Item) {
        db.collection("items").document(item.iD).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func getID (barcode: String, errorF: @escaping closure, noDocF: @escaping closure, success: @escaping closure) {
        db.collection("items").whereField("barcode", isEqualTo: barcode)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    errorF()
                } else {
                    for document in querySnapshot!.documents {
                        //print("\(document.documentID) => \(document.data())")
                        print(document.documentID)
                        self.iD = document.documentID
                        success()
                    }
                    
                    if (querySnapshot!.documents.count == 0) {
                        noDocF()
                    }
                }
        }
    }
    
    func getItemFromBarcode (barcode: String, errorF: @escaping closure, noDocF: @escaping closure, success: @escaping closure) {
        db.collection("items").whereField("barcode", isEqualTo: barcode)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    errorF()
                } else {
                    for document in querySnapshot!.documents {
                        //print("\(document.documentID) => \(document.data())")
                        print(document.documentID)
                        
                        let result = Result {
                            try document.data(as: Item.self)
                        }
                        switch result {
                        case .success(let item):
                            if let item = item {
                                // An `Item` value was successfully initialized from the DocumentSnapshot.
                                //print("Item: \(item)")
                                
                                item.iD = document.documentID
                                
                                item.getStatus()
                                item.getGlobalNumbers()
                                //print("\(item.greenN)")
                                
                                self.item = item
                                
                                success()
                            } else {
                                // A nil value was successfully initialized from the DocumentSnapshot,
                                // or the DocumentSnapshot was nil.
                                print("Document does not exist")
                                
                                errorF()
                            }
                        case .failure(let error):
                            // A `City` value could not be initialized from the DocumentSnapshot.
                            print("Error decoding item: \(error)")
                            errorF()
                        }
                    }
                    
                    if (querySnapshot!.documents.count == 0) {
                        noDocF()
                    }
                }
        }
    }
    
    func getItem (id: String, errorF: @escaping closure, success: @escaping closure) {
        let docRef = db.collection("items").document(id)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                
                let result = Result {
                    try document.data(as: Item.self)
                }
                switch result {
                case .success(let item):
                    if let item = item {
                        // An `Item` value was successfully initialized from the DocumentSnapshot.
                        //print("Item: \(item)")
                        
                        item.iD = document.documentID
                        
                        item.getStatus()
                        item.getGlobalNumbers()
                        //print("\(item.greenN)")
                        
                        self.item = item
                        
                        success()
                    } else {
                        // A nil value was successfully initialized from the DocumentSnapshot,
                        // or the DocumentSnapshot was nil.
                        print("Document does not exist")
                        
                        errorF()
                    }
                case .failure(let error):
                    // A `City` value could not be initialized from the DocumentSnapshot.
                    print("Error decoding item: \(error)")
                    errorF()
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

class categoríasViewModel: ObservableObject {
    
    @Published var categorías = [String]()
    
    private var db = Firestore.firestore()
    
    func get(errorF: @escaping closure, success: @escaping closure) {
        let docRef = db.collection("categorías").document("categorías")

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                //let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                //print("Document data: \(dataDescription)")
                self.categorías = (document["lista"] as! [String]).sorted(by: <)
                print(self.categorías)
                success()
            } else {
                print("Document does not exist")
                errorF()
            }
        }
    }
    
}
