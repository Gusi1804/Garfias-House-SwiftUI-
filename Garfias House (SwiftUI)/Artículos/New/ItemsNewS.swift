//
//  ItemsNewS.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias on 23/06/21.
//

import SwiftUI
import Combine
import CodeScanner
import Foundation

// MARK: - ItemsNewS
@available(iOS 15.0, *)
struct ItemsNewS: View {
    @State var vm = ItemsViewModelNewS() // TODO: make vm binding, to ContentView
    
    @State private var items = ItemStoreS(ItemNewS.previewData)
    @State private var searchText: String = ""
    
    @State private var newItem = ItemNewS(empty: true)
    
    private var categoriesTest: [Categoría] = [.Congelados, .Bebidas, .Lácteos]
    
    @Environment(\.isSearching) private var isSearching: Bool
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var sectioned: Bool = true
    
    func saveChanges(item: ItemNewS) {
        vm.updateItem(item)
        
        self.newItem = ItemNewS(empty: true)
    }
    
    func starItem(item: ItemNewS) {
        vm.starItem(item)
    }
    
    func deleteItem(item: ItemNewS) {
        vm.deleteItem(item)
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let code):
            //barcode = code
            print("Scan success, barcode: \(code)")
            
            vm.searchItem(query: code, searchField: .barcode, errorFunction: {
                //Error
                print("Error searching item.")
            }, noMatches: {
                //No doc found
                self.newItem.barcode = code
                self.activeSheet = .AddingItem
            }, success: {
                self.activeSheet = .SearchResult
            })
        break
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if (searchText == "") {
                    if sectioned {
                        sectionContent(for: $items.favoritos, title: AnyView(HStack {
                            Image(systemName: "star")
                            Text("Favoritos")
                        }), vm: $vm, onDisappear: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                        
                        sections(for: $items, vm: self.$vm, saveChanges: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    } else { //Not sectioned
                        sectionContent(for: $items.all, title: AnyView(Text("Todos los artículos")), vm: $vm, onDisappear: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    }
                } else {
                    if sectioned {
                        sections(for: $items, searchText: searchText, vm: self.$vm, saveChanges: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    } else {
                        sectionContent(for: $items.all, searchText: searchText, title: AnyView(Text("Todos los artículos")), vm: $vm, onDisappear: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    }
                }
            }
            .searchable(text: $searchText)
            .sheet(item: $activeSheet) { item in // MARK: Articulos_New sheets
                switch item {
                case .SearchResult:
                    NavigationView {
                        DetailViewS(item: $vm.item, categoría: vm.item.categoría, vm: $vm, onDisappear: saveChanges(item:))
                            .navigationBarTitle(Text(vm.item.nombre + " " + vm.item.contenido), displayMode: .inline)
                    }
                case .AddingItem:
                    NavigationView {
                        DetailViewS(item: $newItem, categoría: .Abarrotes, addingItem: true, vm: $vm, onDisappear: saveChanges(item:))
                            .navigationBarTitle(Text(newItem.nombre + " " + newItem.contenido), displayMode: .inline)
                    }
                case .ScanningItem:
                    //Working barcode example (for simulator):
                    //CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "0061314000070", completion: self.handleScan)
                    
                    //Non-existant barcode example (for simulator):
                    CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "7503030212038", completion: self.handleScan)
                }
            }
            .toolbar {
                //Sectioned listed
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.sectioned.toggle()
                    }, label: {
                        if sectioned {
                            Image(systemName: "rectangle.grid.1x2.fill")
                        } else {
                            Image(systemName: "rectangle.grid.1x2")
                        }
                    })
                    
                }
                
                //Add Item
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.activeSheet = .AddingItem
                    }, label: {
                        Image(systemName: "plus.circle")
                    })
                    
                }
                
                //Scan Barcode
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.activeSheet = .ScanningItem
                    }, label: {
                        Image(systemName: "barcode.viewfinder")
                    })
                }
            }
            .onSubmit(of: .search) {
                //Search
                vm.searchItem(query: searchText, searchField: .nombre, errorFunction: {
                    //Error while searching or decoding Item
                }, noMatches: {
                    //No matches found
                }, success: {
                    //A match was found
                    print("Match found. Item name: \(vm.item.nombre) \(vm.item.contenido). ID: \(vm.item.id)")
                    
                    self.activeSheet = .SearchResult
                })
            }
            .navigationTitle("Artículos")
            .navigationViewStyle(.columns)
            
            /*
            if var item = $items.all.first {
                DetailViewS(item: item, categoría: item.wrappedValue.categoría, vm: $vm, onDisappear: { item in
                    saveChanges(item: item)
                })
            }
             */
        }
        .onAppear {
            DispatchQueue.main.async {
                vm.fetchData(errorF: {
                    //Error while fetching data
                }, success: {
                    //Success
                    self.items = vm.items
                })
            }
        }
        .onDisappear {
            vm.items.all = []
        }
    }
    
    var searchResults: [ItemNewS] {
        if searchText.isEmpty {
            return items.all
        } else {
            return items.all.filter({$0.nombre.contains(searchText)})
        }
    }
}

