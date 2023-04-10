//
//  PassKeyView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import UIKit

class PassKeyView: UIViewController {
    
    @IBOutlet weak var rippleView: UIImageView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var OnOffButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    
    var authentication: Bool!
    
    
    var topText = [true: [true: "Say your Key Phrase", false: "Press the play button"], false: [true: "Say up to 10 key words. This will serve as an extra layer of authentication. Make sure to remember it!", false: "Press the play button"]]
    
    var isOn: Bool = false {
        didSet {
            topLabel.text = topText[authentication]![isOn]
            if isOn {
                OnOffButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
                speechModule.startRecording()
            } else {
                OnOffButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                speechModule.stop = true
                speechModule.stopRecording()
                if bottomLabel.text!.isEmpty { return }
                if speechModule.behavior == .authenticate {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "passPhraseToMessages", sender: self)
                    }
                } else {
                    let keyPhraseString = bottomLabel.text!
                    alert(title: "Your key phrase will be as follows:", message: keyPhraseString, actions: [ ("Decline", (UIAlertAction.Style.destructive, {
                        self.bottomLabel.text = ""
                        self.isOn = false
                    })), ("Accept", (UIAlertAction.Style.default, {
                        UserDefaults.standard.set(keyPhraseString, forKey: "keyPhrase")
                        UserDefaults.standard.set(true, forKey: "keyPhraseActive")
                        self.navigationController?.popViewController(animated: true)
                    }))])
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        speechModule.stop = true
        speechModule.stopRecording()
    }
    
    var targetText: String!
    
    var speechModule: SpeechModule!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rippleView.clipsToBounds = false
        bottomLabel.text = ""
        topLabel.text = topText[authentication]![isOn]
        if authentication {
            title = "Say your Key Phrase"
            infoButton.isHidden = true
            bottomLabel.isHidden = true
            speechModule = SpeechModule(behavior: .authenticate, controller: self)
            isOn = true
        } else {
            title = "Choose your Key Phrase"
            speechModule = SpeechModule(behavior: .chooseKeyPhrase, controller: self)
            isOn = false
        }
        
        targetText = UserDefaults.standard.string(forKey: "keyPhrase") ?? ""
    }
    
    @IBAction func onOffPressed(_ sender: Any) {
        isOn.toggle()
    }
   
    @IBAction func infoTapped(_ sender: Any) {
        alert(title: "Information", message: "The purpose of setting a key phrase is to add an additional layer of security to your login process. When you login, you will be prompted for your password, then biometrics (if applicable), then the key phrase (if applicable).", actionTitle: "Okay")
    }
    
    
}


extension UIView {
    func ripple() {
        let shapePosition = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        ripple(view: self, position: shapePosition)
    }
    
    func ripple(view:UIView, position: CGPoint) {
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        
        let rippleShape = CAShapeLayer()
        rippleShape.bounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        rippleShape.path = path.cgPath
        rippleShape.lineWidth = 2
        rippleShape.fillColor = UIColor.clear.cgColor
        rippleShape.strokeColor = UIColor.label.cgColor
        rippleShape.opacity = 0
        rippleShape.position = position
        
        view.layer.addSublayer(rippleShape)
        
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        scaleAnim.toValue = NSValue(caTransform3D: CATransform3DMakeScale(2, 2, 1))
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 1
        opacityAnim.toValue = nil
        
        let animation = CAAnimationGroup()
        animation.animations = [scaleAnim, opacityAnim]
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.duration = CFTimeInterval(0.7)
        animation.isRemovedOnCompletion = true
        
        rippleShape.add(animation, forKey: "rippleEffect")
    }
}
