//
//  ViewController.swift
//  Okanewokazoeru
//
//  Created by Masato Kikkawa on 2019/03/07.
//  Copyright © 2019 com.example.masato-kikkawa. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    let validYenDict = ["1000yen_face": 1000, "5000yen_face": 5000,
                        "10000yen_face": 10000,
                        "10000yen_face01": 10000,
                        "10000yen_face02": 10000,
                        "10000yen_face03": 10000,
                        ]
    
    enum AppState {
        case idle
        case run
        case pause
    }
    var appState : AppState = .idle
    
    @IBOutlet weak var counter10000yenLabel: UILabel!
    var counter10000yen = 0

    @IBOutlet weak var counter5000yenLabel: UILabel!
    var counter5000yen = 0

    @IBOutlet weak var counter1000yenLabel: UILabel!
    var counter1000yen = 0

    @IBOutlet weak var totalLabel: UILabel!
    var totalJPY = 0


    @IBOutlet weak var shiheiImage: UIImageView!
    var countingJPY = 0

    @IBOutlet weak var messageLabel: UILabel!

    let avSound = AVSound()

    @IBOutlet weak var plusButton: UIBarButtonItem!

    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }

    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
        AVSpeech.speak(text: "カメラで紙幣を写して、プラスボタンを押してください。合計が出ます。")
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        shiheiImage.isHidden = true
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
 
    }

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        if let id = referenceImage.name, self.validYenDict.keys.contains(id) {
            if self.appState == .run {
                self.appState = .pause
                countJPY(id: id)
            }
            self.session.remove(anchor: imageAnchor)
        } else {
            print("Unknown image detected.")
            print("referenceImage : \(referenceImage)")
            print("appState : \(self.appState)")
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func countJPY(id: String) {
        DispatchQueue.main.async(execute: {
            let jpy = self.validYenDict[id] as Int? ?? 0
            let imageName = String(format: "%dyen", jpy)
            print("JPY : \(String(describing: jpy))")
            self.countingJPY = jpy
            self.updateCountLabel(jpy: jpy)
            self.shiheiImage.image = UIImage(named: imageName)
            self.shiheiImage.isHidden = false
            let basePosition = self.shiheiImage.center
            self.shiheiImage.alpha = 1.0
            self.shiheiImage.center.y += 75.0
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                self.shiheiImage.alpha = 1.0
                self.shiheiImage.center.y -= 75.0
            }, completion: {(finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                    self.shiheiImage.alpha = 0.0
                    self.shiheiImage.center.y -= 75.0
                }, completion: {(finished: Bool) in
                    self.shiheiImage.center = basePosition
                })
            })
            self.avSound.soundEffectPlay(name: "cash-register", loop: 0)
            self.totalJPY += self.countingJPY
            self.totalLabel.text = String(format: "合計: %d円", self.totalJPY)
            //self.appState = .pause
            self.plusButton.isEnabled = false
            self.resetButton.isEnabled = false
            self.backToIdle()
        })
    }

    func updateCountLabel(jpy: Int) {
        if jpy == 10000 {
            counter10000yen += 1
            counter10000yenLabel.text = String(format: "x %d", counter10000yen)
        } else if jpy == 5000 {
            counter5000yen += 1
            counter5000yenLabel.text = String(format: "x %d", counter5000yen)
        } else if jpy == 1000 {
            counter1000yen += 1
            counter1000yenLabel.text = String(format: "x %d", counter1000yen)
        }
    }

    func resetAllCountLabels() {
        counter10000yen = 0
        counter10000yenLabel.text = String(format: "x %d", counter10000yen)
        counter5000yen = 0
        counter5000yenLabel.text = String(format: "x %d", counter5000yen)
        counter1000yen = 0
        counter1000yenLabel.text = String(format: "x %d", counter1000yen)
    }

    func backToIdle() {
        if self.appState == .pause {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.appState = .idle
                self.shiheiImage.isHidden = true
                self.plusButton.isEnabled = true
                self.resetButton.isEnabled = true
            })
        }
    }
    
    // plus
    @IBAction func actionPlus(_ sender: Any) {
        appState = .run
        plusButton.isEnabled = false
    }

    // reset
    @IBAction func actionReset(_ sender: Any) {
        appState = .idle
        countingJPY = 0
        resetAllCountLabels()
        shiheiImage.isHidden = true
        totalJPY = 0
        totalLabel.text = "合計: - 円"
        plusButton.isEnabled = true
        resetButton.isEnabled = true
    }

}
