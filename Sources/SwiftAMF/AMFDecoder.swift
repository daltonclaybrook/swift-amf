//  Created by Dalton Claybrook on 4/12/24.

import Foundation

public struct AMFDecoder {
    public init() {}

    public func decode(data: Data) throws -> [AMFValue] {
        var currentIndex = 0
        var values: [AMFValue] = []
        while currentIndex < data.count {
            let nextValue = try parseNextValue(at: &currentIndex, in: data)
            values.append(nextValue)
        }
        return values
    }

    // MARK: - Next value parser

    private func parseNextValue(at index: inout Int, in data: Data) throws -> AMFValue {
        let byte = try consumeByte(of: data, at: &index)
        guard let typeMarker = AMFTypeMarker(rawValue: byte) else {
            throw AMFDecoderError.unexpectedTypeMarker(byte)
        }

        switch typeMarker {
        case .number:
            return try .number(parseNumber(at: &index, in: data))
        case .boolean:
            return try .boolean(parseBoolean(at: &index, in: data))
        case .string:
            return try .string(parseString(at: &index, in: data))
        case .object:
            return try .object(parseObject(at: &index, in: data))
        case .movieClip:
            try parseMovieClip(at: &index, in: data)
        case .null:
            return .null
        case .undefined:
            return .undefined
        case .reference:
            return try .reference(parseReference(at: &index, in: data))
        case .ecmaArray:
            return try .ecmaArray(parseECMAArray(at: &index, in: data))
        case .strictArray:
            return try .strictArray(parseStrictArray(at: &index, in: data))
        case .date:
            return try .date(parseDate(at: &index, in: data))
        case .longString:
            return try .longString(parseLongString(at: &index, in: data))
        case .unsupported:
            return try .unsupported
        case .recordSet:
            try parseRecordSet(at: &index, in: data)
        case .xmlDocument:
            return try .xmlDocument(parseXMLDocument(at: &index, in: data))
        case .typedObject:
            let (className, object) = try parseTypedObject(at: &index, in: data)
            return .typedObject(className: className, object)
        case .avmPlusObject:
            try parseAVMPlusObject(at: &index, in: data)
        }
    }

    // MARK: - Type parser functions

    private func parseNumber(at index: inout Int, in data: Data) throws -> Double {
        try consumeBytes(of: data, startingAt: &index, count: 8).withUnsafeBytes { pointer in
            Double(bitPattern: pointer.load(as: UInt64.self).bigEndian)
        }
    }

    /// A zero byte value denotes false while a non-zero byte value (typically 1) denotes true.
    private func parseBoolean(at index: inout Int, in data: Data) throws -> Bool {
        let value = try consumeByte(of: data, at: &index)
        if value == 0 {
            return false
        } else {
            return true
        }
    }

    private func parseString(at index: inout Int, in data: Data) throws -> String {
        let length = try consumeBytes(of: data, startingAt: &index, count: 2).withUnsafeBytes { pointer in
            UInt16(bigEndian: pointer.load(as: UInt16.self))
        }
        return try _parseString(at: &index, in: data, length: Int(length))
    }

    private func parseObject(at index: inout Int, in data: Data) throws -> [String: AMFValue] {
        var object: [String: AMFValue] = [:]
        while parseEndOfObject(at: &index, in: data) == false {
            let key = try parseString(at: &index, in: data)
            object[key] = try parseNextValue(at: &index, in: data)
        }
        return object
    }

    private func parseMovieClip(at index: inout Int, in data: Data) throws -> Never {
        throw AMFDecoderError.reservedTypeNotSupported(.movieClip)
    }

    private func parseReference(at index: inout Int, in data: Data) throws -> UInt16 {
        try consumeBytes(of: data, startingAt: &index, count: 2).withUnsafeBytes { pointer in
            UInt16(bigEndian: pointer.load(as: UInt16.self))
        }
    }

