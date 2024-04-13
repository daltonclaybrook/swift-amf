//  Created by Dalton Claybrook on 4/12/24.

import Foundation

public enum AMFTypeMarker: UInt8 {
    case number = 0x00
    case boolean = 0x01
    case string = 0x02
    case object = 0x03
    /// Reserved, not supported
    case movieClip = 0x04
    case null = 0x05
    case undefined = 0x06
    case reference = 0x07
    case ecmaArray = 0x08
    case strictArray = 0x0A
    case date = 0x0B
    case longString = 0x0C
    case unsupported = 0x0D
    /// Reserved, not supported
    case recordSet = 0x0E
    case xmlDocument = 0x0F
    case typedObject = 0x10
    case avmPlusObject = 0x11
}
