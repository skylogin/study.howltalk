//
//  AccountViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 26/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UIViewController {

    @IBOutlet weak var conditionsCommentButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var label_comment: UILabel!
    
    var uid : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
        uid = Auth.auth().currentUser?.uid
        
        conditionsCommentButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        getConditionComment()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getConditionComment(){
        Database.database().reference().child("users").child(uid!).child("comment").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.label_comment.text = datasnapshot.value as! String
        })
    }
    
    @objc func showAlert(){
        let alertController = UIAlertController(title: "상태 메시지", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addTextField { (textfield) in
            textfield.placeholder = "상태메시지를 입력해주세요"
        }
        
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            if let textfield = alertController.textFields?.first{
                let dic = ["comment": textfield.text!]
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("users").child(uid!).updateChildValues(dic)
                
                //상태메시지 출력
                self.label_comment.text = textfield.text!
            }
            
        }))
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { (action) in
            
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func logout(){
        try! Auth.auth().signOut()
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.present(view, animated: true, completion: nil)
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
