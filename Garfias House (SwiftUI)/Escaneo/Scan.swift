//
//  Scan.swift
//  G House (iOS 15, *)
//
//  Created by Gustavo Garfias on 22/03/22.
//

import SwiftUI
import Combine
import CodeScanner
import Foundation
import AVFoundation

struct Scan: View {
    
    //ViewModel
    @State var vm = ItemsViewModelNewS()
    @State private var activeSheet: ActiveSheet?
    @State private var newItem = ItemNewS(empty: true)
    
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
    
    func saveChanges(item: ItemNewS) {
        vm.updateItem(item)
        
        self.newItem = ItemNewS(empty: true)
        self.activeSheet = nil
        
        vm.item = ItemNewS(empty: true)
    }
    
    func resetItemNew(item: ItemNewS) {
        self.newItem = ItemNewS(empty: true)
    }
    
    //Camera options
    @State var torchMode: AVCaptureDevice.TorchMode = .off
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
                torchMode = .off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                    torchMode = .on
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        NavigationView {
            CodeScannerView(codeTypes: [.ean13, .ean8], scanMode: .continuous, simulatedData: "7503030212038", completion: self.handleScan)
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .SearchResult:
                        NavigationView {
                            DetailViewS(item: $vm.item, categoría: vm.item.categoría, vm: $vm, onDisappear: saveChanges(item:))
                                .navigationBarTitle(Text(vm.item.nombre + " " + vm.item.contenido), displayMode: .inline)
                        }
                    case .AddingItem:
                        NavigationView {
                            DetailViewS(item: $newItem, categoría: .Abarrotes, addingItem: true, vm: $vm, onDisappear: resetItemNew(item:))
                                .navigationBarTitle(Text(newItem.nombre + " " + newItem.contenido), displayMode: .inline)
                        }
                    case .ScanningItem:
                        //Working barcode example (for simulator):
                        //CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "0061314000070", completion: self.handleScan)
                        
                        //Non-existant barcode example (for simulator):
                        CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "7503030212038", completion: self.handleScan)
                    }
                }
                .navigationBarTitle(Text("Escanear Artículo"), displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            //Action
                            self.toggleFlash()
                        }, label: {
                            if self.torchMode == .on {
                                Image(systemName: "bolt.circle.fill")
                            }
                            else if torchMode == .off {
                                Image(systemName: "bolt.circle")
                            }
                        })
                    }
                }
        }
    }
}
