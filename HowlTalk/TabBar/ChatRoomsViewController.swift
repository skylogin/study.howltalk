//
//  ChatRoomsViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 20/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableview: UITableView!
    
    var uid : String!
    var chatrooms : [ChatModel]! = []
    var destinationUsers : [String]! = []
    
    //방에 대한 키값 저장
    var keys : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.uid = Auth.auth().currentUser?.uid
        self.getChatroomsList()
        
    }

    func getChatroomsList(){
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                if let chatroomdic = item.value as? [String:AnyObject]{
                    let chatModel = ChatModel(JSON: chatroomdic)
                    self.chatrooms.append(chatModel!)
                    
                    self.keys.append(item.key)
                }
            }
            
            self.tableview.reloadData()
        })
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        
        // 상대방정보 가져오기
        var destinationUid : String?
        for item in chatrooms[indexPath.row].users{
            if(item.key != self.uid){
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
            }
        }
        
        // DB통해서 이미지 및 대화상대이름, 마지막 메시지 가져오기
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
            
            cell.label_title.text = userModel.username
            let url = URL(string: userModel.profileImageUrl!)
            
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            /* 킹피셔를 이용한 코드로 주석처리
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.sync{
                    cell.imageview.image = UIImage(data:data!)
                    cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
                    cell.imageview.layer.masksToBounds = true
                }
            }).resume()
            */
            
            
            // 채팅방 최초생성시 읽음처리를 보내지않고 예외처리
            if(self.chatrooms[indexPath.row].comments.keys.count == 0){
                return
            }
            
            let lastMessagekey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.label_lastmessage.text = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.message
            
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.timestamp
            cell.label_timestamp.text = unixTime?.toDayTime
        })
        
        
        return cell
    }
    
    // 테이블뷰 클릭시 발생되는 이벤트
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭시 로우 깜빡임 지우기
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        if(self.chatrooms[indexPath.row].users.count > 2){
            let destinationUid = self.destinationUsers[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController

            view.destinationRoom = self.keys[indexPath.row]
            
            
            // 네비게이션 컨트롤러의 push를 이용해 옆으로 밀리도록 구현
            self.navigationController?.pushViewController(view, animated: true)
        } else{
            let destinationUid = self.destinationUsers[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            view.destinationUid = destinationUid
            
            // 네비게이션 컨트롤러의 push를 이용해 옆으로 밀리도록 구현
            self.navigationController?.pushViewController(view, animated: true)
        }
        
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

class CustomCell: UITableViewCell{
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var label_lastmessage: UILabel!
    @IBOutlet weak var label_timestamp: UILabel!
    
}
