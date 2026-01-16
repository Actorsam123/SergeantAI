//
//  RepCounting2.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/28/25.
//
import SwiftUI
import YOLO
import Foundation
import AVFoundation
import Combine


// MARK: - View
struct RepCountingView: View {
    @EnvironmentObject var pm: PunishmentManager
    @Environment(\.dismiss) private var dismiss
    
    @State var count: Int = 0
    @State var postureFeedback: String = "No Person Detected"
    @State var isGoodPosture: Bool = false
    @State var coreAngle: Double = .nan
    
    let counter: RepCounter
    let punishment_id: UUID
    
    var body: some View {
        ZStack {
            YOLOCamera(
                modelPathOrName: "yolo11l-pose",
                task: .pose,
                cameraPosition: .front,
                onDetection: { result in
                    counter.update(result: result)
                    DispatchQueue.main.async {
                        count = counter.count
                        postureFeedback = counter.postureFeedback
                        coreAngle = counter.coreAngleDegrees
                        isGoodPosture = counter.isGoodPosture
                        if count >= counter.target_count {
                            pm.deletePunishment(id: punishment_id)
                            dismiss()
                        }
                    }
                }
            )
            .ignoresSafeArea()
            
            
            Text("\(count)/\(counter.target_count)")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(Color.white)
            
            Color(isGoodPosture ? .green : Color(red: 1.0, green: 0.35, blue: 0.35))
                .opacity(isGoodPosture ? 0.25 : 0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onDisappear {
            counter.stopRepLossTimer()
        }


    }
}




// MARK: - Logic

// For debug

func speak(_ text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate

    let synthesizer = AVSpeechSynthesizer()
    synthesizer.speak(utterance)
}


func beep() {
    AudioServicesPlaySystemSound(SystemSoundID(1000))
}

func click() {
    AudioServicesPlaySystemSound(SystemSoundID(1100))
}

/// Returns the Euclidean distance between two 2D points represented as (x, y).
@inline(__always)
func distance(_ p1: (Double, Double), _ p2: (Double, Double)) -> Double {
    let dx = p1.0 - p2.0
    let dy = p1.1 - p2.1
    return (dx * dx + dy * dy).squareRoot()
}


public enum YOLOKeypoint: Int, CaseIterable, CustomStringConvertible {
    case nose = 0

    case leftEye
    case rightEye
    case leftEar
    case rightEar

    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist

    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle

    public var description: String {
        switch self {
        case .nose: return "Nose"
        case .leftEye: return "Left Eye"
        case .rightEye: return "Right Eye"
        case .leftEar: return "Left Ear"
        case .rightEar: return "Right Ear"
        case .leftShoulder: return "Left Shoulder"
        case .rightShoulder: return "Right Shoulder"
        case .leftElbow: return "Left Elbow"
        case .rightElbow: return "Right Elbow"
        case .leftWrist: return "Left Wrist"
        case .rightWrist: return "Right Wrist"
        case .leftHip: return "Left Hip"
        case .rightHip: return "Right Hip"
        case .leftKnee: return "Left Knee"
        case .rightKnee: return "Right Knee"
        case .leftAnkle: return "Left Ankle"
        case .rightAnkle: return "Right Ankle"
        }
    }
}


public protocol RepCounter {
    var repLossTask: Task<Void, Never>? { get set }
    var count: Int { get }
    var target_count: Int { get }
    var isGoodPosture: Bool { get }
    var postureFeedback: String { get }
    var coreAngleDegrees: Double { get }
    func startRepLossTimer()
    func stopRepLossTimer()
    func update(result: YOLOResult)
    func reset()
}


public final class PushupCounter: RepCounter {
    public var repLossTask: Task<Void, Never>? = nil
    public var count: Int = 0
    public var target_count: Int
    public var isGoodPosture: Bool = false
    public var previousIsGoodPosture: Bool = false
    public var postureFeedback: String = "No Person Detected"
    public var coreAngleDegrees: Double = .nan
    
    var isUp: Bool = true
    var isDown: Bool = false
    var wentDown: Bool = false
    var wentUp: Bool = false
    
    var badFrameCounter: Int = 0
    var goodFrameCounter: Int = 0
    var numberOfFramesToTrigger: Int = 3
    
    public init(target_count: Int) {
        self.target_count = target_count
    }
    
    func loseReps() {
        if count != 0 { haptic() }
        count = max(0, count - 1)
    }
    
    public func startRepLossTimer() {
        guard repLossTask == nil else { return }

        repLossTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                await MainActor.run {
                    loseReps()
                }
            }
        }
    }
    
    public func stopRepLossTimer() {
        repLossTask?.cancel()
        repLossTask = nil
    }
    
