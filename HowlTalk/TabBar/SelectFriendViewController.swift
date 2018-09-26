//
//  SelectFriendViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 03/09/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase
import BEMCheckBox


class SelectFriendViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,BEMCheckBoxDelegate {
    
   
    
    @IBOutlet weak var tableview: UITableView!
    
    @IBOutlet weak var button: UIButton!
    
    var array: [UserModel] = []
    var users = Dictionary<String,Bool>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //DB접속
        Database.database().reference().child("users").observe(DataEventType.value, with: { (snapshot) in
            self.array.removeAll()
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children{
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                
                userModel.setValuesForKeys(fchild.value as! [String : Any])
                
                if(userModel.uid == myUid){
                    continue
                }
                
                self.array.append(userModel)
            }
            
            DispatchQueue.main.async {
                self.tableview.reloadData()
            }
        })
        
        
        button.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var view = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        
        view.labelName.text = array[indexPath.row].username
        view.imageviewProfile.kf.setImage(with: URL(string:array[indexPath.row].profileImageUrl!))
        view.checkbox.delegate = self
        view.checkbox.tag = indexPath.row
        
        return view
    }
    
    //셀을 선택할 경우
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭시 로우 깜빡임 지우기
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

    //체크박스 클릭시 이벤트
    func didTap(_ checkBox: BEMCheckBox) {
        if(checkBox.on){
            //체크된경우 이벤트
            users[self.array[checkBox.tag].uid!] = true
            
        } else{
            //아닌경우 이벤트
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
        }
    }
    
    // 대화방만들기
    @objc func createRoom(){
        var myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        
        let nsDic = users as! NSDictionary
        Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic)
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

class SelectFriendCell : UITableViewCell{
    
    @IBOutlet weak var checkbox: BEMCheckBox!
    @IBOutlet weak var imageviewProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    
}