    private func parseECMAArray(at index: inout Int, in data: Data) throws -> [String: AMFValue] {
        let length = try consumeBytes(of: data, startingAt: &index, count: 4).withUnsafeBytes { pointer in
            UInt32(bigEndian: pointer.load(as: UInt32.self))
        }
        let array: [String: AMFValue] = try (0..<length).reduce(into: [:]) { result, _ in
            let key = try parseString(at: &index, in: data)
            result[key] = try parseNextValue(at: &index, in: data)
        }
        guard parseEndOfObject(at: &index, in: data) else {
            // ECMA arrays are expected to have [0x00, 0x00, 0x09] at the end
            throw AMFDecoderError.expectedObjectEndTypeAfterECMAArray
        }
        return array
    }

    private func parseStrictArray(at index: inout Int, in data: Data) throws -> [AMFValue] {
        let length = try consumeBytes(of: data, startingAt: &index, count: 4).withUnsafeBytes { pointer in
            UInt32(bigEndian: pointer.load(as: UInt32.self))
        }
        let array = try (0..<length).map { _ in
            try parseNextValue(at: &index, in: data)
        }
        return array
    }

    private func parseDate(at index: inout Int, in data: Data) throws -> Date {
        let dateNumber = try parseNumber(at: &index, in: data)
        let timeZone = try consumeBytes(of: data, startingAt: &index, count: 2).withUnsafeBytes { pointer in
            Int16(bigEndian: pointer.load(as: Int16.self))
        }
        if timeZone != 0 {
            print("Unexpected non-zero time zone: \(timeZone)")
        }
        return Date(timeIntervalSince1970: dateNumber / 1_000)
    }

    private func parseLongString(at index: inout Int, in data: Data) throws -> String {
        let length = try consumeBytes(of: data, startingAt: &index, count: 4).withUnsafeBytes { pointer in
            UInt32(bigEndian: pointer.load(as: UInt32.self))
        }
        return try _parseString(at: &index, in: data, length: Int(length))
    }

    private func parseRecordSet(at index: inout Int, in data: Data) throws -> Never {
        throw AMFDecoderError.reservedTypeNotSupported(.recordSet)
    }

    private func parseXMLDocument(at index: inout Int, in data: Data) throws -> String {
        let length = try consumeBytes(of: data, startingAt: &index, count: 4).withUnsafeBytes { pointer in
            UInt32(bigEndian: pointer.load(as: UInt32.self))
        }
        return try _parseString(at: &index, in: data, length: Int(length))
    }

    private func parseTypedObject(at index: inout Int, in data: Data) throws -> (className: String, [String: AMFValue]) {
        fatalError("Unimplemented")
    }

    private func parseAVMPlusObject(at index: inout Int, in data: Data) throws -> Never {
        throw AMFDecoderError.amfVersion3NotYetSupported
    }

    // MARK: - Helpers

    private func consumeByte(of data: Data, at index: inout Int) throws -> UInt8 {
        guard index < data.count else {
            throw AMFDecoderError.unexpectedEndOfData
        }
        defer { index += 1}
        return data[index]
    }

    private func consumeBytes(of data: Data, startingAt index: inout Int, count: Int) throws -> [UInt8] {
        guard index + count <= data.count else {
            throw AMFDecoderError.unexpectedEndOfData
        }
        defer { index += count }
        return Array(data[index..<(index + count)])
    }

    private func _parseString(at index: inout Int, in data: Data, length: Int) throws -> String {
        let stringBytes = try consumeBytes(of: data, startingAt: &index, count: length)
        guard let string = String(data: Data(stringBytes), encoding: .utf8) else {
            throw AMFDecoderError.invalidUTF8String
        }
        return string
    }

    /// Returns true if the end-of-object bytes were able to be parsed and consumed. If false, no bytes were consumed.
    private func parseEndOfObject(at index: inout Int, in data: Data) -> Bool {
        guard index + 3 <= data.count else {
            return false
        }
        // '0x00 0x00' == UTF-8-empty and '0x09' == object-end-marker
        if data[index..<(index + 3)].elementsEqual([0x00, 0x00, 0x09]) {
            index += 3 // Only consume the bytes if it's a match
            return true
        } else {
            return false
        }
    }
}

enum AMFDecoderError: Error {
    case unexpectedTypeMarker(UInt8)
    case unexpectedEndOfData
    case invalidUTF8String
    case reservedTypeNotSupported(AMFTypeMarker)
    case amfVersion3NotYetSupported
    case expectedObjectEndTypeAfterECMAArray
}
