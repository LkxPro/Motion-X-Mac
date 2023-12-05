//
//  ContentView.swift
//  Motion X View
//
//  Created by Qianxing Li on 9/28/23.
//

import SwiftUI
import Foundation
import Charts
import SceneKit

struct ContentView: View {
    @State private var roll: Double = 0
    @State private var pitch: Double = 0
    @State private var yaw: Double = 0
    @State private var isConnected: Bool = false
    @State private var webSocketTask: URLSessionWebSocketTask? = nil
    @State private var serverAddress: String = "ws://localhost:8080"
    @State private var motionDataArray: [MotionData] = []
    let maxCapacity = 50
    @State var scene: SCNScene? = .init(named: "Arrow_3d.scn")
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return formatter
    }()
    
    var body: some View {
        VStack {
            MySceneView(scene: $scene, pitch: pitch, yaw: yaw, roll: roll)
                .frame(height: 300)
            HStack{
                Spacer()
                ConnectionButton(isConnected: $isConnected, action: toggleConnection)
                Spacer()
                Button(" Record ") {
                    // Action
                }
                .font(.title)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(.borderless)
                Spacer()
            }
            
            HStack{
                VStack{
                    ForEach(["Roll", "Pitch", "Yaw"], id: \.self) { axis in
                        ChartView(axis: axis, dataArray: motionDataArray)
                    }
                }
                VStack{
                    ForEach(["UserAccelerationX", "UserAccelerationY", "UserAccelerationZ"], id: \.self) { axis in
                        ChartView(axis: axis, dataArray: motionDataArray)
                    }
                }
            }
        }
        .padding()
        .onAppear(perform: setupView)
        .onDisappear(perform: disconnectWebSocket)
    }
    
    func setupView() {
        rotateObject()
    }
    
    func toggleConnection() {
        isConnected.toggle()
        isConnected ? connectWebSocket() : disconnectWebSocket()
    }
    
    func connectWebSocket() {
        guard let url = URL(string: serverAddress) else {
            print("Invalid URL")
            isConnected = false
            return
        }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveData()
    }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel()
        webSocketTask = nil
        print("Motion Data Array:")
        for data in motionDataArray {
            print(data)
        }
    }
    
    func receiveData() {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let jsonString):
                    decodeAndHandle(jsonString: jsonString)
                case .data(let data):
                    if let jsonString = String(data: data, encoding: .utf8) {
                        decodeAndHandle(jsonString: jsonString)
                    } else {
                        print("Failed to convert received Data to String")
                    }
                @unknown default:
                    print("Received unknown message type")
                }
                self.receiveData()
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
                self.isConnected = false
            }
        }
    }
    
    func decodeAndHandle(jsonString: String) {
        if let data = jsonString.data(using: .utf8) {
            do {
                let motionData = try JSONDecoder().decode(MotionData.self, from: data)
                DispatchQueue.main.async {
                    self.roll = motionData.roll
                    self.pitch = motionData.pitch
                    self.yaw = motionData.yaw
                    self.motionDataArray.append(motionData)
                    if self.motionDataArray.count > maxCapacity {
                        self.motionDataArray.removeFirst()
                    }
                    rotateObject()
                }
            } catch {
                print("JSON decoding error: \(error)")
            }
        }
    }
    
    func rotateObject() {
        let rootNode = scene?.rootNode.childNode(withName: "Root", recursively: true)
        rootNode?.eulerAngles = SCNVector3(roll, pitch, -yaw)
    }
}

struct ChartView: View {
    var axis: String
    var dataArray: [MotionData]
    
    var body: some View {
        Chart(dataArray) {
            LineMark(
                x: .value("Timestamp", $0.date ?? Date()),
                y: .value(axis, axisValue(for: axis, from: $0))
            )
        }
        .frame(height: 100)
        .padding(.bottom, 20)
        Text("\(axis): \(formattedValue(for: axis))")
    }
    
    func axisValue(for axis: String, from data: MotionData) -> Double {
        switch axis {
        case "Roll": return data.roll
        case "Pitch": return data.pitch
        case "Yaw": return data.yaw
        case "UserAccelerationX": return data.userAccelerationX
        case "UserAccelerationY": return data.userAccelerationY
        case "UserAccelerationZ": return data.userAccelerationZ
        default: return 0
        }
    }
    
    
    func formattedValue(for axis: String) -> String {
        let value = axisValue(for: axis, from: dataArray.last ?? MotionData(roll: 0, pitch: 0, yaw: 0, userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0, timestamp: ""))
        if ["Roll", "Pitch", "Yaw"].contains(axis) {
            return String(format: "%.2f°", value * 180 / Double.pi)
        } else {
            return String(format: "%.3fm/s²", value)
        }
    }
    
}

struct ConnectionButton: View {
    @Binding var isConnected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(isConnected ? "Disconnect" : "Connect")
        }
        .font(.title)
        .padding()
        .background(isConnected ? Color.green : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .buttonStyle(.borderless)
    }
}

struct MotionData: Codable, Identifiable {
    var id: UUID?  // Make it optional
    var roll: Double
    var pitch: Double
    var yaw: Double
    var userAccelerationX: Double
    var userAccelerationY: Double
    var userAccelerationZ: Double
    var timestamp: String
    var date: Date? {
        ContentView.dateFormatter.date(from: timestamp)
    }
    
    init(roll: Double, pitch: Double, yaw: Double, userAccelerationX: Double, userAccelerationY: Double, userAccelerationZ: Double, timestamp: String) {
        self.id = UUID()  // Generate a new UUID
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
        self.userAccelerationX = userAccelerationX
        self.userAccelerationY = userAccelerationY
        self.userAccelerationZ = userAccelerationZ
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()  // Generate a new UUID
        self.roll = try container.decode(Double.self, forKey: .roll)
        self.pitch = try container.decode(Double.self, forKey: .pitch)
        self.yaw = try container.decode(Double.self, forKey: .yaw)
        
        self.userAccelerationX = try container.decode(Double.self, forKey: .userAccelerationX)
        self.userAccelerationY = try container.decode(Double.self, forKey: .userAccelerationY)
        self.userAccelerationZ = try container.decode(Double.self, forKey: .userAccelerationZ)
        
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
    }
}


struct MySceneView: NSViewRepresentable {
    @Binding var scene: SCNScene?
    var pitch: Double
    var yaw: Double
    var roll: Double
    
    func makeNSView(context: NSViewRepresentableContext<MySceneView>) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.scene = scene
        view.backgroundColor = .clear
        return view
    }
    
    func updateNSView(_ nsView: SCNView, context: NSViewRepresentableContext<MySceneView>) {
        let rootNode = scene?.rootNode.childNode(withName: "Root", recursively: true)
        rootNode?.eulerAngles = SCNVector3(roll, pitch, -yaw)
    }
}

#Preview {
    ContentView()
}

