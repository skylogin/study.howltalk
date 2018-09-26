//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 03/09/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase

class GroupChatRoomViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var button_send: UIButton!
    @IBOutlet weak var textfield_message: UITextField!
    @IBOutlet weak var tableview: UITableView!
    
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var destinationRoom : String?
    var uid : String?
    
    var users : [String:AnyObject]?
    var comments : [ChatModel.Comment] = []
    
    var databaseRef : DatabaseReference?
    var observe : UInt?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid

        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            self.users = datasnapshot.value as! [String:AnyObject]
        })
        
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        getMessageList()
        
        // 탭바 감추기
        self.tabBarController?.tabBar.isHidden = true
        
        // Do any additional setup after loading the view.
    }
    
    // 뷰 종료될 시
    override func viewWillDisappear(_ animated: Bool) {
        // 탭바 나타나기
        self.tabBarController?.tabBar.isHidden = false 
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(self.comments[indexPath.row].uid == uid){
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            // 읽음카운터 체크
            //setReadCounter(label: view.label_read_counter, position: indexPath.row)
            
            return view
        } else{
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUser?["userName"] as! String
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string:(imageUrl))
            // 이미지를 동그랗게 만들어주는 코드
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            
            // 킹피셔를 이용해서 캐시화 하는 코드
            view.imageview_profile.kf.setImage(with: url)
            
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            // 읽음카운터 체크
            //setReadCounter(label: view.label_read_counter, position: indexPath.row)
            
            return view
        }
        
        //return UITableViewCell()
    }

    
    @objc func sendMessage(){
        let value : Dictionary<String,Any> = [
            "uid" : uid!,
            "message": textfield_message.text!,
            "timestamp": ServerValue.timestamp()
        ]
        
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value) { (err, ref) in
            self.textfield_message.text = ""
        }
    }
    
    // 키보드 나타내기
    @objc func keyboardWillShow(notification : Notification){
        if let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue{
            self.bottomConstraint.constant = keyboardSize.height
        }
        
        UIView.animate(withDuration: 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (complete) in
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1, section:0), at: UITableViewScrollPosition.bottom, animated: true)
                
            }
        })
    }
    
    // 키보드 없애기
    @objc func keyboardWillHide(notification : Notification){
        self.bottomConstraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    // 키보드 사라지기 (에디팅 이후)
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // 메시지 받아오기
    func getMessageList(){
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
        
        observe = databaseRef?.observe(DataEventType.value, with: { (datasnapshot) in
            self.comments.removeAll()
            
            var readUserDic : Dictionary<String,AnyObject> = [:]
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                // 마지막 메시지를 읽은거에 대한 변수 (추가선언, 기존거랑 별개로 데이터수정후 서버에 보고해야해서 분기)
                let comment_modify = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                
                comment_modify?.readUsers[self.uid!] = true
                readUserDic[key] = comment_modify?.toJSON() as! NSDictionary
                
                self.comments.append(comment!)
            }
            
            // 파이어베이스가 nsdictionary만 지원해서 변환한 것을 넣어줌
            let nsDic = readUserDic as NSDictionary
            
            // 채팅방을 최초에 만든경우 읽음처리를 보내서는 안된다.
            if(self.comments.last?.readUsers.keys == nil){
                return
            }
            
            // 서버에 마지막 메시지를 읽은 사람이 있을경우 데이터를 쏴주고 / 없을경우에는 그냥 표시만 해준다
            if(!(self.comments.last?.readUsers.keys.contains(self.uid!))!){
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                    self.tableview.reloadData()
                    
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1, section:0), at: UITableViewScrollPosition.bottom, animated: true)
                        
                    }
                })
            } else{
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1, section:0), at: UITableViewScrollPosition.bottom, animated: true)
                    
                }
            }
            
        })
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
