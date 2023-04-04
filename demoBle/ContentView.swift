//
//  ContentView.swift
//  demoBle
//
//  Created by Doan Ho on 03/04/2023.
//

import SwiftUI
import CoreBluetooth
import Foundation

struct PeriDevice: Identifiable{
    var id = UUID()
    var per:CBPeripheral
}

struct ContentView: View {
    @State var showAlert = false
    
    @ObservedObject var plugin = PluginController()
    
    var body: some View {
        VStack {
            List(plugin.peripherals,id: \.self) {
                per in PeripheralView(id: per.identifier.uuidString, name: per.name ?? "")
                    .onTapGesture {
                        self.showAlert = true
                    }
                    .alert(isPresented: $showAlert){
                        let data = plugin.peripheralConnect?.identifier.uuidString == per.identifier.uuidString
                        if !data {
                            return Alert(title:Text("Device \(String(describing: per.name)): (\(per.identifier.uuidString))"),message: Text("Connect"),primaryButton: .cancel(), secondaryButton: Alert.Button.default(Text("Connect")){
                                plugin.connect(per.identifier.uuidString)
                            })
                        }else{
                            return Alert(title:Text("Device \(String(describing: per.name)): (\(per.identifier.uuidString))"),message: Text("Connect"),primaryButton: .cancel(), secondaryButton: Alert.Button.default(Text("Disconnect")){
                                plugin.disconnect()
                            })
                        }
                    }
            }
            HStack(alignment: .center){
                Text("state: \(String(reflecting: plugin.state))")
                Text("status: \(String(reflecting: plugin.status))")
                Text("discoverServived: \(String(plugin.discoverServived))")
                Text("bonded: \(String(plugin.bonded))")
            }
            Button("Scan"){
                plugin.scan()
            }
            Button("stop Scan"){
                plugin.stopScan()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
