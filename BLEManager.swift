//
//  BLEManager.swift
//  cvd19-virus-sensor
//
//  Modified by Zhao Wang on 2021/03/07.
//

import Foundation
import UIKit
import CoreBluetooth
import Charts

class BLEManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate{
    
    //MARK: local variables
    private var manager : CBCentralManager! = nil
    var periph : CBPeripheral!
    
    var isScanning = false
    var connected : Bool = false
    var viewCtl : ViewController!
    var connected_air : Int = 0
    
    var table : UITableView!
    var currentMag1Time : Double = 0
    var currentMag2Time : Double = 0
    var currentMag3Time : Double = 0
    var dataIndex : Int = 0
    var timeSpace : UInt32 = 1
    var virusSensor1Data : [ChartDataEntry]!
    var LineGraph : LineChartView!
    
    var currentMagTime_tvoc : Double = 0
    var dataIndex_tvoc : Int = 0
    var tvocSensorData : [ChartDataEntry]!
    var LineGraph_tvoc : LineChartView!
    
    var currentMagTime_co2 : Double = 0
    var dataIndex_co2 : Int = 0
    var co2SensorData : [ChartDataEntry]!
    var LineGraph_co2 : LineChartView!
    
    var bpmLabel : UILabel!
    var temperatureLabel : UILabel!
    var oxygenLabel : UILabel!
    var bloodPressureLabel : UILabel!
    var covidResLabel : UILabel!
    var tvocLabel : UILabel!
    var co2Label : UILabel!
    
    //MARK: Observable Variables
    var deviceList : [CBPeripheral] = []
    var deviceNames : [String] = []
    
    var connButton : UIButton!
    var warningTriggered : Bool = false
    var threshold = 800.0
    
    //MARK: public vars
    var virusSensor_UUID : CBUUID = CBUUID.init(string: "ba65b745-f9f7-4873-9289-bb93564909f3")
    var HEARTRATE_UUID : CBUUID = CBUUID.init(string: "f87ef99e-a101-4518-958b-4def53dc4b8e")
    var TEMPERATURE_UUID : CBUUID = CBUUID.init(string: "38bca6e3-05a4-487d-95b0-351a3e25eae1")
    var OXYGEN_UUID : CBUUID = CBUUID.init(string: "2f63d787-50dc-42e6-ace0-a403958a02b6")
    var BLOOD_PRESSURE_UUID : CBUUID = CBUUID.init(string: "1652fe5c-c98a-48da-99df-c1d09d0a88c8")
    var FAN_SPEED_UUID : CBUUID = CBUUID.init(string: "98cd17c3-0da1-46ee-9c8d-6c09d2ade30b")
    var THRESHOLD_UUID : CBUUID = CBUUID.init(string: "3e9c01e6-12de-11eb-adc1-0242ac120002")
    var TVOC_UUID : CBUUID = CBUUID.init(string: "04f64a0d-d12a-492b-9e58-f348fc6e59b6")
    var CO2_UUID : CBUUID = CBUUID.init(string: "e4964b4a-7508-4f2b-be6e-398aeb932589")
    
    private var virusSensorService : CBService!
    private var virusSensor1Characteristic : CBCharacteristic!
    private var thresholdCharacteristic : CBCharacteristic!
    private var heartrateCharacteristic : CBCharacteristic!
    private var oxygenCharacteristic : CBCharacteristic!
    private var temperatureCharacteristic : CBCharacteristic!
    //private var bloodPressureCharacteristic : CBCharacteristic!
    private var fanSpeedCharacteristic : CBCharacteristic!
    private var tvocCharacteristic : CBCharacteristic!
    private var co2Characteristic : CBCharacteristic!
    
    public func setTableView(_ table: UITableView!){
        self.table = table
        table.dataSource = self
        table.delegate = self
    }
    
    public func setConnButton(_ button: UIButton!){
        self.connButton = button
    }
    
    public func startScan(){
        self.manager = CBCentralManager(delegate: self, queue: nil)
        print("BLE Manager scan is starting...")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unsupported:
            print("BLE Unsupported by this Device")
            break
        case .resetting:
            print("Bluetooth Module Resetting...")
            break
        case .unauthorized:
            print("Not authorized to start bluetooth comms... Check permissions")
            break
        case .unknown:
            print("Device status unknown!!!")
            break
        case .poweredOff:
            print("Bluetooth has powered off.")
            break
        case .poweredOn:
            print("Bluetooth turned on. Scanning for service uuid...")
            self.manager.scanForPeripherals(withServices: [], options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
            //self.manager.scanForPeripherals(withServices: [virusSensor_UUID], options:[CBCentralManagerScanOptionAllowDuplicatesKey : false])
            isScanning = true
            break
        default:
            print("Error!")
        }
    }
    
