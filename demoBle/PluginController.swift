//
//  PluginController.swift
//  demoBle
//
//  Created by Doan Ho on 03/04/2023.
//

import Foundation
import CoreBluetooth

enum StatusBlue: Int{
    case turningOn = 0
    case on = 1
    case turningOff = 2
    case off = 3
    case notSupport = 4
}

enum StateBle: Int{
    case connecting = 0
    case connected = 1
    case disconnecting = 2
    case disconnected = 3
}

class PluginController: NSObject, ObservableObject{
    private var centralManager: CBCentralManager?
    @Published var peripherals: [CBPeripheral] = []
    @Published var status:StatusBlue = StatusBlue.notSupport
    @Published var state: StateBle = StateBle.disconnected
    var countDiscoverServices = 0
    @Published var discoverServived = false
    var timer: Timer? = nil
    @Published var bonded = false
    @Published var characteristics: [CBCharacteristic] = []
    
    @Published var peripheralConnect: CBPeripheral? = nil
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func scan(){
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: "FEE0")])
    }
    
    func stopScan(){
        centralManager?.stopScan()
    }
    
    func connect(_ deviceId: String){
        print("\(deviceId)")
        if let peripheral = self.peripherals.first(where: {CBUUID(string: deviceId).uuidString == $0.identifier.uuidString}){
            self.peripheralConnect = peripheral
            self.peripheralConnect!.delegate = self
            stopScan()
            self.state = StateBle.connecting
            self.centralManager!.connect(self.peripheralConnect!,options: nil)
        }
        else{
            print("not found device: \(deviceId)")
        }
    }
    
    private func subscriber(_ characteristicId:String)->Void{
        print("char noti \(characteristicId)")
        if let peripheral = peripheralConnect{
            if let characteristic = characteristics.first(where: {CBUUID(string: characteristicId).uuidString == $0.uuid.uuidString}){
                peripheral.setNotifyValue(true, for: characteristic)
                //                if let descriptor = characteristic.descriptors?.first(where: {$0.uuid.uuidString == "2902"}){
                //                    device.peripheral?.writeValue(Data([0x00]), for: descriptor)
                //                }
            }
        }
    }
    
    func disconnect(){
        if let peripheral = peripheralConnect{
            self.state = StateBle.disconnecting
            self.centralManager?.cancelPeripheralConnection(peripheral)
            self.peripheralConnect = nil
            self.characteristics = []
            self.discoverServived = false
            self.countDiscoverServices = 0
            self.bonded = false
        }
    }
}

extension PluginController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("\(central.state)")
        switch central.state{
        case .poweredOn: status = StatusBlue.on
        case .poweredOff: status = StatusBlue.off
        case .unknown: status = StatusBlue.notSupport
        case .resetting: status = StatusBlue.notSupport
        case .unsupported: status = StatusBlue.notSupport
        case .unauthorized: status = StatusBlue.notSupport
        @unknown default: status = StatusBlue.notSupport
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral){
            self.peripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let err = error{
            print("didFailToConnect: \(err.localizedDescription)")
        }
        self.state = StateBle.disconnected
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let err = error{
            // callback when unpair pairing request,
            if err.localizedDescription.contains("The specified device has disconnected from us"){
                timer?.invalidate()
                timer = nil
                bonded = false
            }
            
            // callback when connect timeout, ...
            print("didDisconnectPeripheral: \(err.localizedDescription)")
        }
        self.state = StateBle.disconnected
        self.discoverServived = false
        self.countDiscoverServices = 0
        self.characteristics = []
        self.peripheralConnect = nil
        self.bonded = false
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.state = StateBle.connected
        peripheral.discoverServices([CBUUID(string: "FEE0")])
    }
}

extension PluginController: CBPeripheralDelegate{
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error{
            print("didDiscoverServices: \(err.localizedDescription)")
        }
        countDiscoverServices = peripheral.services?.count ?? 0
        for service in peripheral.services ?? []{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error{
            print("didDiscoverCharacteristicsFor: \(err.localizedDescription)")
        }
        self.countDiscoverServices  = self.countDiscoverServices - 1
        for characteristic in service.characteristics ?? []{
            if characteristic.properties.contains(.notify) && timer == nil{
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){
                    timer in
                    self.subscriber(characteristic.uuid.uuidString)
                }
            }
            self.characteristics.append(characteristic)
        }
        if self.countDiscoverServices <= 0{
            self.countDiscoverServices = 0
            self.discoverServived = true
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor")
        // close timer
        timer?.invalidate()
        timer = nil
        bonded = true
        // end close timer
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor")
        // close timer
        timer?.invalidate()
        timer = nil
        bonded = true
        // end close timer
    }
}
