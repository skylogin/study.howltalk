//
//  ViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 04/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase
import SnapKit


class ViewController: UIViewController {

    var box = UIImageView()
    var remoteConfig : RemoteConfig!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.configSettings = RemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        
        remoteConfig.fetch(withExpirationDuration: TimeInterval(0)) { (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
            self.displayWelcome()
        }
        
        
        
        self.view.addSubview(box)
        box.snp.makeConstraints{ (make) in
            make.center.equalTo(self.view)
        }
        box.image = #imageLiteral(resourceName: "loading_icon")
        //self.view.backgroundColor = UIColor(hex: "#000000")
    }
    
    
    func displayWelcome(){
        let color = remoteConfig["splash_background"].stringValue
        let caps = remoteConfig["splash_message_caps"].boolValue
        let message = remoteConfig["splash_message"].stringValue
        
        print("innnnnn")
        print(caps)
        print(color!)
        print(message!)
        
        if(caps){
            let alert = UIAlertController(title: "공지사항", message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: { (action) in
                exit(0)
            }))
            
            self.present(alert, animated: true, completion: nil)
            print("innnn2")
        } else{
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            self.present(loginVC, animated: false, completion: nil)
        }
        
        self.view.backgroundColor = UIColor(hex: color!)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
