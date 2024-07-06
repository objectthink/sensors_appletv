//
//  sensors_tvApp.swift
//  sensors_tv
//
//  Created by stephen eshelman on 2/18/22.
//

import SwiftUI
import SwiftyNats
import SwiftyJSON

class SensorList: ObservableObject {
   @Published var sensors = [String:Sensor]()
}

@main
struct sensors_tvApp: App {
   @StateObject var sensorList: SensorList = SensorList()
   
    var body: some Scene {
        WindowGroup {
            ContentView(sensorList: sensorList)
        }
    }
}
