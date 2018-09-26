//
//  UserModel.swift
//  HowlTalk
//
//  Created by Awesome S on 06/08/2018.
//  Copyright © 2018 Awesome S. All rights reserved.
//

import UIKit

@objcMembers
class UserModel: NSObject {
    var profileImageUrl : String?
    var username : String?
    var uid : String?
    
    var pushToken : String?
    var comment : String?
}
