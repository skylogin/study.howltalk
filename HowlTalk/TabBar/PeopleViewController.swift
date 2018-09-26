//
//  PeopleViewController.swift
//  HowlTalk
//
//  Created by Awesome S on 05/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit
import SnapKit
import Firebase
import Kingfisher

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var array: [UserModel] = []
    var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //테이블뷰 만들기
        tableview = UITableView()
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(PeopleViewTableCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableview)
        tableview.snp.makeConstraints{ (m) in
            m.top.equalTo(view)
            m.bottom.left.right.equalTo(view)
        }
        
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
        
        // 친구선택 버튼 만들기
        var selectFriendButton = Button()
        view.addSubview(selectFriendButton)
        selectFriendButton.snp.makeConstraints { (m) in
            m.bottom.equalTo(view).offset(-90)
            m.right.equalTo(view).offset(-20)
            m.width.height.equalTo(50)
        }
        
        selectFriendButton.setBackgroundImage(UIImage(named: "baseline_add_circle_outline_black.png"), for: UIControlState.normal)
        selectFriendButton.layer.cornerRadius = 25
        selectFriendButton.layer.masksToBounds = true
        selectFriendButton.backgroundColor = UIColor.white
        selectFriendButton.addTarget(self, action: #selector(showSelectFriendController), for: .touchUpInside)
        
        
        
        // Do any additional setup after loading the view.
    }
    
    @objc func showSelectFriendController(){
        self.performSegue(withIdentifier: "SelectFriendSegue", sender: nil)
    }
    
    
    //갯수 설정
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    //셀 설정
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PeopleViewTableCell
        
        // 이미지 설정
        let imageview = cell.imageview!
        
        imageview.snp.makeConstraints{ (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(cell).offset(10)
            m.height.width.equalTo(30)
        }
        
        let url = URL(string: array[indexPath.row].profileImageUrl!)
        imageview.layer.cornerRadius = 35 / 2   //그려지기 전에 연산되기때문에 상수값으로 고정
        imageview.clipsToBounds = true
        imageview.kf.setImage(with: url)
        
        /* 킹피셔 이용을 위해 주석처리
        URLSession.shared.dataTask(with: URL(string: array[indexPath.row].profileImageUrl!)!){ (data, response, err) in
            DispatchQueue.main.async {
                imageview.image = UIImage(data: data!)
                imageview.layer.cornerRadius = imageview.frame.size.width / 2
                imageview.clipsToBounds = true
            }
        }.resume()
        */
        
        // 이름 설정
        let label = cell.label!
        label.snp.makeConstraints{ (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(imageview.snp.right).offset(10)
        }
        
        label.text = array[indexPath.row].username
        
        // 상태메시지 설정
        let label_comment = cell.label_comment!
        label_comment.snp.makeConstraints { (m) in
            m.right.equalTo(cell).offset(-10)
            m.centerY.equalTo(cell)
            m.width.lessThanOrEqualTo(200)
            m.height.lessThanOrEqualTo(25)
        }
        
        if let comment = array[indexPath.row].comment{
            label_comment.text = comment
            
            // // 라벨 폰트사이즈
            label_comment.font = UIFont.systemFont(ofSize: 12.0)
            // // 라벨 배경처리
            label_comment.layer.cornerRadius = 2.0
            label_comment.clipsToBounds = true
            label_comment.backgroundColor = UIColor(red:0.94, green:0.96, blue:1.00, alpha:1.0)
            // // 라벨 텍스트 얼라인
            label_comment.textAlignment = .right
        }
        
        // 상태메시지 배경 - 주석처리 (내가 별도로 구현해버림)
        /*
        cell.uiview_comment_background.snp.makeConstraints { (m) in
            m.right.equalTo(cell).offset(-10)
            m.centerY.equalTo(cell)
            if let count = label_comment.text?.count{
                m.width.equalTo(count * 10)
            } else{
                m.width.equalTo(0)
            }
            m.height.equalTo(30)
        }
        
        cell.uiview_comment_background.backgroundColor = UIColor.gray
        */
        
        
        return cell
    }

    //테이블의 높이주기
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    //셀을 선택할 경우
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭시 로우 깜빡임 지우기
        tableView.deselectRow(at: indexPath, animated: true)
        
        //채팅방 이동
        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        view?.destinationUid = self.array[indexPath.row].uid
        
        self.navigationController?.pushViewController(view!, animated: true)
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



class PeopleViewTableCell : UITableViewCell{
    var imageview : UIImageView! = UIImageView()
    var label : UILabel! = UILabel()
    var label_comment : UILabel! = UILabelPadding()
    
    // 백그라운드는 주석처리 (내가 별도로 구현해버림)
    //var uiview_comment_background : UIView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageview)
        self.addSubview(label)
        //self.addSubview(uiview_comment_background)
        self.addSubview(label_comment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


// 패딩넣은 UILabel
class UILabelPadding: UILabel {
    let padding = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, padding))
    }
    
    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + padding.left + padding.right
        let heigth = superContentSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
    
    
    
}
