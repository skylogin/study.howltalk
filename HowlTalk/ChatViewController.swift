//
//  ChatViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 11/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import Kingfisher

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    //나중에 채팅할 대상의 UID
    public var destinationUid : String?
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textfield_message: UITextField!
    @IBOutlet weak var tableview: UITableView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    
    var uid : String?
    var chatRoomUid : String?
    
    var comments : [ChatModel.Comment] = []
    var destinationUserModel : UserModel?
    
    var displayName : String?
    
    var databaseRef : DatabaseReference?
    var observe : UInt?
    var peopleCount : Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
        
        // 유저이름 받아서 프로필이름으로 재설정
        Database.database().reference().child("users").child(uid!).child("username").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.displayName = datasnapshot.value as! String
        })
        
        // 탭바 감추기
        self.tabBarController?.tabBar.isHidden = true
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // 시작시 observe 등록
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    
    
    // 컨트롤러 종료시
    override func viewWillDisappear(_ animated: Bool) {
        //노티피케이션 옵져버 삭제
        NotificationCenter.default.removeObserver(self)
        
        //탭바 나타내기
        self.tabBarController?.tabBar.isHidden = false
        
        //메시지 옵저버 삭제
        databaseRef?.removeObserver(withHandle: observe!)
        
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

    
    @objc func createRoom(){
        let createRoomInfo : Dictionary<String,Any> = [
            "users" : [
                uid!: true,
                destinationUid!: true
            ]
            
        ]
        
        if(chatRoomUid == nil){
            self.sendButton.isEnabled = false
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: { (err, ref) in
                if(err == nil){
                    self.checkChatRoom()
                }
            })
        } else{
            if(self.textfield_message.text! != ""){
                let value : Dictionary<String,Any> = [
                    "uid" : uid!,
                    "message" : self.textfield_message.text!,
                    "timestamp" : ServerValue.timestamp()
                ]
                
                Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: { (err, ref) in
                    
                    //푸시 전송
                    self.sendGcm()
                    
                    //메시지창 초기화
                    self.textfield_message.text = ""
                })
            }
        }
        
        
        
        
        
    }

    func checkChatRoom(){
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot)  in
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                if let chatRoomDic = item.value as? [String:AnyObject]{
                    let chatModel = ChatModel(JSON: chatRoomDic)
                    if(chatModel?.users[self.destinationUid!] == true && chatModel?.users.count == 2){
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                        self.getDestinationInfo()
                    }
                }
               
            }
        })
    }
    
    // 대화상대 정보 가져오기
    func getDestinationInfo(){
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.destinationUserModel = UserModel()
            self.destinationUserModel?.setValuesForKeys(datasnapshot.value as! [String:Any])
            self.getMessageList()
            
        })
    }
    
    // 메시지 받아오기
    func getMessageList(){
        databaseRef = Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments")
            
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
    
    // 읽음처리 연산해서 라벨표시
    func setReadCounter(label: UILabel?, position: Int?){
        let readCount = self.comments[position!].readUsers.count
        
        if(peopleCount == nil){
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
                let dic = datasnapshot.value as! [String:Any]
                self.peopleCount = dic.count
                let noReadCount = self.peopleCount! - readCount
                
                if(noReadCount > 0 ){
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                } else{
                    label?.isHidden = true
                }
            })
        } else{
            let noReadCount = self.peopleCount! - readCount
            
            if(noReadCount > 0 ){
                label?.isHidden = false
                label?.text = String(noReadCount)
            } else{
                label?.isHidden = true
            }
        }
        
    }
    
    
    
    
    
    // 푸시메시지 전송
    func sendGcm(){
        let url = "https://gcm-http.googleapis.com/gcm/send"
        let header : HTTPHeaders = [
            "Content-Type" :"application/json",
            "Authorization" : "key=AIzaSyBlm44seAnRTsaKeBQoY-u6x6VFWtJB1n0",
        ]
        
        //let userName = Auth.auth().currentUser?.displayName
        let userName = self.displayName;
        
        var notificationModel = NotificationModel()
        notificationModel.to = destinationUserModel?.pushToken
        notificationModel.notification.title = userName
        notificationModel.notification.text = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.text = textfield_message.text
        
        let params = notificationModel.toJSON()
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            //print(response.result.value)
            
        }
    }
    
    
    
    // 메시지 가져온 테이블뷰의 카운트
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    // 메시지 가져온 테이블뷰의 내용
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(self.comments[indexPath.row].uid == uid){
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            // 읽음카운터 체크
            setReadCounter(label: view.label_read_counter, position: indexPath.row)
            
            return view
        } else{
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUserModel?.username
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            let url = URL(string:(self.destinationUserModel?.profileImageUrl)!)
            // 이미지를 동그랗게 만들어주는 코드
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            
            // 킹피셔를 이용해서 캐시화 하는 코드
            view.imageview_profile.kf.setImage(with: url)
            
            /* 킹피셔로 인해 url-session코드는 삭제해도 무방
            URLSession.shared.dataTask(wit방: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.async {
                    view.imageview_profile.image = UIImage(data: data!)
                    
                    
                }
            }).resume()
            */
            
            // 읽음카운터 체크
            setReadCounter(label: view.label_read_counter, position: indexPath.row)
            
            return view
        }
        
        //return UITableViewCell()
    }
    
    // 높이를 유연하게 조절
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // 클릭이벤트
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭시 로우 깜빡임 지우기
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    //메시지창에서 엔터누를때 키보드 이벤트
    @IBAction func didEndOnMessage(_ sender: Any) {
        self.createRoom()
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


extension Int{
    var toDayTime : String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        let date = Date(timeIntervalSince1970: Double(self)/1000)
        
        return dateFormatter.string(from: date)
    }
}

class MyMessageCell : UITableViewCell{
    
    @IBOutlet weak var label_message: UILabel!
    @IBOutlet weak var label_timestamp: UILabel!
    
    @IBOutlet weak var label_read_counter: UILabel!
    

}

class DestinationMessageCell : UITableViewCell{

    @IBOutlet weak var label_message: UILabel!
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var imageview_profile: UIImageView!
    @IBOutlet weak var label_timestamp: UILabel!
    
    @IBOutlet weak var label_read_counter: UILabel!
    
    
}
