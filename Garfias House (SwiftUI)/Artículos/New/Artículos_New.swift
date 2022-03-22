//
//  Artículos_New.swift
//  Garfias House (SwiftUI)
//
//  Created by Gustavo Garfias on 11/06/21.
//

import SwiftUI
import Combine
import CodeScanner

enum ActiveSheet: Identifiable {
    case SearchResult, AddingItem, ScanningItem
    
    var id: Int {
        hashValue
    }
}

// MARK: -Articulos_New
@available(iOS 15.0, *)
struct Articulos_New: View {
    @State var vm = ItemsViewModelNew()
    
    @State private var items = ItemStore(ItemNew.previewData)
    @State private var searchText: String = ""
    
    @State private var newItem = ItemNew.emptyItem
    
    private var categoriesTest: [Categoría] = [.Congelados, .Bebidas, .Lácteos]
    
    @Environment(\.isSearching) private var isSearching: Bool
    
    @State private var activeSheet: ActiveSheet?
    
    func update() {
        vm.fetchData(errorF: {
            //Error
            return
        }, success: {
            self.items = vm.items
        })
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
                    sectionContent(for: $items.favoritos, title: AnyView(HStack {
                        Image(systemName: "star")
                        Text("Favoritos")
                    }), vm: $vm)
                    
                    sections(for: $items, vm: self.$vm)
                } else {
                    sections(for: items, searchText: searchText, vm: self.$vm)
                }
            }
            .searchable(text: $searchText)
            .sheet(item: $activeSheet) { item in // MARK: Articulos_New sheets
                switch item {
                case .SearchResult:
                    DetailView(item: vm.item, categoría: vm.item.categoría, vm: $vm)
                case .AddingItem:
                    DetailView(item: newItem, categoría: .Abarrotes, addingItem: true, vm: $vm)
                case .ScanningItem:
                    //Working barcode example (for simulator):
                    //CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "0061314000070", completion: self.handleScan)
                    
                    //Non-existant barcode example (for simulator):
                    CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "7503030212038", completion: self.handleScan)
                }
            }
            .toolbar {
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
    
    var searchResults: [ItemNew] {
        if searchText.isEmpty {
            return items.all
        } else {
            return items.all.filter({$0.nombre.contains(searchText)})
        }
    }
    
    // MARK: sectionContent
    @ViewBuilder
    private func sectionContent(for items: Binding<[ItemNew]>, title: AnyView, vm: Binding<ItemsViewModelNew>) -> some View {
        if (items.count != 0) {
            Section(header: title) {
                ForEach(items) { $item in
                    itemRow(item: $item, vm: vm)
                        .swipeActions(edge: .trailing) {
                            //Delete
                            Button(role: .destructive, action: {
                                withAnimation {
                                    self.vm.deleteItem(item)
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            //Toggle Favorite
                            Button(action: {
                                withAnimation(.easeInOut(duration: 4)) {
                                    self.vm.starItem(item)
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
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionContent(for items: [ItemNew], title: AnyView, vm: Binding<ItemsViewModelNew>) -> some View {
        if (items.count != 0) {
            Section(header: title) {
                ForEach(items) { item in
                    ItemRow(item: item, vm: vm)
                        .swipeActions(edge: .trailing) {
                            //Delete
                            Button(role: .destructive, action: {
                                withAnimation {
                                    self.vm.deleteItem(item)
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            //Toggle Favorite
                            Button(action: {
                                withAnimation(.easeInOut(duration: 4)) {
                                    self.vm.starItem(item)
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
                }
            }
        }
    }
    
    // MARK: sections
    @ViewBuilder
    private func sections(for items: Binding<ItemStore>, vm: Binding<ItemsViewModelNew>) -> some View {
        sectionContent(for: $items.abarrotes, title: AnyView(Text("Abarrotes")), vm: vm)
        
        sectionContent(for: $items.bebidas, title: AnyView(Text("Bebidas")), vm: vm)
        
        sectionContent(for: $items.congelados, title: AnyView(Text("Congelados")), vm: vm)
        
        sectionContent(for: $items.frutasYVerduras, title: AnyView(Text("Frutas y Verduras")), vm: vm)
        
        sectionContent(for: $items.higiene, title: AnyView(Text("Higiene")), vm: vm)
        
        sectionContent(for: $items.lácteos, title: AnyView(Text("Lácteos")), vm: vm)
        
        sectionContent(for: $items.limpieza, title: AnyView(Text("Limpieza")), vm: vm)
        
        sectionContent(for: $items.medicamentos, title: AnyView(Text("Medicamentos")), vm: vm)
        
        sectionContent(for: $items.panaderíaYTortillería, title: AnyView(Text("Panadería y Tortillería")), vm: vm)
        
        sectionContent(for: $items.salchichonería, title: AnyView(Text("Salchichonería")), vm: vm)
    }
    
    @ViewBuilder
    private func sections(for items: ItemStore, searchText: String, vm: Binding<ItemsViewModelNew>) -> some View {
        if (items.matchesCount(searchText: searchText) > 0) {
            sectionContent(for: items.favouritesFiltered(searchText: searchText), title: AnyView(HStack {
                Image(systemName: "star")
                Text("Favoritos")
            }), vm: vm)
            Group {
                sectionContent(for: items.sectionFiltered(category: .Abarrotes, searchText: searchText), title: AnyView(Text("Abarrotes")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Bebidas, searchText: searchText), title: AnyView(Text("Bebidas")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Congelados, searchText: searchText), title: AnyView(Text("Congelados")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .FrutasYVerduras, searchText: searchText), title: AnyView(Text("Frutas y Verduras")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Higiene, searchText: searchText), title: AnyView(Text("Higiene")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Lácteos, searchText: searchText), title: AnyView(Text("Lácteos")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Limpieza, searchText: searchText), title: AnyView(Text("Limpieza")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Medicamentos, searchText: searchText), title: AnyView(Text("Medicamentos")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .PanaderíaYTortillería, searchText: searchText), title: AnyView(Text("Panadería y Tortillería")), vm: vm)
                sectionContent(for: items.sectionFiltered(category: .Salchichonería, searchText: searchText), title: AnyView(Text("Salchichonería")), vm: vm)
            }
        } else {
            Text("No se encontaron coincidencias.")
        }
    }
}

// MARK: -DetailView
@available(iOS 15.0, *)
struct DetailView: View {
    @State var item: ItemNew
    @State var categoría: Categoría
    @State var addingItem: Bool = false
    @Binding var vm: ItemsViewModelNew
    @State var modified = false
    var updateFunction: closure = { return }
    
    //ImagePicker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var data: Data?
    @State private var image: Image?
    
    @State private var imageURL: URL?
    
    @Environment(\.dismiss) var dismiss
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        
        
        if let data = data {
            vm.saveImage(item: item, data: data)
        }
    }
    
    var body: some View {
        List {
            // MARK: Image
            Group {
                Section(header: VStack {
                    if let imageURL = imageURL {
                        AsyncImage(url: imageURL, content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                        }, placeholder: {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                        })
                            .frame(width: 400, height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        if image != nil {
                            image?
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            HStack {
                                Spacer()
                                Button(action: {
                                    self.showingImagePicker = true
                                }) {
                                    Text("Agregar una foto del artículo")
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                            }
                        }
                    }
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
                        Text(categoría.rawValue)
                        
                        Spacer()
                        
                        Picker("Cambiar", selection: $categoría) {
                            ForEach(Categoría.allCases, id: \.self) { category in
                                Text(category.rawValue)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Código de Barras") {
                    TextField("Código de Barras", text: $item.barcode)
                        .keyboardType(.numberPad)
                }
            }
            
            //VarietyView
            VarietyView(item: $item, vm: $vm)
            
            //Alerts
            AlertView(item: $item)
            
            // MARK: addingItem
            if addingItem {
                //Add item button
                Section(footer: HStack {
                    Spacer()
                    Button(action: {
                        let tmp = self.item
                        tmp.categoría = self.categoría
                        precondition(Thread.isMainThread)
                        vm.addItem(tmp)
                        updateFunction()
                        dismiss()
                    }) {
                        Text("Guardar Artículo")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }) {
                    EmptyView()
                }
            } else if modified {
                // MARK: modifiedItem
                Section(footer: HStack {
                    Spacer()
                    Button(action: {
                        let tmp = self.item
                        tmp.categoría = self.categoría
                        precondition(Thread.isMainThread)
                        vm.updateItem(tmp)
                        updateFunction()
                        dismiss()
                    }) {
                        Text("Guardar Cambios al Artículo")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }) {
                    EmptyView()
                }
            }
        }
        .navigationBarTitle("\(item.nombre) \(item.contenido)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: AlertView
@available(iOS 15.0, *)
struct AlertView: View {
    @Binding var item: ItemNew
    
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
                TextField("", value: $item.quantityAlert, formatter: formatter)
                    .frame(width: 35)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
            
            HStack {
                Text("Caducidad mínima (días):")
                Spacer()
                TextField("", value: $item.expiryDateAlert, formatter: formatter)
                    .frame(width: 35)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
        }
    }
}

// MARK: VarietyView
@available(iOS 15.0, *)
struct VarietyView: View {
    @Binding var item: ItemNew
    @Binding var vm: ItemsViewModelNew
    
    var body: some View {
        Section(header: HStack{
            Text("Variedades")
            Button(action: {
                vm.addVariety(for: item, variedad: VariedadNew(cantidad: 1))
                item.setStatusForVarieties()
            }) {
                Image(systemName: "plus.circle")
                Text("Agregar")
            }
            .buttonStyle(.bordered)
        }) {
            HStack {
                Text("Caducidad")
                    .font(.callout)
                    .bold()
                Spacer()
                Text("Cantidad")
                    .font(.callout)
                    .bold()
            }
            ForEach($item.variedades) { $variedad in
                VStack {
                    NavigationLink(destination: VariantEditView(variedad: $variedad)) {
                        HStack {
                            if (variedad.caducidad != nil) {
                                Text(variedad.caducidadString ?? "")
                            } else {
                                Text("N/A")
                            }
                            Spacer()
                            numInCircle(number: variedad.cantidad, color: variedad.color)
                        }
                    }
                }
                .swipeActions {
                    Button(role: .destructive, action: {
                        vm.deleteVariety(of: item, variedad: variedad)
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

// MARK: VariantEditView
@available(iOS 15.0, *)
struct VariantEditView: View {
    @Binding var variedad: VariedadNew
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        Form {
            Section("Cantidad") {
                TextField("Cantidad", value: $variedad.cantidad, formatter: formatter)
            }
            
            Section("Caducidad") {
                if (variedad.caducidad == nil) {
                    Text("Esta variedad no tiene caducidad.")
                    Button(action: {
                        variedad.caducidad = Date()
                    }) {
                        Image(systemName: "plus.circle")
                        Text("Agregar")
                    }
                    .buttonStyle(.bordered)
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
    }
}

// MARK: ItemRow & itemRow
@available(iOS 15.0, *)
@ViewBuilder
func itemRow(item: ItemNew, vm: Binding<ItemsViewModelNew>) -> some View {
    NavigationLink(destination: DetailView(item: item, categoría: item.categoría, vm: vm), label: {
        HStack {
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
            
            Spacer()
            
            HStack {
                if (item.itemStatus[.Rojo] != 0) {
                    numInCircle(number: item.itemStatus[.Rojo], color: .red)
                }
                
                if (item.itemStatus[.Naranja] != 0) {
                    numInCircle(number: item.itemStatus[.Naranja], color: .orange)
                }
                
                if (item.itemStatus[.Teal] != 0) {
                    numInCircle(number: item.itemStatus[.Teal], color: .teal)
                }
                
                if (item.itemStatus[.Verde] != 0) {
                    numInCircle(number: item.itemStatus[.Verde], color: .green)
                }
            }
        }
    })
}

@available(iOS 15.0, *)
@ViewBuilder
func itemRow(item: Binding<ItemNew>, vm: Binding<ItemsViewModelNew>) -> some View {
    NavigationLink(destination: DetailView(item: item.wrappedValue, categoría: item.wrappedValue.categoría, vm: vm), label: {
        HStack {
            HStack {
                Text(item.wrappedValue.nombre)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(item.wrappedValue.contenido)
                    .font(.subheadline)
                if (item.wrappedValue.alert) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            HStack {
                if (item.wrappedValue.itemStatus[.Rojo] != 0) {
                    numInCircle(number: item.wrappedValue.itemStatus[.Rojo], color: .red)
                }
                
                if (item.wrappedValue.itemStatus[.Naranja] != 0) {
                    numInCircle(number: item.wrappedValue.itemStatus[.Naranja], color: .orange)
                }
                
                if (item.wrappedValue.itemStatus[.Teal] != 0) {
                    numInCircle(number: item.wrappedValue.itemStatus[.Teal], color: .teal)
                }
                
                if (item.wrappedValue.itemStatus[.Verde] != 0) {
                    numInCircle(number: item.wrappedValue.itemStatus[.Verde], color: .green)
                }
            }
        }
    })
}

@available(iOS 15.0, *)
struct ItemRow: View {
    var item: ItemNew
    @Binding var vm: ItemsViewModelNew
    /*
    init(_ item: ItemNew) {
        self.item = item
    }
    */
     
    var body: some View {
        NavigationLink(destination: DetailView(item: item, categoría: item.categoría, vm: $vm), label: {
            HStack {
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
                
                Spacer()
                
                HStack {
                    if (item.itemStatus[.Rojo] != 0) {
                        numInCircle(number: item.itemStatus[.Rojo], color: .red)
                    }
                    
                    if (item.itemStatus[.Naranja] != 0) {
                        numInCircle(number: item.itemStatus[.Naranja], color: .orange)
                    }
                    
                    if (item.itemStatus[.Teal] != 0) {
                        numInCircle(number: item.itemStatus[.Teal], color: .teal)
                    }
                    
                    if (item.itemStatus[.Verde] != 0) {
                        numInCircle(number: item.itemStatus[.Verde], color: .green)
                    }
                }
            }
        })
       
    }
}

struct Arti_culos_New_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            Articulos_New()
                .preferredColorScheme(.dark)
        } else {
            // Fallback on earlier versions
        }
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}

extension Binding where Value == Date? {
    func toNonOptional() -> Binding<Date> {
        return Binding<Date>(
            get: {
                return self.wrappedValue ?? Date()
            },
            set: {
                self.wrappedValue = $0
            }
        )
    }
}

extension Binding where Value == String? {
    func toNonOptional() -> Binding<String> {
        return Binding<String>(
            get: {
                return self.wrappedValue ?? ""
            },
            set: {
                self.wrappedValue = $0
            }
        )
    }
}
