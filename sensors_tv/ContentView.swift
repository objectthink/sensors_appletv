//
//  ContentView.swift
//  sensors_tv
//
//  Created by stephen eshelman on 2/18/22.
//

import SwiftUI
import SwiftyNats
import SwiftyJSON

private var client: NatsClient?

class Sensor: Identifiable
{
   var id: String
   var location: String
   var temperature: Int
   var humidity: Int
   var timestamp: Date
   
   var dtFormatter = DateFormatter()
   
   init(id: String, location: String, temperature: Int, humidity: Int)
   {
      self.id = id
      self.temperature = temperature
      self.location = location
      self.humidity = humidity
      
      self.timestamp = Date()
      
      dtFormatter.dateStyle = .short
      dtFormatter.timeStyle = .medium
   }
   
   init(message: NatsMessage)
   {
      let json = JSON(parseJSON: message.payload!)
      
      // get sensor name from status
      id = json["name"].stringValue
      location = json["location"].stringValue
      temperature = json["temperature"].intValue
      humidity = json["humidity"].intValue
      
      dtFormatter.dateStyle = .short
      dtFormatter.timeStyle = .medium

      timestamp = Date()
   }
}

struct SensorRow: View {
   var sensor: Sensor
   var body: some View {

      HStack {
         VStack(alignment: .leading) {
            Text(sensor.location)
            Text(sensor.id).font(.subheadline).foregroundColor(.gray)
            //Text(sensor.timestamp.description)
            Text(sensor.dtFormatter.string(from: sensor.timestamp))
         }
         Spacer()
         Text(String(format: "%d º", sensor.temperature))
      }
   }
}

struct SensorDetail: View {
   @ObservedObject var sensorList: SensorList
   @State private var newLocation: String = ""
   @State private var showDialog = false
   
   
   var sensor: Sensor
   
   @State var showAlert = false
   @State private var newlocation: String = ""
   
   var body: some View {
      VStack {
         //get the sensor out of the list instead
         let sensor = sensorList.sensors[sensor.id]!
         
         Text(sensor.location).font(.headline)
         
         HStack {
            //Text("temperatue - \(String(format: "%d º", sensor.temperature))")
            Text("temperature")
            Spacer()
            Text("\(String(format: "%d º", sensor.temperature))")
         }
         HStack {
            //Text("humidity   - \(String(format: "%d rh", sensor.humidity))")
            Text("humidity")
            Spacer()
            Text("\(String(format: "%d rh", sensor.humidity))")
         }
         
         Spacer()
         
         Button(action: {
            self.showDialog = true
         }, label: {
            Text("change location")
         })
      }
      .frame(width: 500, height: 500)
      .alert(isPresented: $showDialog,
             TextAlert(title: "Change Location",
                       message: "change location of sensor",
                       keyboardType: .alphabet) { result in
         if result != nil
         {
            // Text was accepted
            print("\(result ?? "NOT SET")")
            client!.publish("\(result ?? "NOT SET")", to: sensor.id + ".set.location")
         } else {
            // The dialog was cancelled
            print("dialog canceled")
         }
      })
   }
}

struct ContentView: View {
   @ObservedObject var sensorList: SensorList
   
   func natsSetup()
   {
      if client == nil
      {
         // register a new client
         client = NatsClient("http://10.5.1.216:4222")
         
         // listen to an event
         client!.on(NatsEvent.connected) { _ in
            print("Client connected")
         }
         
         // try to connect to the server
         try? client!.connect()
         
         // subscribe to a channel with a inline message handler.
         client!.subscribe(to: "*.status") {message in
            
            DispatchQueue.main.async {
               let sensor = Sensor(message: message)
               sensorList.sensors[sensor.id] = sensor
            }
         }
         
         // publish an event onto the message strem into a subject
         //client!.publish("this event happened", to: "foo.bar")
      }
   }
   
   init(sensorList: SensorList) {
      self.sensorList = sensorList
      natsSetup()
   }
   
   var body: some View {
      
      NavigationView{
         List
         {
            ForEach(Array(sensorList.sensors.keys), id: \.self) {key in
               if let sensor = sensorList.sensors[key]
               {
                  NavigationLink(destination: SensorDetail(sensorList: sensorList, sensor: sensor)) {
                     SensorRow(sensor: sensor)
                  }
               }
            }
         }
         .navigationBarTitle("Sensors")
      }
   }
}

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      ContentView(sensorList: SensorList())
         .onAppear {
         }
   }
}
