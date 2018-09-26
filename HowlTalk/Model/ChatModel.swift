//
//  ChatModel.swift
//  HowlTalk
//
//  Created by Awesome S on 11/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import ObjectMapper

@objcMembers
class ChatModel: Mappable {

    //채팅방에 참여한 사람들
    public var users : Dictionary<String,Bool> = [:]
    //채팅방의 대화내용
    public var comments : Dictionary<String,Comment> = [:]
    
    
    required init?(map: Map) {
        
    }
    func mapping(map : Map){
        users <- map["users"]
        comments <- map["comments"]
    }
    
    public class Comment : Mappable{
        public var uid : String?
        public var message : String?
        public var timestamp : Int?
        public var readUsers : Dictionary<String,Bool> = [:]
        
        
        public required init?(map : Map){
            
        }
        public func mapping(map : Map){
            uid <- map["uid"]
            message <- map["message"]
            timestamp <- map["timestamp"]
            readUsers <- map["readUsers"]
        }
    }

}
