//
//  SignupViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 04/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(20)
        }
        
        color = remoteConfig["splash_background"].stringValue
        //statusBar.backgroundColor = UIColor(hex: color)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        
        signupButton.backgroundColor = UIColor(hex: color)
        cancelButton.backgroundColor = UIColor(hex: color)
        
        
        
        signupButton.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc func imagePicker(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func signupEvent(){
        if(self.email.text! == "" && self.password.text! == ""){
            self.email.text = "test@test.com"
            self.password.text = "qwerty"
            self.name.text = "test"
        }
        
        Auth.auth().createUser(withEmail: self.email.text!, password: self.password.text!) { (user, error) in
            let uid = user?.user.uid
            //let uid = Auth.auth().currentUser?.uid
            let image = UIImageJPEGRepresentation(self.imageView.image!, 0.1)!
            
            
            let imageStorageRef = Storage.storage().reference().child("userImages").child(uid!)
            //Storage.storage().reference().child("userImages").child(uid!).putData(image, metadata: nil, completion: { (data, error) in
            imageStorageRef.putData(image, metadata: nil, completion: { (data, error) in
                //let imageUrl = data?.downloadURL()?.absoluteString
                
                //이미지 url가져오는 법이 변경됨
                imageStorageRef.downloadURL { (url, error) in
                    let values = ["username": self.name.text!, "profileImageUrl": url?.absoluteString, "uid": Auth.auth().currentUser?.uid]
                    Database.database().reference().child("users").child(uid!).setValue(values, withCompletionBlock: { (err, ref) in
                        if(err == nil){
                            self.cancelEvent()
                        }
                    })
                    
                }
                
            })
            
            /* 이동하는거 주석
            if(user != nil){
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as! UITabBarController
                self.present(view, animated: true, completion: nil)
            }
            */
        }
        
    }
    
    @objc func cancelEvent(){
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //키보드 이벤트
    @IBAction func didEndOnEmail(_ sender: Any) {
        self.name.becomeFirstResponder()
    }
    @IBAction func didEndOnName(_ sender: Any) {
        self.password.becomeFirstResponder()
    }
    @IBAction func didEndOnPassword(_ sender: Any) {
        signupEvent()
    }
    
    
    //다른곳 터치할때 이벤트
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
        print("####다른곳 터치해서 키보드 닫음")
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
