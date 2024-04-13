//  Created by Dalton Claybrook on 4/12/24.

import Foundation

public enum AMFValue {
    case number(Double)
    case boolean(Bool)
    case string(String)
    case object([String: AMFValue])
    case null
    case undefined
    case reference(UInt16)
    case ecmaArray([String: AMFValue])
    case objectEnd
    case strictArray([AMFValue])
    case date(Date)
    case longString(String)
    case unsupported
    case xmlDocument(String)
    case typedObject(className: String, [String: AMFValue])
    case avmPlusObject
}
