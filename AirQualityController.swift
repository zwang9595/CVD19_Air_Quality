//
//  AirQualityController.swift
//  Azar Telemedicine
//
//  Created by Zhao Wang on 2021/03/07.
//  Copyright © 2021 Zhao Wang. All rights reserved.
//

import Foundation
import UIKit
import Charts
import Alamofire
import FirebaseDatabase
import FirebaseCore

class AirQualityController: UIViewController {
    
    var bleManager : BLEManager!
    var dataView : ViewController!
    
    @IBOutlet var tvocChart: LineChartView!
    @IBOutlet var co2Chart: LineChartView!
    
    @IBOutlet weak var tvocLabel: UILabel!
    @IBOutlet weak var co2Label: UILabel!
    
    var tvocDataSet : LineChartDataSet!
    var co2DataSet : LineChartDataSet!
    var tvocMeasurement : LineChartData!
    var co2Measurement : LineChartData!
    var tvocData : [ChartDataEntry]!
    var co2Data : [ChartDataEntry]!
    
    @IBAction func closeAir(_ sender: UIButton) {
        tvocChart.lineData?.dataSets[0].clear()
        co2Chart.lineData?.dataSets[0].clear()
        bleManager.connected_air = 0
        bleManager.currentMagTime_tvoc = 0
        bleManager.currentMagTime_co2 = 0
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(bleManager.connected_air)
        bleManager.tvocLabel = self.tvocLabel
        bleManager.co2Label = self.co2Label
        
        tvocData = []
        co2Data = []
        
        tvocDataSet = LineChartDataSet(entries: tvocData, label: "tvoc ppm")
        co2DataSet = LineChartDataSet(entries: co2Data, label: "co2 ppb")
        
        tvocMeasurement = LineChartData(dataSet: tvocDataSet)
        co2Measurement = LineChartData(dataSet: co2DataSet)
        tvocMeasurement.setDrawValues(false)
        co2Measurement.setDrawValues(false)
        
        tvocChart.noDataText = "Please connect to device to start plotting data."
        co2Chart.noDataText = "Please connect to device to start plotting data."
        
        tvocChart.data = tvocMeasurement
        tvocChart.data?.setDrawValues(false)
        tvocChart.xAxis.axisLineWidth = 1.0
        tvocChart.xAxis.drawLabelsEnabled = true
        tvocChart.autoresizesSubviews = true
        tvocChart.leftAxis.drawBottomYLabelEntryEnabled = true
        tvocChart.leftAxis.drawTopYLabelEntryEnabled = false
        tvocChart.autoScaleMinMaxEnabled = true
        tvocChart.xAxis.labelPosition = .bottom
        tvocChart.xAxis.axisMinimum = 0.0
        tvocChart.leftAxis.accessibilityLabel = "tvoc ppb"
        tvocChart.rightAxis.drawLabelsEnabled = false
        
        tvocDataSet.drawFilledEnabled = true
        tvocDataSet.setColor(.blue)
        tvocDataSet.circleRadius = 1.5
        tvocDataSet.circleHoleRadius = 0.125
        
        tvocChart.borderColor = .black
        tvocChart.borderLineWidth = 1.0
        
        co2Chart.data = co2Measurement
        co2Chart.data?.setDrawValues(false)
        co2Chart.xAxis.axisLineWidth = 1.0
        co2Chart.xAxis.drawLabelsEnabled = true
        co2Chart.autoresizesSubviews = true
        co2Chart.leftAxis.drawBottomYLabelEntryEnabled = true
        co2Chart.leftAxis.drawTopYLabelEntryEnabled = false
        co2Chart.autoScaleMinMaxEnabled = true
        co2Chart.xAxis.labelPosition = .bottom
        co2Chart.leftAxis.accessibilityLabel = "CO2 ppm"
        co2Chart.xAxis.axisMinimum = 0.0
        co2Chart.rightAxis.drawLabelsEnabled = false
        
        co2DataSet.drawFilledEnabled = true
        co2DataSet.setColor(.green)
        co2DataSet.circleRadius = 1.5
        co2DataSet.circleHoleRadius = 0.125
        
        co2Chart.borderColor = .black
        co2Chart.borderLineWidth = 1.0
        
        bleManager.LineGraph_tvoc = self.tvocChart
        bleManager.tvocSensorData = self.tvocData
        bleManager.LineGraph_co2 = self.co2Chart
        bleManager.co2SensorData = self.co2Data
        
        if(bleManager.connected) {
            dataView.connectToAir()
        }
    }
    
