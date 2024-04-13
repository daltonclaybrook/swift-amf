//  Created by Dalton Claybrook on 4/12/24.

import Foundation

public enum AMFType {
    case number(Double)
    case boolean(Bool)
    case string(String)
    case object([String: AMFType])
    case null
    case undefined
    case reference(UInt16)
    case ecmaArray([String: AMFType])
    case objectEnd
    case strictArray([AMFType])
    case date(Date)
    case longString(String)
    case unsupported
    case xmlDocument(String)
    case typedObject(className: String, [String: AMFType])
    case avmPlusObject
}