    public func update(result: YOLOResult) {
        
        // If no person is detected, exit early
        guard result.boxes.count > 0, let first = result.keypointsList.first else {
            postureFeedback = "No Person Detected"
            return
        }
        
        // Filter keypoints by confidence while preserving indices (non-confident -> nil)
        let rawKpArray = first.xyn
        let conf: [Float] = first.conf
        let kpArray: [Any?] = rawKpArray.enumerated().map { index, value in
            guard index < conf.count, conf[index] > 0.6 else { return nil }
            return value
        }
        
        func point(at index: Int) -> (x: Double, y: Double)? {
            guard index >= 0 && index < kpArray.count, let vAny = kpArray[index] else { return nil }
            if let p = vAny as? (x: Double, y: Double) { return (p.x, p.y) }
            if let p = vAny as? (Double, Double) { return (p.0, p.1) }
            if let p = vAny as? (x: Float, y: Float) { return (Double(p.x), Double(p.y)) }
            if let p = vAny as? (Float, Float) { return (Double(p.0), Double(p.1)) }
            return nil
        }
        
        func angleDegrees(a: (x: Double, y: Double), b: (x: Double, y: Double), c: (x: Double, y: Double)) -> Double {
            // vectors BA and BC
            let bax = a.x - b.x
            let bay = a.y - b.y
            let bcx = c.x - b.x
            let bcy = c.y - b.y
            let dot = bax * bcx + bay * bcy
            let magBA = sqrt(bax * bax + bay * bay)
            let magBC = sqrt(bcx * bcx + bcy * bcy)
            guard magBA > 0, magBC > 0 else { return 180 }
            var cosTheta = dot / (magBA * magBC)
            // Clamp to valid range to avoid NaNs from numerical issues
            cosTheta = max(-1, min(1, cosTheta))
            return acos(cosTheta) * 180.0 / .pi
        }
        
        
        // Keypoints we need for elbow angle (prefer left, fallback to right)
        let ls = point(at: YOLOKeypoint.leftShoulder.rawValue)
        let rs = point(at: YOLOKeypoint.rightShoulder.rawValue)
        let le = point(at: YOLOKeypoint.leftElbow.rawValue)
        let re = point(at: YOLOKeypoint.rightElbow.rawValue)
        let lw = point(at: YOLOKeypoint.leftWrist.rawValue)
        let rw = point(at: YOLOKeypoint.rightWrist.rawValue)
        let lh = point(at: YOLOKeypoint.leftHip.rawValue)
        let rh = point(at: YOLOKeypoint.rightHip.rawValue)
        let rk = point(at: YOLOKeypoint.rightKnee.rawValue)
        let lk = point(at: YOLOKeypoint.leftKnee.rawValue)
        let ra = point(at: YOLOKeypoint.rightAnkle.rawValue)
        let la = point(at: YOLOKeypoint.leftAnkle.rawValue)
        
        func sidePoints(
            shoulderL: (Double, Double)?,
            elbowL: (Double, Double)?,
            wristL: (Double, Double)?,
            hipL: (Double, Double)?,
            kneeL: (Double, Double)?,
            ankleL: (Double, Double)?,
            shoulderR: (Double, Double)?,
            elbowR: (Double, Double)?,
            wristR: (Double, Double)?,
            hipR: (Double, Double)?,
            kneeR: (Double, Double)?,
            ankleR: (Double, Double)?
        ) -> (s: (Double,Double), e: (Double,Double), w: (Double,Double), h: (Double,Double), k: (Double,Double), a: (Double,Double))? {

            if let s = shoulderL, let e = elbowL, let w = wristL, let h = hipL, let k = kneeL, let a = ankleL {
                return (s,e,w,h,k,a)
            }
            if let s = shoulderR, let e = elbowR, let w = wristR, let h = hipR, let k = kneeR, let a = ankleR {
                return (s,e,w,h,k,a)
            }
            return nil
        }
        
        guard let side = sidePoints(
            shoulderL: ls, elbowL: le, wristL: lw,
            hipL: lh, kneeL: lk, ankleL: la,
            shoulderR: rs, elbowR: re, wristR: rw,
            hipR: rh, kneeR: rk, ankleR: ra
        ) else {
            postureFeedback = "Move fully into frame"
            return
        }
        
        let torsoLength = distance(side.h, side.s)
        let bodyAngle = angleDegrees(a: side.s, b: side.h, c: side.a)
        let coreIsStraight = bodyAngle > 155 && bodyAngle < 205
        let shoulderAndHipsTooFarApart = abs(side.s.1 - side.h.1) > torsoLength * 0.8

        if !coreIsStraight && !isDown || shoulderAndHipsTooFarApart {
            badFrameCounter += 1
            
            if badFrameCounter >= 3 {
                startRepLossTimer()
                isGoodPosture = false
                postureFeedback = "Bad Position"
            }
            
            return
        }
        
        stopRepLossTimer()
        isGoodPosture = true
        postureFeedback = "Good position"
        
        let elbowAngle = angleDegrees(a: side.w, b: side.e, c: side.s)

        let DOWN_ANGLE = 95.0
        let UP_ANGLE   = 135.0

        if elbowAngle <= DOWN_ANGLE && !isDown {
            isDown = true
            postureFeedback = "Down"
            return
        }

        if elbowAngle >= UP_ANGLE && isDown {
            count += 1
            beep()
            isDown = false
            postureFeedback = "Up"
        }

    }
    
    public func reset() {
        
    }
    
    deinit {
        repLossTask?.cancel()
        repLossTask = nil
    }
}