    func clearChart() {
        tvocChart.clear()
        co2Chart.clear()
        bleManager.currentMagTime_tvoc = 0
        bleManager.currentMagTime_co2 = 0
        
        tvocData = []
        co2Data = []
        
        tvocDataSet = LineChartDataSet(entries: tvocData, label: "tvoc ppm")
        co2DataSet = LineChartDataSet(entries: co2Data, label: "co2 ppb")
        
        tvocMeasurement = LineChartData(dataSet: tvocDataSet)
        co2Measurement = LineChartData(dataSet: co2DataSet)
        tvocMeasurement.setDrawValues(false)
        co2Measurement.setDrawValues(false)
        
        tvocChart.data = tvocMeasurement
        tvocChart.data?.setDrawValues(false)
        tvocChart.xAxis.axisLineWidth = 1.0
        tvocChart.xAxis.drawLabelsEnabled = true
        tvocChart.autoresizesSubviews = true
        tvocChart.leftAxis.drawBottomYLabelEntryEnabled = true
        tvocChart.leftAxis.drawTopYLabelEntryEnabled = false
        tvocChart.autoScaleMinMaxEnabled = true
        tvocChart.xAxis.labelPosition = .bottom
        tvocChart.leftAxis.accessibilityLabel = "tvoc ppb"
        tvocChart.xAxis.axisMinimum = 0.0
        tvocChart.rightAxis.drawLabelsEnabled = false
        
        tvocDataSet.drawFilledEnabled = true
        tvocDataSet.setColor(.blue)
        tvocDataSet.circleRadius = 1.5
        tvocDataSet.circleHoleRadius = 0.125
        
        tvocChart.borderColor = .black
        tvocChart.borderLineWidth = 1.0
        
        co2Chart.data = co2Measurement
        co2Chart.data?.setDrawValues(false)
        co2Chart.xAxis.axisLineWidth = 1.0
        co2Chart.xAxis.drawLabelsEnabled = true
        co2Chart.autoresizesSubviews = true
        co2Chart.leftAxis.drawBottomYLabelEntryEnabled = true
        co2Chart.leftAxis.drawTopYLabelEntryEnabled = false
        co2Chart.autoScaleMinMaxEnabled = true
        co2Chart.xAxis.labelPosition = .bottom
        co2Chart.leftAxis.accessibilityLabel = "CO2 ppm"
        co2Chart.xAxis.axisMinimum = 0.0
        co2Chart.rightAxis.drawLabelsEnabled = false
        
        co2DataSet.drawFilledEnabled = true
        co2DataSet.setColor(.green)
        co2DataSet.circleRadius = 1.5
        co2DataSet.circleHoleRadius = 0.125
        
        co2Chart.borderColor = .black
        co2Chart.borderLineWidth = 1.0
        
        bleManager.LineGraph_tvoc = self.tvocChart
        bleManager.tvocSensorData = self.tvocData
        bleManager.LineGraph_co2 = self.co2Chart
        bleManager.co2SensorData = self.co2Data
    }
    
    @IBAction func clearGraph(_ sender: UIButton) {
        clearChart()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(!bleManager.connected) {
            let alert = UIAlertController.init(title: "Please connect to a sensor device for measurement.", message: "", preferredStyle: .alert)
            let dismissAction = UIAlertAction.init(title: "ok", style: .default, handler: {_ in
                self.dismiss(animated: true, completion: nil)
            })
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