// MARK: -ItemsNewSCompatible
struct ItemsNewSCompatible: View {
    @State var vm = ItemsViewModelNewS()
    
    @State private var items = ItemStoreS(ItemNewS.previewData)
    @State private var searchText: String = ""
    
    @State private var newItem = ItemNewS(empty: true)
    
    private var categoriesTest: [Categoría] = [.Congelados, .Bebidas, .Lácteos]
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var sectioned: Bool = true
    
    func saveChanges(item: ItemNewS) {
        vm.updateItem(item)
        
        self.newItem = ItemNewS(empty: true)
    }
    
    func starItem(item: ItemNewS) {
        vm.starItem(item)
    }
    
    func deleteItem(item: ItemNewS) {
        vm.deleteItem(item)
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let code):
            //barcode = code
            print("Scan success, barcode: \(code)")
            
            vm.searchItem(query: code, searchField: .barcode, errorFunction: {
                //Error
                print("Error searching item.")
            }, noMatches: {
                //No doc found
                self.newItem.barcode = code
                self.activeSheet = .AddingItem
            }, success: {
                self.activeSheet = .SearchResult
            })
        break
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                //SearchBar(text: $searchText)
                //TextField("Search ...", text: $searchText)
                
                if (searchText == "") {
                    if sectioned {
                        sectionContent(for: $items.favoritos, title: AnyView(HStack {
                            Image(systemName: "star")
                            Text("Favoritos")
                        }), vm: $vm, onDisappear: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                        
                        sections(for: $items, vm: self.$vm, saveChanges: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    } else { //Not sectioned
                        sectionContent(for: $items.all, title: AnyView(Text("Todos los artículos")), vm: $vm, onDisappear: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    }
                } else {
                    if sectioned {
                        sections(for: $items, searchText: searchText, vm: self.$vm, saveChanges: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    } else {
                        sectionContent(for: $items.all, searchText: searchText, title: AnyView(Text("Todos los artículos")), vm: $vm, onDisappear: saveChanges(item:), deleteItem: deleteItem(item:), starItem: starItem(item:))
                    }
                }
            }
            .sheet(item: $activeSheet) { item in // MARK: Articulos_New sheets
                switch item {
                case .SearchResult:
                    NavigationView {
                        DetailViewS(item: $vm.item, categoría: vm.item.categoría, vm: $vm, onDisappear: saveChanges(item:))
                            .navigationBarTitle(Text(vm.item.nombre + " " + vm.item.contenido), displayMode: .inline)
                    }
                case .AddingItem:
                    NavigationView {
                        DetailViewS(item: $newItem, categoría: .Abarrotes, addingItem: true, vm: $vm, onDisappear: saveChanges(item:))
                            .navigationBarTitle(Text(newItem.nombre + " " + newItem.contenido), displayMode: .inline)
                    }
                case .ScanningItem:
                    //Working barcode example (for simulator):
                    //CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "0061314000070", completion: self.handleScan)
                    
                    //Non-existant barcode example (for simulator):
                    CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "7503030212038", completion: self.handleScan)
                }
            }
            .toolbar {
                //Sectioned listed
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.sectioned.toggle()
                    }, label: {
                        if sectioned {
                            Image(systemName: "rectangle.grid.1x2.fill")
                        } else {
                            Image(systemName: "rectangle.grid.1x2")
                        }
                    })
                    
                }
                
