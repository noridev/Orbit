//
//  InstanceUtil.swift
//  Orbit
//
//  Created by NoriDev on 7/7/25.
//

import Foundation
import VRCKit

struct InstanceUtil {
    // "99999~hidden(usr_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)" -> "99999"
    static func extractInstanceNumber(from instanceId: String) -> String {
        if let tildeIndex = instanceId.firstIndex(of: "~") {
            return String(instanceId[..<tildeIndex])
        }
        return instanceId
    }
    
    static func getInstanceTypeDescription(_ instance: Instance) -> String {
        return instance.typeDescription
    }
    
    static func getUserCountString(_ instance: Instance) -> String {
        return "(\(instance.userCount)/\(instance.world.capacity))"
    }
    
    static func getWorldNameWithInstance(_ instance: Instance) -> String {
        let instanceNumber = extractInstanceNumber(from: instance.instanceId)
        return "\(instance.world.name) #\(instanceNumber)"
    }
    
    static func getInstanceTypeWithUserCount(_ instance: Instance) -> String {
        let typeDescription = getInstanceTypeDescription(instance)
        let userCount = getUserCountString(instance)
        return "\(typeDescription) \(userCount)"
    }
} 