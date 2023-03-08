//
//  ViewModelNew.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias on 11/06/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import SwiftUI

/*
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
 */

// MARK: ItemsViewModelNew (deprecated)
@available(iOS 15.0, *)
class ItemsViewModelNew: ObservableObject {
    @Published var items = ItemStore([ItemNew]())
    @Published var iD = ""
    @Published var item = ItemNew()
    
    @Published var listener: ListenerRegistration!
    
    private var db = Firestore.firestore()
    
    // MARK: - Updated Functions (fully functional with ItemStore, ItemNew, and VariedadNew)
    
    // MARK: fetchData
    func fetchData(errorF: @escaping closure, success: @escaping closure) {
        db.collection("items")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    //Decode document as item
                    let result = Result {
                        try diff.document.data(as: ItemNew.self)
                    }
                    
                    switch result {
                    case .success(let item):
                        item.id = diff.document.documentID //Set item id
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
                            
                            self.deleteItem(item)
                            self.addItem(item, randomID: false)
                        }
                        
                        success()
                    case .failure(let error):
                        // An `ItemNew` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding city: \(error)")
                        errorF()
                    }
                }
            }
    }
    
    // MARK: addItem
    func addItem (_ item: ItemNew, randomID: Bool = true) {
        if randomID {
            do {
                try db.collection("items").addDocument(from: item)
            } catch let error {
                print("Error writing item to Firestore: \(error)")
            }
        } else {
            do {
                try db.collection("items").document(item.id).setData(from: item)
            } catch let error {
                print("Error writing item to Firestore: \(error)")
            }
        }
        
    }
    
    // MARK: updateItem
    func updateItem (_ item: ItemNew) {
        do {
            try db.collection("items").document(item.id).setData(from: item)
        } catch let error {
            print("Error writing item to Firestore: \(error)")
        }
    }
    
    // MARK: deleteItem
    func deleteItem (_ item: ItemNew) {
        db.collection("items").document(item.id).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    // MARK: starItem
    func starItem (_ item: ItemNew) {
        let newValue: Bool = !item.favorito
        
        db.collection("items").document(item.id).updateData([
            "favorito": newValue
        ])
    }
    
    enum SearchField: String {
        case barcode
        case id
        case nombre
    }
    
    // MARK: searchItem
    func searchItem (query: String, searchField: SearchField, errorFunction: @escaping closure, noMatches: @escaping closure, success: @escaping closure) {
        // Search by name or barcode
        if (searchField != .id) {
            var match = ""
            
            if (searchField == .nombre) {
                var matches = [String]()
                let tmp = items.all.filter({$0.nombre.contains(query)})
                matches = tmp.map { $0.nombre }
                
                match = matches.first ?? ""
            } else {
                match = query
            }
            
            db.collection("items").whereField(searchField.rawValue, isEqualTo: match)
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        errorFunction()
                    } else {
                        for document in querySnapshot!.documents {
                            //print("\(document.documentID) => \(document.data())")
                            print(document.documentID)
                            
                            let result = Result {
                                try document.data(as: ItemNew.self)
                            }
                            switch result {
                            case .success(let item):
                                // An `Item` value was successfully initialized from the DocumentSnapshot.
                                //print("Item: \(item)")
                                
                                item.id = document.documentID //Set item id
                                item.setStatusForVarieties()
                                
                                self.item = item
                                
                                success()
                            case .failure(let error):
                                // An `Item` value could not be initialized from the DocumentSnapshot.
                                print("Error decoding item: \(error)")
                                noMatches()
                            }
                        }
                        
                        if (querySnapshot!.documents.count == 0) {
                            noMatches()
                        }
                    }
            }
        } else { //Search by id
            db.collection("items").document(query).getDocument { (document, error) in
                if let document = document, document.exists {
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                    
                    let result = Result {
                        try document.data(as: ItemNew.self)
                    }
                    switch result {
                    case .success(let item):
                        // An `Item` value was successfully initialized from the DocumentSnapshot.
                        //print("Item: \(item)")
                        
                        item.id = document.documentID //Set item id
                        item.setStatusForVarieties()
                        
                        self.item = item
                        
                        success()
                    case .failure(let error):
                        // An `Item` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding item: \(error)")
                        errorFunction()
                    }
                } else {
                    print("Document does not exist")
                    noMatches()
                }
            }
        }
    }
    
    // MARK: downloadImage
    func downloadImage(item: ItemNew, errorClosure: @escaping closure, success: @escaping (URL) -> Void) {
        // Create a reference to the file you want to download
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("ItemImages")
        let imageRef = imagesRef.child(item.id + ".jpeg")

        // Fetch the download URL
        imageRef.downloadURL { url, error in
            if let error = error {
                // Handle any errors
                errorClosure()
            } else {
                // Get the download URL for 'images/stars.jpg'
                if let url = url {
                    success(url)
                }
            }
        }
    }
    
    // MARK: saveImage
    func saveImage(item: ItemNew, data: Data) {
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("ItemImages")
        let imageRef = imagesRef.child(item.id + ".jpeg")
        
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload file and metadata to the object 'images/mountains.jpg'
        let uploadTask = imageRef.putData(data, metadata: metadata)

        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
            // Upload resumed, also fires when the upload starts
        }

        uploadTask.observe(.pause) { snapshot in
            // Upload paused
        }

        uploadTask.observe(.progress) { snapshot in
            // Upload reported progress
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)
        }

        uploadTask.observe(.success) { snapshot in
            // Upload completed successfully
        }

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as? NSError {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                // File doesn't exist
                break
                case .unauthorized:
                    // User doesn't have permission to access file
                    break
                case .cancelled:
                    // User canceled the upload
                    break

                /* ... */

                case .unknown:
                    // Unknown error occurred, inspect the server response
                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    break
                }
          }
        }
    }
    
    // MARK: addVariety
    func addVariety (for item: ItemNew, variedad: VariedadNew) {
        let ref = db.collection("items").document(item.id)
        
        if let caducidad = variedad.caducidad {
            ref.updateData([
                "variedades": FieldValue.arrayUnion([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "caducidadFB": Timestamp.init(date: caducidad),
                    "id": variedad.id
                ]])
            ])
        } else {
            ref.updateData([
                "variedades": FieldValue.arrayUnion([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "id": variedad.id,
                ]])
            ])
        }
    }
    
    // MARK: deleteVariety
    func deleteVariety (of item: ItemNew, variedad: VariedadNew) {
        let ref = db.collection("items").document(item.id)
        if let caducidad = variedad.caducidad {
            ref.updateData([
                "variedades": FieldValue.arrayRemove([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "caducidadFB": Timestamp.init(date: caducidad),
                    "id": variedad.id
                ]])
            ])
        } else {
            ref.updateData([
                "variedades": FieldValue.arrayRemove([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "id": variedad.id,
                ]])
            ])
        }
    }
    
    func updateVariety (of item: ItemNew, variedad: VariedadNew) {
        if let old = item.variedades.first(where: {$0.id == variedad.id}) {
            deleteVariety(of: item, variedad: old)
            addVariety(for: item, variedad: variedad)
        }
    }
    
    // MARK: - Unupdated functions, not functional
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
    
    /*
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
     */
}

