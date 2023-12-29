//
//  ViewController.swift
//  cvd19-virus-sensor
//
//  Modified by Zhao Wang on 2021/03/07.
//

import UIKit
import Charts
import Alamofire
import FirebaseDatabase
import FirebaseCore

class ShareButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.shadowRadius = 5.0
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: 50).isActive = true
        self.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.setTitle("", for: .normal)
    }
}

class ViewController: UIViewController {
    var bleManager = BLEManager()
    var dataIndex = 0
    
    /*
    struct Model: Codable {
        
        let test_result = ""
        let longitude = ""
        let latitude = ""
    }*/
    
    @IBOutlet var LineChart: LineChartView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var oxygenLabel: UILabel!
    @IBOutlet weak var bloodPressureLabel: UILabel!
    @IBOutlet weak var covidResLabel: UILabel!
    @IBOutlet weak var shareButton: UILabel!
    @IBOutlet weak var co2Label: UILabel!
    @IBOutlet weak var tvocLabel: UILabel!
    @IBOutlet weak var airButton: UIButton!
    
    var virusSensor1DataSet : LineChartDataSet!
    var virusSensor2DataSet : LineChartDataSet!
    var virusSensor3DataSet : LineChartDataSet!
    var measurementData : LineChartData!
    var virusSensor1Data : [ChartDataEntry]!
    var virusSensor2Data : [ChartDataEntry]!
    var virusSensor3Data : [ChartDataEntry]!
    var dbRef: DatabaseReference!
    @IBOutlet var titleText: UILabel!
    @IBOutlet weak var fanSpeedSlider: UISlider!
    
    
    @IBAction func roundSliderValue(_ sender: AnyObject) {
        sender.setValue(roundf(sender.value), animated: true)
        print("New value")
        bleManager.setFanSpeed(roundf(fanSpeedSlider.value))
    }
    
    var redVal : CGFloat = 0
    var warningTriggered : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let model: Model
        dbRef = Database.database().reference()
        virusSensor1Data = []
        virusSensor1DataSet = LineChartDataSet(entries: virusSensor1Data, label: "# Viruses Detected")
        
        measurementData = LineChartData(dataSet: virusSensor1DataSet)
        measurementData.setDrawValues(false)
        LineChart.noDataText = "Please connect to device to start plotting data."
        LineChart.data = measurementData
        LineChart.data?.setDrawValues(false)
        LineChart.xAxis.axisLineWidth = 1.0
        LineChart.xAxis.drawLabelsEnabled = true
        LineChart.autoresizesSubviews = true
        LineChart.leftAxis.axisMinimum = 0.0
        LineChart.leftAxis.drawBottomYLabelEntryEnabled = true
        LineChart.leftAxis.drawTopYLabelEntryEnabled = false
        LineChart.xAxis.labelPosition = .bottom
        LineChart.leftAxis.accessibilityLabel = "# Viruses Detected"
        LineChart.rightAxis.axisMinimum = 100.0
        LineChart.leftAxis.axisMaximum = 1500.0
        LineChart.rightAxis.axisMaximum = 1500.0
        LineChart.leftAxis.axisMinimum = 100.0
        LineChart.xAxis.axisMinimum = 0.0
        LineChart.rightAxis.drawLabelsEnabled = false
        
        statusLabel.textColor = .red
        statusLabel.text = "Disconnected"
                
        virusSensor1DataSet.drawFilledEnabled = true
        virusSensor1DataSet.setColor(.blue)
        virusSensor1DataSet.circleRadius = 1.5
        virusSensor1DataSet.circleHoleRadius = 0.125
        
