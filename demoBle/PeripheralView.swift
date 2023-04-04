//
//  PeripheralView.swift
//  demoBle
//
//  Created by Doan Ho on 03/04/2023.
//

import Foundation
import SwiftUI
import CoreBluetooth

struct PeripheralView :View{
    var id:String
    var name:String
    var body:some View{
        HStack(alignment: .center){
            Text("\(id): ")
            Text(name)
        }
    }
}

struct PeripheralView_Previews:PreviewProvider{
    static var previews: some View{
        PeripheralView(id: "Test", name: "Test Name")
    }
}
