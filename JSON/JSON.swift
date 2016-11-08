/*

Copyright (c) 2016, Storehouse
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/


import Foundation


/// Recursive structure that represents a JSON tree.
public enum JSON {
    case number(Double)
    case string(Swift.String)
    case boolean(Bool)
    case array([JSON])
    case object([Swift.String:JSON])
    case null
}


public extension JSON {
    
    /// Initialize a JSON value from NSData.
    /// - Parameter data: A data object containing JSON data (typically fetched from a server or file).
    /// - Note: returns nil if the data object could not be successfully parsed as JSON.
    public init?(data: Data) {
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            self.init(NSJSONObject: obj as AnyObject)
        } catch {
            return nil
        }
    }
    
    /// Initialize a JSON value from a string containing JSON data.
    /// - Parameter string: A string containing JSON data.
    /// - Note: returns nil if the string could not be successfully parsed as JSON.
    public init?(string: Swift.String) {
        guard let data = string.data(using: Swift.String.Encoding.utf8) else { return nil }
        self.init(data: data)
    }
    
    /// Initialize a JSON value from a JSON object returned by NSJSONSerialization.
    /// - Parameter NSJSONObject: A JSON object returned by NSJSONSerialization.
    /// - SeeAlso: `init?(data:)`
    public init(NSJSONObject: Any) {
        switch NSJSONObject {
        case let number as NSNumber:
            let typeString = NSString(utf8String: number.objCType)
            guard let type = typeString else { fatalError() } // should not be possible
            if type.isEqual(to: "c") {
                self = .boolean(number.boolValue)
            } else {
                self = .number(number.doubleValue)
            }
        case let str as Swift.String:
            self = .string(str)
        case let boolean as Bool:
            self = .boolean(boolean)
        case let array as [AnyObject]:
            self = .array(array.map {JSON(NSJSONObject: $0)})
        case let dictionary as [AnyHashable: Any]:
            var d: [Swift.String: JSON] = [:]
            for key in dictionary.keys {
                guard let key = key as? Swift.String else { fatalError("Unexpected key type found in JSON Dictionary") }
                guard let val = dictionary[key] else { fatalError("Error retrieving value from JSON Dictionary") }
                d[key] = JSON(NSJSONObject: val as AnyObject)
            }
            self = .object(d)
        case _ as NSNull:
            self = .null
        default:
            fatalError("Unsupported JSON object type")
        }
    }
    
}


public extension JSON { // core JSON-type accessors
    
    public subscript(key: Swift.String) -> JSON? {
        get {
            guard case let .object(dictionary) = self else { return nil }
            return dictionary[key]
        }
        set {
            guard case var .object(dictionary) = self else { fatalError("Keyed valued are only supported on objects") }
            dictionary[key] = newValue
            self = .object(dictionary)
        }
    }
    
    public subscript(index: Int) -> JSON? {
        get {
            guard case let .array(array) = self else { return nil }
            return array[index]
        }
    }
    
    /// The underlying string value for a JSON string, or nil if it's not a JSON string.
    public var string: Swift.String? {
        switch self {
        case .string(let str):
            return str
        default:
            return nil
        }
    }
    
    /// The underlying number value (as a `Double`) for a JSON number, or nil if it's not a JSON number.
    public var number: Double? {
        switch self {
        case .number(let num):
            return num
        default:
            return nil
        }
    }
    
    /// The underlying boolean value for a JSON boolean, or nil if it's not a JSON boolean.
    public var boolean: Bool? {
        switch self {
        case .boolean(let bool):
            return bool
        default:
            return nil
        }
    }
    
    /// The underlying array value for a JSON array, or nil if it's not a JSON array.
    public var array: [JSON]? {
        switch self {
        case .array(let array):
            return array
        default:
            return nil
        }
    }
    
    /// The underlying dictionary value for a JSON dictionary, or nil if it's not a JSON dictionary.
    public var object: [Swift.String: JSON]? {
        switch self {
        case .object(let dictionary):
            return dictionary
        default:
            return nil
        }
    }
    
}


extension JSON : Equatable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs, rhs) {
    case (.number(let num1), .number(let num2)):
        return num1 == num2
    case (.string(let str1), .string(let str2)):
        return str1 == str2
    case (.boolean(let b1), .boolean(let b2)):
        return b1 == b2
    case (.array(let a1), .array(let a2)):
        return a1 == a2
    case (.object(let o1), .object(let o2)):
        return o1 == o2
    case (.null, .null):
        return true
    default:
        return false
    }
}


extension JSON : Sequence {
    
    public func makeIterator() -> JSONGenerator {
        return JSONGenerator(JSONs: array ?? [])
    }
    
    public struct JSONGenerator: IteratorProtocol {
        fileprivate let JSONs: [JSON]
        fileprivate var nextIndex = 0
        fileprivate init(JSONs: [JSON]) { self.JSONs = JSONs }
        public mutating func next() -> JSON? {
            guard nextIndex < JSONs.count else { return nil }
            let j = JSONs[nextIndex]
            nextIndex += 1
            return j
        }
    }
    
}


extension JSON : CustomDebugStringConvertible, CustomStringConvertible {
    
    public var debugDescription: Swift.String {
        return formattedOutputString(true)
    }
    
    public var description: Swift.String {
        return formattedOutputString(true)
    }
    
    /// The JSON tree formatted as a JSON string.
    /// - SeeAlso: `description` and `debugDescription`.
    public var formattedJSON: Swift.String {
        return formattedOutputString(false)
    }
    
    fileprivate func formattedOutputString(_ pretty: Bool) -> Swift.String {
        do {
            let data = try JSONSerialization.data(withJSONObject: NSJSONValue, options: pretty ? [.prettyPrinted] : [])
            guard let string = Swift.String(data: data, encoding: .utf8) else { return "" }
            return string as Swift.String
        } catch {
            return ""
        }
    }
    
}


extension JSON {
    
    /// The JSON tree formatted as NSObject-compatible objects.
    public var NSJSONValue: NSObject {
        switch self {
        case .number(let num):
            return num as NSObject
        case .string(let str):
            return str as NSObject
        case .boolean(let bool):
            return bool as NSObject
        case .array(let array):
            return array.map({ $0.NSJSONValue }) as NSArray
        case .object(let dictionary):
            var output: [AnyHashable: Any] = [:]
            for (key, j) in dictionary {
                output[key] = j.NSJSONValue
            }
            return output as NSObject
        case .null:
            return NSNull()
        }
    }
    
}