    func setFanSpeed(_ speed: Float){
        if connected && fanSpeedCharacteristic != nil{
            var value = String(speed)
        let data = Data(bytes: &value, count: 1)
        periph.writeValue(data as Data, for: fanSpeedCharacteristic, type: .withResponse)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        let device_name = "Azar Telemedecine"
        let end = device_name.index(device_name.startIndex, offsetBy: device_name.count)
        let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID]
        var service_id = TEMPERATURE_UUID // use the temperature uuid as a place-filler CBUUID
        if(uuids != nil && uuids!.count > 0) {
            service_id = (uuids?.first)!
        }
        if(!idInDevices(peripheral.identifier) &&
            service_id == virusSensor_UUID ||
            peripheral.name != nil &&
            peripheral.name!.count >= device_name.count &&
            peripheral.name?.substring(to: end) == device_name)
        {
        print("New peripheral found! \(peripheral.name ?? "NONE") : \(peripheral.description)")
        deviceNames.append(peripheral.name ?? "UNKNOWN DEVICE")
        deviceList.append(peripheral)
        table.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connected = true
        currentMag1Time = 0
        print("Connected successfully!")
        print("Discovering services...")
        peripheral.discoverServices(nil)
    }
        
    func connectToPeripheral(){
        if(periph != nil){
            threshold = 800.0
        print("Connecting to selected peripheral : \(periph.name ?? "UNKNOWN DEVICE")!")
        self.manager.stopScan()
        isScanning = false
        self.periph.delegate = self
        manager.connect(self.periph)
        }
    }
    
    func disconnectFromPeripheral(){
        connected = false
        if(self.periph != nil) {
            self.manager.cancelPeripheralConnection(self.periph)
        }
        deviceList = []
        deviceNames = []
        periph = nil
        table.reloadData()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to device!")
        connected = false
        // TODO UIAlertController(title: "Failure", message: "Unable to connect to \(peripheral.name)! Error: \(error?.localizedDescription)", preferredStyle: .alert).present(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: <#T##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
    }
    
    func stopScan(){
        if(isScanning){
            self.manager.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "UNKNOWN DEVICE")")
        disconnectFromPeripheral()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        if(error == nil){
            for service in peripheral.services!{
                if(service.uuid == virusSensor_UUID){
                    virusSensorService = service
                    break
                }
            }
            peripheral.discoverCharacteristics([virusSensor_UUID, HEARTRATE_UUID, OXYGEN_UUID, TEMPERATURE_UUID, FAN_SPEED_UUID, THRESHOLD_UUID, TVOC_UUID, CO2_UUID], for: virusSensorService)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(error == nil){
        for characteristic in service.characteristics!{
            if(characteristic.uuid == virusSensor_UUID){
                virusSensor1Characteristic = characteristic
            }
            else if(characteristic.uuid == HEARTRATE_UUID){
                heartrateCharacteristic = characteristic
            }
            else if(characteristic.uuid == OXYGEN_UUID){
                oxygenCharacteristic = characteristic
            }
            else if(characteristic.uuid == TEMPERATURE_UUID){
                temperatureCharacteristic = characteristic
            }
            else if(characteristic.uuid == FAN_SPEED_UUID){
                fanSpeedCharacteristic = characteristic
            }
            else if(characteristic.uuid == FAN_SPEED_UUID){
                fanSpeedCharacteristic = characteristic
            }
            else if(characteristic.uuid == THRESHOLD_UUID) {
                thresholdCharacteristic = characteristic
            }
            else if(characteristic.uuid == TVOC_UUID) {
                tvocCharacteristic = characteristic
            }
            else if(characteristic.uuid == CO2_UUID) {
                co2Characteristic = characteristic
            }
        }
            peripheral.readValue(for: virusSensor1Characteristic)
            peripheral.readValue(for: heartrateCharacteristic)
            peripheral.readValue(for: oxygenCharacteristic)
            peripheral.readValue(for: temperatureCharacteristic)
            peripheral.readValue(for: thresholdCharacteristic)
            peripheral.readValue(for: tvocCharacteristic)
            peripheral.readValue(for: co2Characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error == nil && characteristic == virusSensor1Characteristic){
            let val = String(decoding: characteristic.value!, as: UTF8.self)
            //print("virusSensor value: \(val)")
            let dispatch = DispatchQueue(label: "valueThread", qos: .userInteractive)
            dispatch.async {
                usleep(1 * 1000 * 1000)
                peripheral.readValue(for: characteristic)
            }
            var value = Double(val)
            if(value == nil || value! < 0.0){
                value = 0.0
            }
            let dataEntry = ChartDataEntry(x: currentMag1Time, y: value!)
            self.currentMag1Time += 1
            let dataSet = LineGraph.lineData?.dataSets[0] as! LineChartDataSet
            dataSet.append(dataEntry)
            LineGraph.lineData?.notifyDataChanged()
            LineGraph.notifyDataSetChanged()
            self.dataIndex += 1
            if(value! >= threshold){
                print("VALUE REALLY HIGH!")
                warningTriggered = true
                covidResLabel.text = "positive"
                covidResLabel.textColor = .red
            }
            else {
                covidResLabel.text = "negative"
                covidResLabel.textColor = .green
                DispatchQueue.main.async {
                    self.viewCtl.toggleWarning(warningTriggered: false)
                }
            }
        }
        else if(error == nil && characteristic == temperatureCharacteristic){
            //MARK: update temperature value
            var val = String(decoding: characteristic.value!, as: UTF8.self)
            if(val == "1899.59") {
                val = "---"
            }
            temperatureLabel.text = "\(val) ℉"
            let queue = DispatchQueue(label: "temperatureThread", qos: .userInteractive)
            queue.async{
                peripheral.readValue(for: characteristic)
            }
        }
        else if(error == nil && characteristic == heartrateCharacteristic){
            //MARK: update heartrate value
            var val = String(decoding: characteristic.value!, as: UTF8.self)
            if(val == "-1.0"){
                val = "---"
            }
            bpmLabel.text = "\(val)"
            let queue = DispatchQueue(label: "bpmThread", qos: .userInteractive)
            queue.async{
                peripheral.readValue(for: characteristic)
            }
        }
        else if(error == nil && characteristic == oxygenCharacteristic){
            //MARK: update oxygen value
            var val = String(decoding: characteristic.value!, as: UTF8.self)
            if(val == "-1.0"){
                val = "---"
            }
            oxygenLabel.text = "\(val)"
            let queue = DispatchQueue(label: "oxygenThread", qos: .userInteractive)
            queue.async{
                peripheral.readValue(for: characteristic)
            }
        }
        else if(error == nil && characteristic == thresholdCharacteristic){
            //MARK: update threshold value
            let val = String(decoding: characteristic.value!, as: UTF8.self)
            threshold = Double(val) ?? 800.0
            let queue = DispatchQueue(label: "thresholdThread", qos: .userInteractive)
            queue.async{
                peripheral.readValue(for: characteristic)
            }
        }
        else if(error == nil && characteristic == tvocCharacteristic && connected_air == 1){
            //MARK: update tvoc value
            let val = String(decoding: characteristic.value!, as: UTF8.self)
            var val_l = val
            let dispatch = DispatchQueue(label: "tvocThread", qos: .userInteractive)
            dispatch.async {
                usleep(1 * 1000 * 100)
                peripheral.readValue(for: characteristic)
            }
            var value = Double(val)
            if(val == "-1.0"){
                val_l = "---"
            }
            if(value == nil || value! < 0.0){
                value = 0.0
            }
            tvocLabel.text = "\(val_l)"
            let dataEntry = ChartDataEntry(x: currentMagTime_tvoc, y: value!)
            self.currentMagTime_tvoc += 1
            let dataSet = LineGraph_tvoc.lineData?.dataSets[0] as! LineChartDataSet
            dataSet.append(dataEntry)
            LineGraph_tvoc.lineData?.notifyDataChanged()
            LineGraph_tvoc.notifyDataSetChanged()
            self.dataIndex_tvoc += 1
        }
        else if(error == nil && characteristic == co2Characteristic && connected_air == 1){
            //MARK: update co2 value
            let val = String(decoding: characteristic.value!, as: UTF8.self)
            var val_l = val
            let dispatch = DispatchQueue(label: "co2Thread", qos: .userInteractive)
            dispatch.async {
                usleep(1 * 1000 * 100)
                peripheral.readValue(for: characteristic)
            }
            var value = Double(val)
            if(val == "-1.0"){
                val_l = "---"
            }
            if(value == nil || value! < 0.0){
                value = 0.0
            }
            co2Label.text = "\(val_l)"
            let dataEntry = ChartDataEntry(x: currentMagTime_co2, y: value!)
            self.currentMagTime_co2 += 1
            let dataSet = LineGraph_co2.lineData?.dataSets[0] as! LineChartDataSet
            dataSet.append(dataEntry)
            LineGraph_co2.lineData?.notifyDataChanged()
            LineGraph_co2.notifyDataSetChanged()
            self.dataIndex_co2 += 1
        }
    }
    
    func idInDevices(_ id: UUID) -> Bool{
        for dev in deviceList{
            if(dev.identifier == id){
                return true
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.deviceNames.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "devCell")
        
        cell.textLabel?.text = deviceNames[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        connButton.isEnabled = true
        print("Peripheral set to \(deviceNames[indexPath.row])")
        periph = deviceList[indexPath.row]
    }
    
}