                //Add Item
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.activeSheet = .AddingItem
                    }, label: {
                        Image(systemName: "plus.circle")
                    })
                    
                }
                
                //Scan Barcode
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        //Action
                        self.activeSheet = .ScanningItem
                    }, label: {
                        Image(systemName: "barcode.viewfinder")
                    })
                }
            }
            .navigationTitle("Artículos")
            if #available(iOS 15.0, *) {
                if var item = $items.all.first {
                    DetailViewS(item: item, categoría: item.wrappedValue.categoría, vm: $vm, onDisappear: { item in
                        saveChanges(item: item)
                    })
                }
            }
            /*
            
             */
        }
        .onAppear {
            DispatchQueue.main.async {
                vm.fetchData(errorF: {
                    //Error while fetching data
                }, success: {
                    //Success
                    self.items = vm.items
                })
            }
        }
        .onDisappear {
            vm.items.all = []
        }
    }
}

// MARK: sectionContent
@ViewBuilder
private func sectionContent(for items: Binding<[ItemNewS]>, title: AnyView, vm: Binding<ItemsViewModelNewS>, onDisappear: @escaping (ItemNewS) -> Void, deleteItem: @escaping (ItemNewS) -> Void, starItem: @escaping (ItemNewS) -> Void) -> some View {
    if (items.wrappedValue.count != 0) {
        Section(header: title) {
            ForEach(items) { $item in
                if #available(iOS 15.0, *) {
                    ItemRowS(item: $item, vm: vm, onDisappear: { item in
                        onDisappear(item)
                    })
                        .swipeActions(edge: .trailing) {
                            //Delete
                            Button(role: .destructive, action: {
                                withAnimation {
                                    deleteItem(item)
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            //Toggle Favorite
                            Button(action: {
                                withAnimation(.easeInOut(duration: 4)) {
                                    starItem(item)
                                }
                            }) {
                                if (!item.favorito) {
                                    Image(systemName: "star")
                                } else {
                                    Image(systemName: "star.slash")
                                }
                            }
                            .tint(.yellow)
                        }
                } else {
                    // Fallback on earlier versions
                    ItemRowS(item: $item, vm: vm, onDisappear: { item in
                        onDisappear(item)
                    })
                        .contextMenu(menuItems: {
                            //Toggle Favorite
                            Button(action: {
                                withAnimation(.easeInOut(duration: 4)) {
                                    starItem(item)
                                }
                            }) {
                                if (!item.favorito) {
                                    Image(systemName: "star")
                                } else {
                                    Image(systemName: "star.slash")
                                }
                            }
                            
                            //Delete
                            Button(action: {
                                withAnimation {
                                    deleteItem(item)
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                        })
                }
            }
        }
    }
}

@ViewBuilder
private func sectionContent(for items: Binding<[ItemNewS]>, searchText: String, title: AnyView, vm: Binding<ItemsViewModelNewS>, onDisappear: @escaping (ItemNewS) -> Void, deleteItem: @escaping (ItemNewS) -> Void, starItem: @escaping (ItemNewS) -> Void) -> some View {
    if (items.count != 0) { //Only show if section is not empty
        if (items.wrappedValue.filter({$0.nombre.contains(searchText)}).count != 0) { //Only show if there are any matches
            Section(header: title) {
                ForEach(items) { $item in
                    if (item.nombre.contains(searchText)) {
                        if #available(iOS 15.0, *) {
                            ItemRowS(item: $item, vm: vm, onDisappear: { item in
                                onDisappear(item)
                            })
                                .swipeActions(edge: .trailing) {
                                    //Delete
                                    Button(role: .destructive, action: {
                                        withAnimation {
                                            deleteItem(item)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    //Toggle Favorite
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 4)) {
                                            starItem(item)
                                        }
                                    }) {
                                        if (!item.favorito) {
                                            Image(systemName: "star")
                                        } else {
                                            Image(systemName: "star.slash")
                                        }
                                    }
                                    .tint(.yellow)
                                }
                        } else {
                            // Fallback on earlier versions
                            ItemRowS(item: $item, vm: vm, onDisappear: { item in
                                onDisappear(item)
                            })
                                .contextMenu(menuItems: {
                                    //Toggle Favorite
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 4)) {
                                            starItem(item)
                                        }
                                    }) {
                                        if (!item.favorito) {
                                            Image(systemName: "star")
                                            Text("Favorito")
                                        } else {
                                            Image(systemName: "star.slash")
                                            Text("Desmarcar como favorito")
                                        }
                                    }
                                    
                                    //Delete
                                    Button(action: {
                                        withAnimation {
                                            deleteItem(item)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                })

                        }
                    }
                }
            }
        }
    }
}

// MARK: sections
@ViewBuilder
private func sections(for items: Binding<ItemStoreS>, vm: Binding<ItemsViewModelNewS>, saveChanges: @escaping (ItemNewS) -> Void, deleteItem: @escaping (ItemNewS) -> Void, starItem: @escaping (ItemNewS) -> Void) -> some View {
    sectionContent(for: items.abarrotes, title: AnyView(Text("Abarrotes")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.bebidas, title: AnyView(Text("Bebidas")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.congelados, title: AnyView(Text("Congelados")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.frutasYVerduras, title: AnyView(Text("Frutas y Verduras")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.higiene, title: AnyView(Text("Higiene")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.lácteos, title: AnyView(Text("Lácteos")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.limpieza, title: AnyView(Text("Limpieza")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.medicamentos, title: AnyView(Text("Medicamentos")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.panaderíaYTortillería, title: AnyView(Text("Panadería y Tortillería")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
    
    sectionContent(for: items.salchichonería, title: AnyView(Text("Salchichonería")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
}

@ViewBuilder
private func sections(for items: Binding<ItemStoreS>, searchText: String, vm: Binding<ItemsViewModelNewS>, saveChanges: @escaping (ItemNewS) -> Void, deleteItem: @escaping (ItemNewS) -> Void, starItem: @escaping (ItemNewS) -> Void) -> some View {
    if (items.wrappedValue.matchesCount(searchText: searchText) > 0) {
        sectionContent(for: items.favoritos, searchText: searchText, title: AnyView(HStack {
            Image(systemName: "star")
            Text("Favoritos")
        }), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
        Group {
            sectionContent(for: items.abarrotes, searchText: searchText, title: AnyView(Text("Abarrotes")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.bebidas, searchText: searchText, title: AnyView(Text("Bebidas")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.congelados, searchText: searchText, title: AnyView(Text("Congelados")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.frutasYVerduras, searchText: searchText, title: AnyView(Text("Frutas y Verduras")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.higiene, searchText: searchText, title: AnyView(Text("Higiene")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.lácteos, searchText: searchText, title: AnyView(Text("Lácteos")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.limpieza, searchText: searchText, title: AnyView(Text("Limpieza")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.medicamentos, searchText: searchText, title: AnyView(Text("Medicamentos")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.panaderíaYTortillería, searchText: searchText, title: AnyView(Text("Panadería y Tortillería")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
            
            sectionContent(for: items.salchichonería, searchText: searchText, title: AnyView(Text("Salchichonería")), vm: vm, onDisappear: saveChanges, deleteItem: deleteItem, starItem: starItem)
        }
    } else {
        Text("No se encontaron coincidencias.")
    }
}

// MARK: -DetailViewS
//@available(iOS 15.0, *)
struct DetailViewS: View {
    @Binding var item: ItemNewS
    @State var categoría: Categoría
    @State var addingItem: Bool = false
    @Binding var vm: ItemsViewModelNewS
    @State var modified = false
    var onDisappear: (ItemNewS) -> Void
    
    //ImagePicker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var data: Data?
    @State private var image: Image?
    
    @State private var imageURL: URL?
    
    @State private var scanning = false
    @State private var editingVariety = false
    
    @Environment(\.presentationMode) var presentationMode
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        
        
        if let data = data {
            vm.saveImage(item: item, data: data)
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        scanning = false
        
        switch result {
        case .success(let code):
            item.barcode = code
        break
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    var body: some View {
        Form {
            // MARK: Image
            Group {
                Section(header: HStack {
                    Spacer()
                    
                    if let imageURL = imageURL {
                        if #available(iOS 15.0, *) {
                            AsyncImage(url: imageURL, content: { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }, placeholder: {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                            })
                                .frame(height: 400)
                        } else {
                            // Fallback on earlier versions
                            AsyncImageCompatible(
                                url: imageURL,
                                placeholder: {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                            })
                                .frame(height: 400)
                        }
                            
                    } else {
                        if image != nil {
                            image?
                                .resizable()
                                .scaledToFit()
                                .frame(height: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            if #available(iOS 15.0, *) {
                                CompatibleButton(action: {
                                    self.showingImagePicker = true
                                }, label: AnyView(Group {
                                    Text("Agregar una foto del artículo")
                                }), buttonStyle: .bordered, controlProminence: .standard)
                            } else {
                                // Fallback on earlier versions
                                CompatibleButton(action: {
                                    self.showingImagePicker = true
                                }, label: AnyView(Group {
                                    Text("Agregar una foto del artículo")
                                }))
                            }
                        }
                    }
                    
                    Spacer()
                }) {
                    EmptyView()
                }
                .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                    ImagePicker(image: self.$inputImage, data: self.$data)
                }
                .onAppear {
                    vm.downloadImage(item: item, errorClosure: { return }, success: { url in
                        self.imageURL = url
                    })
                }
            }
            
            // MARK: Basic Data
            Group {
                Section(header: Text("Nombre")) {
                    TextField("Nombre", text: $item.nombre)
                        .onReceive(Just(item.nombre)) { nombre in
                            modified = true
                        }
                }
                
                Section(header: Text("Contenido")) {
                    TextField("Contenido", text: $item.contenido)
                }
                
                Section(header: Text("Categoría")) {
                    HStack {
                        /*
                        Text(categoría.rawValue)
                        
                        Spacer()
                         */
                        Picker(categoría.rawValue, selection: $categoría) {
                            ForEach(Categoría.allCases, id: \.self) { category in
                                Text(category.rawValue)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: HStack {
                    Text("Código de Barras")
                    
                    if #available(iOS 15.0, *) {
                        CompatibleButton(action: {
                            scanning.toggle()
                        }, label: AnyView(Group {
                            Image(systemName: "barcode.viewfinder")
                            Text("Escanear")
                        }), buttonStyle: .bordered, controlProminence: .standard)
                    } else {
                        // Fallback on earlier versions
                        CompatibleButton(action: {
                            scanning.toggle()
                        }, label: AnyView(Group {
                            Image(systemName: "barcode.viewfinder")
                            Text("Escanear")
                        }))
                    }
                }
                ) {
                    TextField("Código de Barras", text: $item.barcode)
                        .keyboardType(.numberPad)
                        .sheet(isPresented: $scanning) {
                            CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "7503030212038", completion: handleScan(result:))
                        }
                }
            }
            
            //VarietyView
            VarietyViewS(item: $item, editing: $editingVariety)
            
            //Alerts
            AlertViewS(item: $item)
            
            if !addingItem {
                // MARK: modifiedItem
                Section(footer: HStack {
                    Spacer()
                    if #available(iOS 15.0, *) {
                        Button(action: {
                            var tmp = self.item
                            tmp.categoría = self.categoría
                            precondition(Thread.isMainThread)
                            vm.updateItem(tmp)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Guardar Cambios al Artículo")
                        }
                        .buttonStyle(.bordered)
                        .controlProminence(.increased)
                    } else {
                        // Fallback on earlier versions
                        CompatibleButton(action: {
                            var tmp = self.item
                            tmp.categoría = self.categoría
                            precondition(Thread.isMainThread)
                            vm.updateItem(tmp)
                            presentationMode.wrappedValue.dismiss()
                        }, prominent: true, label: AnyView(
                            Text("Guardar Cambios al Artículo")
                                .bold()
                        ))
                    }
                    Spacer()
                }) {
                    EmptyView()
                }
            }
        }
        .navigationBarTitle("\(item.nombre) \(item.contenido)")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear(perform: {
            if !scanning && !showingImagePicker && !editingVariety {
                if !addingItem {
                    var tmp = item
                    tmp.categoría = categoría
                    onDisappear(tmp)
                    presentationMode.wrappedValue.dismiss()
                } else {
                    var tmp = self.item
                    tmp.categoría = self.categoría
                    precondition(Thread.isMainThread)
                    vm.addItem(tmp, randomID: false)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        })
    }
}

// MARK: AlertView
//@available(iOS 15.0, *)
struct AlertViewS: View {
    @Binding var item: ItemNewS
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        Section(header: Text("Alertas")) {
            HStack {
                Text("Cantidad mínima:")
                Spacer()
                TextField("", text: $item.quantityAlertString)
                    .frame(width: 35)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
            
            HStack {
                Text("Caducidad mínima (días):")
                Spacer()
                TextField("", text: $item.expiryDateAlertString)
                    .frame(width: 35)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
        }
    }
}

// MARK: VarietyView
//@available(iOS 15.0, *)
struct VarietyViewS: View {
    @Binding var item: ItemNewS
    @Binding var editing: Bool
    
    var body: some View {
        Section(header: HStack {
            Text("Variedades")
            
            if #available(iOS 15.0, *) {
                CompatibleButton(action: {
                    item.variedades.append(VariedadNewS(cantidad: 1))
                }, label: AnyView(Group {
                    Image(systemName: "plus.circle")
                    Text("Agregar")
                }), buttonStyle: .bordered, controlProminence: .standard)
            } else {
                // Fallback on earlier versions
                CompatibleButton(action: {
                    item.variedades.append(VariedadNewS(cantidad: 1))
                }, label: AnyView(Group {
                    Image(systemName: "plus.circle")
                    Text("Agregar")
                }))
            }
        }) {
            if (item.variedades.count != 0) { //There are already some varieties for this item
                HStack {
                    Text("Caducidad")
                        .font(.callout)
                        .bold()
                    Spacer()
                    Text("Cantidad")
                        .font(.callout)
                        .bold()
                }
                //Rows for each variety
                ForEach($item.variedades) { $variedad in
                    if #available(iOS 15.0, *) {
                        VStack {
                            /*
                            NavigationLink(destination: VariantEditViewS(variedad: variedad, onDisappear: { variety in
                                print("ItemDetail, variety quantity: \(variedad.cantidad)")
                                editing = false
                                
                                $variedad.wrappedValue = variety
                                print("ItemDetail, variety quantity: \(variedad.cantidad)")
                                item.setStatusForVarieties()
                            }).onAppear(perform: {
                                editing = true
                            }).onDisappear(perform: {
                                editing = false
                            })) {
                                VarietyRow(variedad: variedad)
                            
                            
                            }
                             */
                            
                            NavigationLink(destination: VariantEditViewSNew(variedad: $variedad, onDisappear: {
                                print("ItemDetail, variety quantity: \(variedad.cantidad)")
                                editing = false
                                
                                //$variedad.wrappedValue = variety
                                item.setStatusForVarieties()
                            }).onAppear(perform: {
                                editing = true
                            }).onDisappear(perform: {
                                editing = false
                            })) {
                                VarietyRow(variedad: $variedad)
                            }
                        }
                        .swipeActions {
                            Button(action: {
                                if variedad.cantidad > 1 {
                                    variedad.cantidad += -1
                                    
                                    var new = variedad
                                    new.cantidad = 1
                                    new.abierto = true
                                    new.id = Identifier(string: String(length: 20))
                                    
                                    item.variedades.append(new)
                                } else if variedad.cantidad == 1 && !variedad.abierto { //Only one remaining, but still closed
                                    variedad.abierto.toggle()
                                } else if variedad.abierto { //Already open, so close
                                    variedad.abierto.toggle()
                                }
                                
                                item.setStatusForVarieties()
                            }) {
                                if !variedad.abierto {
                                    Text("Abrir")
                                } else {
                                    Text("Cerrar")
                                }
                            }
                            .tint(.teal)
                            
                            Button(role: .destructive, action: {
                                if let i = item.variedades.firstIndex(where: {$0.id == variedad.id}) {
                                    item.variedades.remove(at: i)
                                    item.setStatusForVarieties()
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                        }
                    } else {
                        // Fallback on earlier versions
                        VStack {
                            NavigationLink(destination: VariantEditViewS(variedad: variedad, onDisappear: { variety in
                                print("ItemDetail, variety quantity: \(variedad.cantidad)")
                                editing = false
                                
                                $variedad.wrappedValue = variety
                                print("ItemDetail, variety quantity: \(variedad.cantidad)")
                            }).onAppear(perform: {
                                editing = true
                            }).onDisappear(perform: {
                                editing = false
                            })) {
                                VarietyRow(variedad: $variedad)
                            }
                        }
                        .contextMenu(menuItems: {
                            Button(action: {
                                if variedad.cantidad > 1 {
                                    variedad.cantidad += -1
                                    
                                    var new = variedad
                                    new.cantidad = 1
                                    new.abierto = true
                                    new.id = Identifier(string: String(length: 20))
                                    
                                    item.variedades.append(new)
                                } else if variedad.cantidad == 1 && !variedad.abierto { //Only one remaining, but still closed
                                    variedad.abierto.toggle()
                                } else if variedad.abierto { //Already open, so close
                                    variedad.abierto.toggle()
                                }
                                
                                item.setStatusForVarieties()
                            }) {
                                if !variedad.abierto {
                                    Text("Abrir Variedad")
                                } else {
                                    Text("Cerrar Variedad")
                                }
                            }
                            
                            Button(action: {
                                if let i = item.variedades.firstIndex(where: {$0.id == variedad.id}) {
                                    item.variedades.remove(at: i)
                                }
                            }) {
                                Text("Eliminar Variedad")
                                Image(systemName: "trash")
                            }
                        })
                    }
                }
            } else {
                Text("No hay ninguna variedad, intente agregar una.")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
        }
    }
    
    @ViewBuilder
    func VarietyRow(variedad: Binding<VariedadNewS>) -> some View {
        HStack {
            if (variedad.wrappedValue.caducidad != nil) {
                Text(variedad.wrappedValue.caducidadString ?? "")
            } else {
                Text("N/A")
            }
            if (variedad.wrappedValue.status != .Teal && variedad.wrappedValue.abierto) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(Color(UIColor.systemTeal))
            }
            
            Spacer()
            
            numInCircle(number: variedad.wrappedValue.cantidad, color: Color(status: variedad.wrappedValue.status ?? .Verde))
        }
    }
    
    @ViewBuilder
    func VarietyRow(variedad: VariedadNewS) -> some View {
        HStack {
            if (variedad.caducidad != nil) {
                Text(variedad.caducidadString ?? "")
            } else {
                Text("N/A")
            }
            if (variedad.status != .Teal && variedad.abierto) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(Color(UIColor.systemTeal))
            }
            
            Spacer()
            
            numInCircle(number: variedad.cantidad, color: Color(status: variedad.status ?? .Verde))
        }
    }
}

// MARK: TextView
struct TextView: UIViewRepresentable {
    var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        textView.textAlignment = .justified
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}


// MARK: VariantEditViewSNew
struct VariantEditViewSNew: View {
    @Binding var variedad: VariedadNewS
    var onDisappear: closure
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        Form {
            Section(header: Text("Cantidad")) {
                TextField("Cantidad", value: $variedad.cantidad, formatter: formatter)
                    .keyboardType(.numberPad)
            }
            
            Section(header: Text("Caducidad")) {
                if (variedad.caducidad == nil) {
                    Text("Esta variedad no tiene caducidad.")
                    
                    if #available(iOS 15.0, *) {
                        CompatibleButton(action: {
                            variedad.caducidad = Date()
                        }, label: AnyView(Group {
                            Image(systemName: "plus.circle")
                            Text("Agregar")
                        }), buttonStyle: .bordered, controlProminence: .standard)
                    } else {
                        // Fallback on earlier versions
                        CompatibleButton(action: {
                            variedad.caducidad = Date()
                        }, label: AnyView(Group {
                            Image(systemName: "plus.circle")
                            Text("Agregar")
                        }))
                    }
                } else {
                    if variedad.caducidad != nil {
                        DatePicker(selection: $variedad.caducidad.toNonOptional(), displayedComponents: .date) {
                            EmptyView()
                        }
                        .datePickerStyle(.graphical)
                    }
                }
            }
        }
        .onDisappear {
            print("Variety edit view disappearing...")
            print("Variety quantity: \(variedad.cantidad)")
            //onDisappear(variedad)
            onDisappear()
        }
    }
}

// MARK: VariantEditViewS
//@available(iOS 15.0, *)
struct VariantEditViewS: View {
    @State var variedad: VariedadNewS
    var onDisappear: (VariedadNewS) -> Void
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        Form {
            Section(header: Text("Cantidad")) {
                TextField("Cantidad", value: $variedad.cantidad, formatter: formatter)
                    .keyboardType(.numberPad)
            }
            
            Section(header: Text("Caducidad")) {
                if (variedad.caducidad == nil) {
                    Text("Esta variedad no tiene caducidad.")
                    
                    if #available(iOS 15.0, *) {
                        CompatibleButton(action: {
                            variedad.caducidad = Date()
                        }, label: AnyView(Group {
                            Image(systemName: "plus.circle")
                            Text("Agregar")
                        }), buttonStyle: .bordered, controlProminence: .standard)
                    } else {
                        // Fallback on earlier versions
                        CompatibleButton(action: {
                            variedad.caducidad = Date()
                        }, label: AnyView(Group {
                            Image(systemName: "plus.circle")
                            Text("Agregar")
                        }))
                    }
                } else {
                    if variedad.caducidad != nil {
                        DatePicker(selection: $variedad.caducidad.toNonOptional(), displayedComponents: .date) {
                            EmptyView()
                        }
                        .datePickerStyle(.graphical)
                    }
                }
            }
        }
        .onDisappear {
            print("Variety edit view disappearing...")
            print("Variety quantity: \(variedad.cantidad)")
            onDisappear(variedad)
        }
    }
}

// MARK: CompatibleButton
@available(iOS 15.0, *)
@ViewBuilder
func CompatibleButton(action: @escaping () -> Void, label: AnyView, buttonStyle: BorderedButtonStyle = .bordered, controlProminence: Prominence = .standard) -> some View {
    Button(action: {
        action()
    }) {
        label
    }
    .buttonStyle(buttonStyle)
    .controlProminence(controlProminence)
}

@ViewBuilder
func CompatibleButton(action: @escaping () -> Void, prominent: Bool = false, label: AnyView) -> some View {
    if !prominent {
        Button(action: {
            action()
        }) {
            label
        }
    } else {
        Button(action: {
            action()
        }) {
            label
        }
        .padding(10)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(20)
    }
    
}

// MARK: ItemRowS
//@available(iOS 15.0, *)
struct ItemRowS: View {
    @Binding var item: ItemNewS
    @Binding var vm: ItemsViewModelNewS
    var onDisappear: (ItemNewS) -> Void
    
    var body: some View {
        NavigationLink(destination: DetailViewS(item: $item, categoría: $item.wrappedValue.categoría, vm: $vm, onDisappear: { item in
            onDisappear(item)
        })) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.nombre)
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(item.contenido)
                            .font(.subheadline)
                        if (item.alert) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if (item.itemStatus[.Naranja] != 0) {
                        if let dict = item.remainingDays {
                            ForEach(Array(dict.keys), id: \.id) { variety in
                                if let value = dict[variety] {
                                    //Text("\(variety.cantidad) caduca en \(value) días")
                                    AlertForExpiryDateText(días: value, cantidad: variety.cantidad)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Group {
                    if (item.itemStatus[.Rojo] != 0) {
                        numInCircle(number: item.itemStatus[.Rojo], color: .red)
                    }
                    
                    if (item.itemStatus[.Naranja] != 0) {
                        numInCircle(number: item.itemStatus[.Naranja], color: .orange)
                    }
                    
                    if (item.itemStatus[.Teal] != 0) {
                        if #available(iOS 15.0, *) {
                            numInCircle(number: item.itemStatus[.Teal], color: .teal)
                        } else {
                            // Fallback on earlier versions
                            numInCircle(number: item.itemStatus[.Teal], color: Color(UIColor.systemTeal))
                        }
                    }
                    
                    if (item.itemStatus[.Verde] != 0) {
                        numInCircle(number: item.itemStatus[.Verde], color: .green)
                    }
                    
                    if (item.itemStatus[.Rojo] == 0 && item.itemStatus[.Naranja] == 0 && item.itemStatus[.Teal] == 0 && item.itemStatus[.Verde] == 0) {
                        numInCircle(number: 0, color: .secondary)
                    }
                }
            }
        }
    }
}

struct AlertForExpiryDateText: View {
    @State var días: Int
    @State var cantidad: Int
    
    @State private var caducanStr: String = ""
    @State private var díasStr: String = ""
    
    
    var body: some View {
        
        Text("\(cantidad) \(caducanStr) en \(días) \(díasStr)")
            .onAppear {
                if (cantidad > 1) {
                    caducanStr = "caducan"
                } else {
                    caducanStr = "caduca"
                }
                
                if (días > 1) {
                    díasStr = "días"
                } else {
                    díasStr = "día"
                }
            }
            .foregroundColor(.orange)
            .font(Font.caption)
    }
    
}


@available(iOS 15.0, *)
struct ItemNewS_Previews: PreviewProvider {
    static var previews: some View {
        ItemsNewS()
        /*
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("Default preview")
         */
    }
}
