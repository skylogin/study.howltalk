//
//  NotificationModel.swift
//  HowlTalk
//
//  Created by Awesome S on 25/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import ObjectMapper

class NotificationModel: Mappable {
    public var to : String?
    public var notification : Notification = Notification()
    public var data : Data = Data()
    
    init(){
    }
    required init?(map : Map) {
    }
    
    func mapping(map : Map){
        to <- map["to"]
        notification <- map["notification"]
        data <- map["data"]
    }
    
    class Notification : Mappable{
        public var title : String?
        public var text : String?
        
        init(){}
        required init?(map : Map) {}
        func mapping(map : Map){
            title <- map["title"]
            text <- map["text"]
        }
    }
    
    // 안드로이드 포그라운드 노티피케이션을 위한 클래스
    class Data : Mappable{
        public var title : String?
        public var text : String?
        
        init(){}
        required init?(map : Map) {}
        func mapping(map : Map){
            title <- map["title"]
            text <- map["text"]
        }
    }
}