        LineChart.borderColor = .black
        LineChart.borderLineWidth = 1.0
    }

    //MARK: actions
    @IBAction func showConnectionDialog(_ sender: UIButton) {
        if(sender == connectionButton && sender.currentTitle == "Connect to Device"){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let connDialog = storyboard.instantiateViewController(withIdentifier: "connDialog") as! ConnDialogController
            connDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            connDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            connDialog.bleManager = bleManager
            connDialog.dataView = self
            self.present(connDialog, animated: true, completion: nil)
        }
        else if(sender == connectionButton){
            bleManager.disconnectFromPeripheral()
            LineChart.lineData?.dataSets[0].clear()
            connectionButton.setTitle("Connect to Device", for: .normal)
            statusLabel.textColor = .red
            statusLabel.text = "Disconnected"
        }
    }

    //MARK: actions
    @IBAction func openShareDialog(_ sender: UIButton) {
        if(sender == shareButton){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let shareDialog = storyboard.instantiateViewController(withIdentifier: "shareDialog") as! ShareController
        shareDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        shareDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            shareDialog.test_res = covidResLabel.text ?? ""
            self.present(shareDialog, animated: true, completion: nil)
//        connDialog.bleManager = bleManager
//        connDialog.dataView = self
//            self.present(connDialog, animated: true, completion: nil)
//        }
//        else if(sender == connectionButton){
//            bleManager.disconnectFromPeripheral()
//            LineChart.lineData?.dataSets[0].clear()
//            connectionButton.setTitle("Connect to Device", for: .normal)
//            statusLabel.textColor = .red
//            statusLabel.text = "Disconnected"
        }
    }
    @IBAction func openAirDialog(_ sender: UIButton) {
        if(sender == airButton) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let airDialog = storyboard.instantiateViewController(withIdentifier: "airDialog") as! AirQualityController
            airDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            airDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            airDialog.bleManager = bleManager
            airDialog.dataView = self
            self.present(airDialog, animated: true, completion: nil)
        }
    }
    
    //MARK: actions
    @IBAction func showMap(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openMap", sender: self)
    }
    
    @IBAction func showAir(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openAir", sender: self)
    }
    
    //MARK: actions
    @IBAction func showShare(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openShare", sender: self)
    }
    
    func connectToDevice(){
        bleManager.LineGraph = self.LineChart
        bleManager.virusSensor1Data = self.virusSensor1Data
        bleManager.warningTriggered = self.warningTriggered
        bleManager.bpmLabel = self.bpmLabel
        bleManager.oxygenLabel = self.oxygenLabel
        bleManager.temperatureLabel = self.temperatureLabel
        bleManager.bloodPressureLabel = self.bloodPressureLabel
        bleManager.covidResLabel = self.covidResLabel
        bleManager.viewCtl = self
        bleManager.connectToPeripheral()
        if(bleManager.periph != nil){
        connectionButton.setTitle("Disconnect", for: .normal)
        statusLabel.text = "Connected!"
        statusLabel.textColor = .green
        }
    }
    
    func connectToAir() {
        bleManager.connected_air = 1
        bleManager.connectToPeripheral()
    }
    
    func toggleWarning(warningTriggered: Bool){
        //Send warning message!
//        sendWarningMessage()
//        Launch warning view
        //print("Value threshold exceeded...")
//        if(warningTriggered) {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let warningDiag = storyboard.instantiateViewController(withIdentifier: "warningDialog") as! WarningDialogController
//            warningDiag.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//            warningDiag.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
//            warningDiag.resolvingView = self
//            self.present(warningDiag, animated: true, completion: nil)
//        }
//        }
    }
    
    func resolveWarning(){
        warningTriggered = false
        bleManager.warningTriggered = false
    }
    
    func sendWarningMessage(){
        let accountID = "ACae565f497d3b648a6b9ab351bf1b8fa7"
        let authToken = "d95bf0dc1f1850eedff1bec07a6dfc26"
        let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountID)/Messages"
        let params = ["From": "+12513578303", "To": "+18015976892", "Body": "virusSensor value exceeded set threshold on \(Date())"]
        AF.request(url, method: .post, parameters: params).authenticate(username: accountID, password: authToken).response{
            result in
            print(result)
        }
    }
}
