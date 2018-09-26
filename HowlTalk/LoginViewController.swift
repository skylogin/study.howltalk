//
//  LoginViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 04/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, MessagingDelegate {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //최초에 로그아웃시켜버리고 시작
        try! Auth.auth().signOut()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            
            //아이폰X 대응용 코드
            if(UIScreen.main.nativeBounds.height == 2436){
                m.height.equalTo(40)
            } else{
                m.height.equalTo(20)
            }
            
        }

        color = remoteConfig["splash_background"].stringValue
        //statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        signupButton.backgroundColor = UIColor(hex: color)
        
        loginButton.addTarget(self, action: #selector(loginEvent), for: .touchUpInside)
        signupButton.addTarget(self, action: #selector(presentSignup), for: .touchUpInside)
        
        Auth.auth().addStateDidChangeListener{ (auth, user) in
            if(user != nil){
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as! UITabBarController
                self.present(view, animated: true, completion: nil)
                
                let uid = Auth.auth().currentUser?.uid
                
                // 푸시 토큰 받아오기
                let token = InstanceID.instanceID().token()
                Database.database().reference().child("users").child(uid!).updateChildValues(["pushToken":token!])
            
            }
        }
        // Do any additional setup after loading the view.
        
    }
    
    @objc func loginEvent(){
        if(self.email.text! == "" && self.password.text! == ""){
            self.email.text = "test@test.com"
            self.password.text = "qwerty"
        }
        
        
        Auth.auth().signIn(withEmail: self.email.text!, password: self.password.text!){ (user, error) in
            if(error != nil){
                let alert = UIAlertController(title: "에러", message: error.debugDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated:true, completion: nil)
            }
        }
    }
    
    @objc func presentSignup(){
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        
        self.present(view, animated: true, completion: nil)
        
    }
    
    
    //키보드 이벤트
    @IBAction func didEndOnEmail(_ sender: Any) {
        self.password.becomeFirstResponder()
    }
    
    @IBAction func didEndOnPassword(_ sender: Any) {
        loginEvent()
    }
    
    //다른곳 터치할때 이벤트
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
        print("####다른곳 터치해서 키보드 닫음")
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
