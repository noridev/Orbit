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
        guard let world = instance.world else {
            return "(\(instance.userCount)/\(instance.capacity))"
        }
        return "(\(instance.userCount)/\(world.capacity))"
    }
    
    static func getWorldNameWithInstance(_ instance: Instance) -> String {
        let instanceNumber = extractInstanceNumber(from: instance.instanceId)
        guard let world = instance.world else {
            return "Unknown World #\(instanceNumber)"
        }
        return "\(world.name) #\(instanceNumber)"
    }
    
    static func getInstanceWithUserCount(_ instance: Instance) -> String {
        let instanceNumber = extractInstanceNumber(from: instance.instanceId)
        let userCount = getUserCountString(instance)
        return "#\(instanceNumber) - \(userCount)"
    }
    
    static func getInstanceWithInstanceType(_ instance: Instance) -> String {
        let instanceNumber = extractInstanceNumber(from: instance.instanceId)
        let typeDescription = getInstanceTypeDescription(instance)
        return "#\(instanceNumber) - \(typeDescription)"
    }

    static func getInstanceDescription(_ instance: Instance) -> String {
        let instanceNumber = extractInstanceNumber(from: instance.instanceId)
        let typeDescription = getInstanceTypeDescription(instance)
        let userCount = getUserCountString(instance)
        return "#\(instanceNumber) - \(typeDescription) \(userCount)"
    }

    static func getInstanceTypeWithUserCount(_ instance: Instance) -> String {
        let typeDescription = getInstanceTypeDescription(instance)
        let userCount = getUserCountString(instance)
        return "\(typeDescription) \(userCount)"
    }
} 