// MARK: -ItemsViewModelNewS
//@available(iOS 15.0, *)
class ItemsViewModelNewS: ObservableObject {
    @Published var items = ItemStoreS([ItemNewS]())
    @Published var iD = ""
    @Published var item = ItemNewS()
    
    @Published var listener: ListenerRegistration!
    
    private var db = Firestore.firestore()
        
    // MARK: fetchData
    func fetchData(errorF: @escaping closure, success: @escaping closure) {
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
                    case .success(var item):
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
                            
                            /*
                            let count = self.items.all.filter({$0.id == item.id}).count
                            
                            if count == 1 {
                                if let i = self.items.all.firstIndex(where: {$0.id == item.id}) {
                                    self.items.all[i] = item
                                } else {
                                    self.items.all.append(item)
                                }
                            } else {
                                print("instances of this item: \(count)")
                                self.items.all.removeAll(where: {$0.id == item.id})
                                self.items.all.append(item)
                            }
                             */
                            
                            
                            if let i = self.items.all.firstIndex(where: {$0.id == item.id}) {
                                self.items.all[i].update(item)
                            } else {
                                self.items.all.append(item)
                            }                             
                        }
                        
                        print("Finished loading item \(item.nombre)")
                        success()
                    case .failure(let error):
                        // An `ItemNew` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding city: \(error)")
                        errorF()
                    }
                }
            }
    }
    
    // MARK: addItem
    func addItem (_ item: ItemNewS, randomID: Bool = true) {
        if randomID {
            do {
                try db.collection("items").addDocument(from: item)
            } catch let error {
                print("Error writing item to Firestore: \(error)")
            }
        } else {
            do {
                try db.collection("items").document(item.id.string).setData(from: item)
            } catch let error {
                print("Error writing item to Firestore: \(error)")
            }
        }
        
    }
    
    // MARK: updateItem
    func updateItem (_ item: ItemNewS) {
        do {
            try db.collection("items").document(item.id.string).setData(from: item)
        } catch let error {
            print("Error writing item to Firestore: \(error)")
        }
    }
    
    // MARK: deleteItem
    func deleteItem (_ item: ItemNewS) {
        db.collection("items").document(item.id.string).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    // MARK: starItem
    func starItem (_ item: ItemNewS) {
        let newValue: Bool = !item.favorito
        
        db.collection("items").document(item.id.string).updateData([
            "favorito": newValue
        ])
    }
    
    enum SearchField: String {
        case barcode
        case id
        case nombre
    }
    
    // MARK: searchItem
    func searchItem (query: String, searchField: SearchField, errorFunction: @escaping closure, noMatches: @escaping closure, success: @escaping closure) {
        // Search by name or barcode
        if (searchField != .id) {
            var match = ""
            
            if (searchField == .nombre) {
                var matches = [String]()
                let tmp = items.all.filter({$0.nombre.contains(query)})
                matches = tmp.map { $0.nombre }
                
                match = matches.first ?? ""
            } else {
                match = query
            }
            
            db.collection("items").whereField(searchField.rawValue, isEqualTo: match)
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        errorFunction()
                    } else {
                        for document in querySnapshot!.documents {
                            //print("\(document.documentID) => \(document.data())")
                            print(document.documentID)
                            
                            let result = Result {
                                try document.data(as: ItemNewS.self)
                            }
                            switch result {
                            case .success(var item):
                                // An `Item` value was successfully initialized from the DocumentSnapshot.
                                //print("Item: \(item)")
                                
                                item.id = Identifier(string: document.documentID) //Set item id
                                item.setStatusForVarieties()
                                
                                self.item = item
                                
                                success()
                            case .failure(let error):
                                // An `Item` value could not be initialized from the DocumentSnapshot.
                                print("Error decoding item: \(error)")
                                noMatches()
                            }
                        }
                        
                        if (querySnapshot!.documents.count == 0) {
                            noMatches()
                        }
                    }
            }
        } else { //Search by id
            db.collection("items").document(query).getDocument { (document, error) in
                if let document = document, document.exists {
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                    
                    let result = Result {
                        try document.data(as: ItemNewS.self)
                    }
                    switch result {
                    case .success(var item):
                        // An `Item` value was successfully initialized from the DocumentSnapshot.
                        //print("Item: \(item)")
                        
                        item.id = Identifier(string: document.documentID) //Set item id
                        item.setStatusForVarieties()
                        
                        self.item = item
                        
                        success()
                    case .failure(let error):
                        // An `Item` value could not be initialized from the DocumentSnapshot.
                        print("Error decoding item: \(error)")
                        errorFunction()
                    }
                } else {
                    print("Document does not exist")
                    noMatches()
                }
            }
        }
    }
    
    // MARK: downloadImage
    func downloadImage(item: ItemNewS, errorClosure: @escaping closure, success: @escaping (URL) -> Void) {
        // Create a reference to the file you want to download
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("ItemImages")
        let imageRef = imagesRef.child(item.id.string + ".jpeg")

        // Fetch the download URL
        imageRef.downloadURL { url, error in
            if let error = error {
                // Handle any errors
                errorClosure()
            } else {
                // Get the download URL for 'images/stars.jpg'
                if let url = url {
                    success(url)
                }
            }
        }
    }
    
    // MARK: saveImage
    func saveImage(item: ItemNewS, data: Data) {
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("ItemImages")
        let imageRef = imagesRef.child(item.id.string + ".jpeg")
        
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload file and metadata to the object 'images/mountains.jpg'
        let uploadTask = imageRef.putData(data, metadata: metadata)

        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
            // Upload resumed, also fires when the upload starts
        }

        uploadTask.observe(.pause) { snapshot in
            // Upload paused
        }

        uploadTask.observe(.progress) { snapshot in
            // Upload reported progress
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)
        }

        uploadTask.observe(.success) { snapshot in
            // Upload completed successfully
        }

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as? NSError {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                // File doesn't exist
                break
                case .unauthorized:
                    // User doesn't have permission to access file
                    break
                case .cancelled:
                    // User canceled the upload
                    break

                /* ... */

                case .unknown:
                    // Unknown error occurred, inspect the server response
                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    break
                }
          }
        }
    }
    
    // MARK: addVariety
    func addVariety (for item: ItemNewS, variedad: VariedadNewS) {
        let ref = db.collection("items").document(item.id.string)
        
        if let caducidad = variedad.caducidad {
            ref.updateData([
                "variedades": FieldValue.arrayUnion([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "caducidadFB": Timestamp.init(date: caducidad),
                    "id": variedad.id.string,
                ]])
            ])
        } else {
            ref.updateData([
                "variedades": FieldValue.arrayUnion([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "id": variedad.id.string,
                ]])
            ])
        }
    }
    
    // MARK: deleteVariety
    func deleteVariety (of item: ItemNewS, variedad: VariedadNewS) {
        let ref = db.collection("items").document(item.id.string)
        if let caducidad = variedad.caducidad {
            ref.updateData([
                "variedades": FieldValue.arrayRemove([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "caducidadFB": Timestamp.init(date: caducidad),
                    "id": variedad.id.string,
                ]])
            ])
        } else {
            ref.updateData([
                "variedades": FieldValue.arrayRemove([[
                    "cantidad": variedad.cantidad,
                    "open": variedad.abierto,
                    "id": variedad.id.string,
                ]])
            ])
        }
    }
    
    func updateVariety (of item: ItemNewS, variedad: VariedadNewS) {
        if let old = item.variedades.first(where: {$0.id == variedad.id}) {
            deleteVariety(of: item, variedad: old)
            addVariety(for: item, variedad: variedad)
        }
    }
    
    // MARK: - Unupdated functions, not functional
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
}
