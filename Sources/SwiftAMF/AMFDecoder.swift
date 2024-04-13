//  Created by Dalton Claybrook on 4/12/24.

import Foundation

public struct AMFDecoder {
    public init() {}

    public func decode(data: Data) throws {
        var currentIndex = 0
        var values: [AMFValue] = []
        while currentIndex < data.count {
            let byte = consumeByte(of: data, at: &currentIndex)
            guard let typeMarker = AMFTypeMarker(rawValue: byte) else {
                throw AMFDecoderError.unexpectedTypeMarker(byte)
            }

            switch typeMarker {
            case .number:
                try values.append(.number(parseNumber(at: &currentIndex, in: data)))
            case .boolean:
                try values.append(.boolean(parseBoolean(at: &currentIndex, in: data)))
            case .string:
                try values.append(.string(parseString(at: &currentIndex, in: data)))
            case .object:
                try values.append(.object(parseObject(at: &currentIndex, in: data)))
            case .movieClip:
                try parseMovieClip(at: &currentIndex, in: data)
            case .null:
                try parseNull(at: &currentIndex, in: data)
                values.append(.null)
            case .undefined:
                try parseUndefined(at: &currentIndex, in: data)
                values.append(.undefined)
            case .reference:
                try values.append(.reference(parseReference(at: &currentIndex, in: data)))
            case .ecmaArray:
                try values.append(.ecmaArray(parseECMAArray(at: &currentIndex, in: data)))
            case .objectEnd:
                try parseObjectEnd(at: &currentIndex, in: data)
                values.append(.objectEnd)
            case .strictArray:
                try values.append(.strictArray(parseStrictArray(at: &currentIndex, in: data)))
            case .date:
                try values.append(.date(parseDate(at: &currentIndex, in: data)))
            case .longString:
                try values.append(.longString(parseLongString(at: &currentIndex, in: data)))
            case .unsupported:
                try parseUnsupported(at: &currentIndex, in: data)
                values.append(.unsupported)
            case .recordSet:
                try parseRecordSet(at: &currentIndex, in: data)
            case .xmlDocument:
                try values.append(.xmlDocument(parseXMLDocument(at: &currentIndex, in: data)))
            case .typedObject:
                let (className, object) = try parseTypedObject(at: &currentIndex, in: data)
                values.append(.typedObject(className: className, object))
            case .avmPlusObject:
                try parseAVMPlusObject(at: &currentIndex, in: data)
            }
        }
    }

    // MARK: - Private helpers

    private func parseNumber(at index: inout Int, in data: Data) throws -> Double {
        fatalError("Unimplemented")
    }

    private func parseBoolean(at index: inout Int, in data: Data) throws -> Bool {
        fatalError("Unimplemented")
    }

    private func parseString(at index: inout Int, in data: Data) throws -> String {
        fatalError("Unimplemented")
    }

    private func parseObject(at index: inout Int, in data: Data) throws -> [String: AMFValue] {
        fatalError("Unimplemented")
    }

    private func parseMovieClip(at index: inout Int, in data: Data) throws -> Never {
        throw AMFDecoderError.reservedTypeNotSupported(.movieClip)
    }

    private func parseNull(at index: inout Int, in data: Data) throws {
        fatalError("Unimplemented")
    }

    private func parseUndefined(at index: inout Int, in data: Data) throws {
        fatalError("Unimplemented")
    }

    private func parseReference(at index: inout Int, in data: Data) throws -> UInt16 {
        fatalError("Unimplemented")
    }

    private func parseECMAArray(at index: inout Int, in data: Data) throws -> [String: AMFValue] {
        fatalError("Unimplemented")
    }

    private func parseObjectEnd(at index: inout Int, in data: Data) throws {
        fatalError("Unimplemented")
    }

    private func parseStrictArray(at index: inout Int, in data: Data) throws -> [AMFValue] {
        fatalError("Unimplemented")
    }

    private func parseDate(at index: inout Int, in data: Data) throws -> Date {
        fatalError("Unimplemented")
    }

    private func parseLongString(at index: inout Int, in data: Data) throws -> String {
        fatalError("Unimplemented")
    }

    private func parseUnsupported(at index: inout Int, in data: Data) throws {
        fatalError("Unimplemented")
    }

    private func parseRecordSet(at index: inout Int, in data: Data) throws -> Never {
        throw AMFDecoderError.reservedTypeNotSupported(.recordSet)
    }

    private func parseXMLDocument(at index: inout Int, in data: Data) throws -> String {
        fatalError("Unimplemented")
    }

    private func parseTypedObject(at index: inout Int, in data: Data) throws -> (className: String, [String: AMFValue]) {
        fatalError("Unimplemented")
    }

    private func parseAVMPlusObject(at index: inout Int, in data: Data) throws -> Never {
        throw AMFDecoderError.amfVersion3NotYetSupported
    }

    private func consumeByte(of data: Data, at index: inout Int) -> UInt8 {
        defer { index += 1}
        return data[index]
    }
}

enum AMFDecoderError: Error {
    case unexpectedTypeMarker(UInt8)
    case reservedTypeNotSupported(AMFTypeMarker)
    case amfVersion3NotYetSupported
}
