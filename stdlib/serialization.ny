# ============================================================
# Nyx Standard Library - Serialization Module
# ============================================================
# Comprehensive serialization framework providing binary, 
# MessagePack, Protocol Buffers, and custom serialization.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Serialization formats
let FORMAT_BINARY = "binary";
let FORMAT_MSGPACK = "msgpack";
let FORMAT_PROTOBUF = "protobuf";
let FORMAT_JSON = "json";
let FORMAT_CBOR = "cbor";
let FORMAT_UBJSON = "ubjson";

# Type markers for binary format
let TYPE_NULL = 0x00;
let TYPE_TRUE = 0x01;
let TYPE_FALSE = 0x02;
let TYPE_INT8 = 0x10;
let TYPE_INT16 = 0x11;
let TYPE_INT32 = 0x12;
let TYPE_INT64 = 0x13;
let TYPE_UINT8 = 0x20;
let TYPE_UINT16 = 0x21;
let TYPE_UINT32 = 0x22;
let TYPE_UINT64 = 0x23;
let TYPE_FLOAT32 = 0x30;
let TYPE_FLOAT64 = 0x31;
let TYPE_STRING = 0x40;
let TYPE_BINARY = 0x41;
let TYPE_ARRAY = 0x50;
let TYPE_MAP = 0x51;
let TYPE_OBJECT = 0x52;

# ============================================================
# Binary Serializer
# ============================================================

class BinarySerializer {
    init() {
        self.buffer = [];
    }

    serialize(value) {
        self.buffer = [];
        self._writeValue(value);
        return self._toBytes();
    }

    _writeValue(value) {
        if value == null {
            self._writeUInt8(TYPE_NULL);
        } else if type(value) == "boolean" {
            if value {
                self._writeUInt8(TYPE_TRUE);
            } else {
                self._writeUInt8(TYPE_FALSE);
            }
        } else if type(value) == "number" {
            if value == floor(value) {
                if value >= -128 and value <= 127 {
                    self._writeUInt8(TYPE_INT8);
                    self._writeInt8(value);
                } else if value >= -32768 and value <= 32767 {
                    self._writeUInt8(TYPE_INT16);
                    self._writeInt16(value);
                } else if value >= -2147483648 and value <= 2147483647 {
                    self._writeUInt8(TYPE_INT32);
                    self._writeInt32(value);
                } else {
                    self._writeUInt8(TYPE_INT64);
                    self._writeInt64(value);
                }
            } else {
                self._writeUInt8(TYPE_FLOAT64);
                self._writeFloat64(value);
            }
        } else if type(value) == "string" {
            self._writeString(value);
        } else if type(value) == "list" {
            self._writeArray(value);
        } else if type(value) == "map" {
            self._writeMap(value);
        }
    }

    _writeUInt8(value) {
        self.buffer = self.buffer + [value & 0xFF];
    }

    _writeInt8(value) {
        self._writeUInt8(value);
    }

    _writeInt16(value) {
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeInt32(value) {
        self._writeUInt8((value >> 24) & 0xFF);
        self._writeUInt8((value >> 16) & 0xFF);
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeInt64(value) {
        # Simplified for 64-bit
        self._writeInt32((value >> 32) & 0xFFFFFFFF);
        self._writeInt32(value & 0xFFFFFFFF);
    }

    _writeFloat32(value) {
        # Would use float32 conversion
        self._writeFloat64(value);
    }

    _writeFloat64(value) {
        # Simplified - would use proper float64 encoding
        let str = str(value);
        self._writeString(str);
    }

    _writeString(value) {
        let bytes = self._toUTF8(value);
        let length = len(bytes);
        
        if length <= 255 {
            self._writeUInt8(TYPE_STRING);
            self._writeUInt8(length);
        } else if length <= 65535 {
            self._writeUInt8(TYPE_STRING);
            self._writeUInt8(0xFF);
            self._writeInt16(length);
        } else {
            self._writeUInt8(TYPE_STRING);
            self._writeUInt8(0xFE);
            self._writeInt32(length);
        }
        
        for b in bytes {
            self._writeUInt8(b);
        }
    }

    _writeArray(value) {
        let length = len(value);
        
        if length <= 255 {
            self._writeUInt8(TYPE_ARRAY);
            self._writeUInt8(length);
        } else if length <= 65535 {
            self._writeUInt8(TYPE_ARRAY);
            self._writeUInt8(0xFF);
            self._writeInt16(length);
        } else {
            self._writeUInt8(TYPE_ARRAY);
            self._writeUInt8(0xFE);
            self._writeInt32(length);
        }
        
        for item in value {
            self._writeValue(item);
        }
    }

    _writeMap(value) {
        let keys = keys(value);
        let length = len(keys);
        
        if length <= 255 {
            self._writeUInt8(TYPE_MAP);
            self._writeUInt8(length);
        } else if length <= 65535 {
            self._writeUInt8(TYPE_MAP);
            self._writeUInt8(0xFF);
            self._writeInt16(length);
        } else {
            self._writeUInt8(TYPE_MAP);
            self._writeUInt8(0xFE);
            self._writeInt32(length);
        }
        
        for key in keys {
            self._writeValue(key);
            self._writeValue(value[key]);
        }
    }

    _toUTF8(str) {
        # Simplified UTF-8 conversion
        let bytes = [];
        for i in range(len(str)) {
            bytes = bytes + [str[i]];
        }
        return bytes;
    }

    _toBytes() {
        return join(self.buffer, "");
    }
}

# ============================================================
# Binary Deserializer
# ============================================================

class BinaryDeserializer {
    init(data) {
        self.data = data;
        self.position = 0;
    }

    deserialize() {
        return self._readValue();
    }

    _readValue() {
        if self.position >= len(self.data) {
            return null;
        }
        
        let type = self._readUInt8();
        
        if type == TYPE_NULL {
            return null;
        } else if type == TYPE_TRUE {
            return true;
        } else if type == TYPE_FALSE {
            return false;
        } else if type == TYPE_INT8 {
            return self._readInt8();
        } else if type == TYPE_INT16 {
            return self._readInt16();
        } else if type == TYPE_INT32 {
            return self._readInt32();
        } else if type == TYPE_INT64 {
            return self._readInt64();
        } else if type == TYPE_FLOAT32 or type == TYPE_FLOAT64 {
            return self._readFloat64();
        } else if type == TYPE_STRING {
            return self._readString();
        } else if type == TYPE_ARRAY {
            return self._readArray();
        } else if type == TYPE_MAP {
            return self._readMap();
        }
        
        return null;
    }

    _readUInt8() {
        let pos = self.position;
        self.position = pos + 1;
        
        if pos >= len(self.data) {
            return 0;
        }
        
        return self.data[pos];
    }

    _readInt8() {
        return self._readUInt8();
    }

    _readInt16() {
        let high = self._readUInt8();
        let low = self._readUInt8();
        return (high << 8) | low;
    }

    _readInt32() {
        let b1 = self._readUInt8();
        let b2 = self._readUInt8();
        let b3 = self._readUInt8();
        let b4 = self._readUInt8();
        return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }

    _readInt64() {
        return self._readInt32();
    }

    _readFloat64() {
        let str = self._readString();
        return parseFloat(str);
    }

    _readString() {
        let lengthFlag = self._readUInt8();
        
        let length = 0;
        if lengthFlag < 0xFE {
            length = lengthFlag;
        } else if lengthFlag == 0xFF {
            length = self._readInt16();
        } else if lengthFlag == 0xFE {
            length = self._readInt32();
        }
        
        let result = "";
        for i in range(length) {
            result = result + self._readUInt8();
        }
        
        return result;
    }

    _readArray() {
        let lengthFlag = self._readUInt8();
        
        let length = 0;
        if lengthFlag < 0xFE {
            length = lengthFlag;
        } else if lengthFlag == 0xFF {
            length = self._readInt16();
        } else if lengthFlag == 0xFE {
            length = self._readInt32();
        }
        
        let result = [];
        for i in range(length) {
            result = result + [self._readValue()];
        }
        
        return result;
    }

    _readMap() {
        let lengthFlag = self._readUInt8();
        
        let length = 0;
        if lengthFlag < 0xFE {
            length = lengthFlag;
        } else if lengthFlag == 0xFF {
            length = self._readInt16();
        } else if lengthFlag == 0xFE {
            length = self._readInt32();
        }
        
        let result = {};
        for i in range(length) {
            let key = self._readValue();
            let value = self._readValue();
            result[key] = value;
        }
        
        return result;
    }
}

# ============================================================
# MessagePack Serializer
# ============================================================

class MessagePackSerializer {
    init() {
        self.buffer = [];
    }

    serialize(value) {
        self.buffer = [];
        self._writeValue(value);
        return join(self.buffer, "");
    }

    _writeValue(value) {
        if value == null {
            self._writeUInt8(0xC0);
        } else if type(value) == "boolean" {
            if value {
                self._writeUInt8(0xC3);
            } else {
                self._writeUInt8(0xC2);
            }
        } else if type(value) == "number" {
            if value == floor(value) {
                if value >= 0 {
                    if value <= 127 {
                        self._writeUInt8(value);
                    } else if value <= 255 {
                        self._writeUInt8(0xCC);
                        self._writeUInt8(value);
                    } else if value <= 65535 {
                        self._writeUInt8(0xCD);
                        self._writeUInt16(value);
                    } else if value <= 4294967295 {
                        self._writeUInt8(0xCE);
                        self._writeUInt32(value);
                    } else {
                        self._writeUInt8(0xCF);
                        self._writeUInt64(value);
                    }
                } else {
                    if value >= -32 {
                        self._writeUInt8(0xE0 + (value + 32));
                    } else if value >= -128 {
                        self._writeUInt8(0xD0);
                        self._writeInt8(value);
                    } else if value >= -32768 {
                        self._writeUInt8(0xD1);
                        self._writeInt16(value);
                    } else if value >= -2147483648 {
                        self._writeUInt8(0xD2);
                        self._writeInt32(value);
                    } else {
                        self._writeUInt8(0xD3);
                        self._writeInt64(value);
                    }
                }
            } else {
                self._writeUInt8(0xCB);
                self._writeFloat64(value);
            }
        } else if type(value) == "string" {
            let length = len(value);
            if length <= 31 {
                self._writeUInt8(0xA0 + length);
            } else if length <= 255 {
                self._writeUInt8(0xD9);
                self._writeUInt8(length);
            } else if length <= 65535 {
                self._writeUInt8(0xDA);
                self._writeUInt16(length);
            } else {
                self._writeUInt8(0xDB);
                self._writeUInt32(length);
            }
            
            for i in range(length) {
                self._writeUInt8(value[i]);
            }
        } else if type(value) == "list" {
            let length = len(value);
            if length <= 15 {
                self._writeUInt8(0x90 + length);
            } else if length <= 65535 {
                self._writeUInt8(0xDC);
                self._writeUInt16(length);
            } else {
                self._writeUInt8(0xDD);
                self._writeUInt32(length);
            }
            
            for item in value {
                self._writeValue(item);
            }
        } else if type(value) == "map" {
            let length = len(keys(value));
            if length <= 15 {
                self._writeUInt8(0x80 + length);
            } else if length <= 65535 {
                self._writeUInt8(0xDE);
                self._writeUInt16(length);
            } else {
                self._writeUInt8(0xDF);
                self._writeUInt32(length);
            }
            
            for key in keys(value) {
                self._writeValue(key);
                self._writeValue(value[key]);
            }
        }
    }

    _writeUInt8(value) {
        self.buffer = self.buffer + [value & 0xFF];
    }

    _writeUInt16(value) {
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeUInt32(value) {
        self._writeUInt8((value >> 24) & 0xFF);
        self._writeUInt8((value >> 16) & 0xFF);
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeUInt64(value) {
        self._writeUInt32((value >> 32) & 0xFFFFFFFF);
        self._writeUInt32(value & 0xFFFFFFFF);
    }

    _writeInt8(value) {
        self._writeUInt8(value & 0xFF);
    }

    _writeInt16(value) {
        self._writeUInt16(value & 0xFFFF);
    }

    _writeInt32(value) {
        self._writeUInt32(value & 0xFFFFFFFF);
    }

    _writeInt64(value) {
        self._writeUInt64(value);
    }

    _writeFloat64(value) {
        # Simplified
        let str = str(value);
        for i in range(len(str)) {
            self._writeUInt8(str[i]);
        }
    }
}

# ============================================================
# MessagePack Deserializer
# ============================================================

class MessagePackDeserializer {
    init(data) {
        self.data = data;
        self.position = 0;
    }

    deserialize() {
        return self._readValue();
    }

    _readValue() {
        if self.position >= len(self.data) {
            return null;
        }
        
        let byte = self._readUInt8();
        
        # Null
        if byte == 0xC0 {
            return null;
        }
        
        # Booleans
        if byte == 0xC2 {
            return false;
        }
        if byte == 0xC3 {
            return true;
        }
        
        # Positive fixint
        if byte <= 0x7F {
            return byte;
        }
        
        # Negative fixint
        if byte >= 0xE0 {
            return byte - 256;
        }
        
        # Fixstr
        if byte >= 0xA0 and byte <= 0xBF {
            let length = byte - 0xA0;
            return self._readString(length);
        }
        
        # Fixarray
        if byte >= 0x90 and byte <= 0x9F {
            let length = byte - 0x90;
            return self._readArray(length);
        }
        
        # Fixmap
        if byte >= 0x80 and byte <= 0x8F {
            let length = byte - 0x80;
            return self._readMap(length);
        }
        
        # Unsigned integers
        if byte == 0xCC {
            return self._readUInt8();
        }
        if byte == 0xCD {
            return self._readUInt16();
        }
        if byte == 0xCE {
            return self._readUInt32();
        }
        if byte == 0xCF {
            return self._readUInt64();
        }
        
        # Signed integers
        if byte == 0xD0 {
            return self._readInt8();
        }
        if byte == 0xD1 {
            return self._readInt16();
        }
        if byte == 0xD2 {
            return self._readInt32();
        }
        if byte == 0xD3 {
            return self._readInt64();
        }
        
        # Float
        if byte == 0xCB {
            return self._readFloat64();
        }
        
        # Strings
        if byte == 0xD9 {
            return self._readString(self._readUInt8());
        }
        if byte == 0xDA {
            return self._readString(self._readUInt16());
        }
        if byte == 0xDB {
            return self._readString(self._readUInt32());
        }
        
        # Arrays
        if byte == 0xDC {
            return self._readArray(self._readUInt16());
        }
        if byte == 0xDD {
            return self._readArray(self._readUInt32());
        }
        
        # Maps
        if byte == 0xDE {
            return self._readMap(self._readUInt16());
        }
        if byte == 0xDF {
            return self._readMap(self._readUInt32());
        }
        
        return null;
    }

    _readUInt8() {
        let pos = self.position;
        self.position = pos + 1;
        
        if pos >= len(self.data) {
            return 0;
        }
        
        return self.data[pos];
    }

    _readUInt16() {
        return (self._readUInt8() << 8) | self._readUInt8();
    }

    _readUInt32() {
        return (self._readUInt8() << 24) | (self._readUInt8() << 16) | 
               (self._readUInt8() << 8) | self._readUInt8();
    }

    _readUInt64() {
        return self._readUInt32();
    }

    _readInt8() {
        let value = self._readUInt8();
        if value >= 128 {
            return value - 256;
        }
        return value;
    }

    _readInt16() {
        let value = self._readUInt16();
        if value >= 32768 {
            return value - 65536;
        }
        return value;
    }

    _readInt32() {
        let value = self._readUInt32();
        if value >= 2147483648 {
            return value - 4294967296;
        }
        return value;
    }

    _readInt64() {
        return self._readInt32();
    }

    _readFloat64() {
        let str = self._readString(self._readUInt8());
        return parseFloat(str);
    }

    _readString(length) {
        let result = "";
        for i in range(length) {
            result = result + chr(self._readUInt8());
        }
        return result;
    }

    _readArray(length) {
        let result = [];
        for i in range(length) {
            result = result + [self._readValue()];
        }
        return result;
    }

    _readMap(length) {
        let result = {};
        for i in range(length) {
            let key = self._readValue();
            let value = self._readValue();
            result[key] = value;
        }
        return result;
    }
}

# ============================================================
# Protocol Buffers Style Schema
# ============================================================

class ProtobufSchema {
    init(name) {
        self.name = name;
        self.fields = {};
        self.enums = {};
    }

    addField(number, name, type, repeated, required) {
        self.fields[number] = {
            "number": number,
            "name": name,
            "type": type,
            "repeated": repeated ?? false,
            "required": required ?? false
        };
        
        return self;
    }

    addEnum(name, values) {
        self.enums[name] = values;
        return self;
    }

    getField(number) {
        return self.fields[number];
    }

    getFieldByName(name) {
        for num in keys(self.fields) {
            if self.fields[num]["name"] == name {
                return self.fields[num];
            }
        }
        return null;
    }

    validate(data) {
        let errors = [];
        
        # Check required fields
        for num in keys(self.fields) {
            let field = self.fields[num];
            
            if field["required"] {
                if data[field["name"]] == null {
                    errors = errors + ["Missing required field: " + field["name"]];
                }
            }
        }
        
        return {
            "valid": len(errors) == 0,
            "errors": errors
        };
    }
}

class ProtobufSerializer {
    init(schema) {
        self.schema = schema;
    }

    serialize(data) {
        self.buffer = [];
        
        let validation = self.schema.validate(data);
        if not validation["valid"] {
            return null;
        }
        
        for num in keys(self.schema.fields) {
            let field = self.schema.fields[num];
            let value = data[field["name"]];
            
            if value != null {
                self._writeField(field, value);
            }
        }
        
        return join(self.buffer, "");
    }

    _writeField(field, value) {
        let wireType = self._getWireType(field["type"]);
        let tag = (field["number"] << 3) | wireType;
        
        self._writeVarint(tag);
        
        if field["repeated"] {
            for item in value {
                self._writeValue(field["type"], item);
            }
        } else {
            self._writeValue(field["type"], value);
        }
    }

    _writeValue(type, value) {
        if type == "int32" or type == "int64" or type == "uint32" or type == "uint64" {
            self._writeVarint(value);
        } else if type == "sint32" or type == "sint64" {
            self._writeZigZag(value);
        } else if type == "fixed32" {
            self._writeFixed32(value);
        } else if type == "fixed64" {
            self._writeFixed64(value);
        } else if type == "sfixed32" {
            self._writeSFixed32(value);
        } else if type == "sfixed64" {
            self._writeSFixed64(value);
        } else if type == "float" {
            self._writeFloat(value);
        } else if type == "double" {
            self._writeDouble(value);
        } else if type == "bool" {
            self._writeVarint(value ? 1 : 0);
        } else if type == "string" or type == "bytes" {
            self._writeLengthDelimited(value);
        } else if type == "message" {
            let nested = ProtobufSerializer(self.schema);
            let nestedData = nested.serialize(value);
            self._writeLengthDelimited(nestedData);
        }
    }

    _writeVarint(value) {
        while value > 0x7F {
            self.buffer = self.buffer + [0x80 | (value & 0x7F)];
            value = value >> 7;
        }
        self.buffer = self.buffer + [value];
    }

    _writeZigZag(value) {
        if value < 0 {
            value = (value * -2) - 1;
        } else {
            value = value * 2;
        }
        self._writeVarint(value);
    }

    _writeFixed32(value) {
        self.buffer = self.buffer + [
            value & 0xFF,
            (value >> 8) & 0xFF,
            (value >> 16) & 0xFF,
            (value >> 24) & 0xFF
        ];
    }

    _writeFixed64(value) {
        self._writeFixed32(value & 0xFFFFFFFF);
        self._writeFixed32((value >> 32) & 0xFFFFFFFF);
    }

    _writeSFixed32(value) {
        self._writeFixed32(value);
    }

    _writeSFixed64(value) {
        self._writeFixed64(value);
    }

    _writeFloat(value) {
        self._writeFixed32(value);
    }

    _writeDouble(value) {
        self._writeFixed64(value);
    }

    _writeLengthDelimited(value) {
        self._writeVarint(len(value));
        for i in range(len(value)) {
            self.buffer = self.buffer + [value[i]];
        }
    }

    _getWireType(type) {
        if type == "int32" or type == "int64" or type == "uint32" or type == "uint64" or 
           type == "sint32" or type == "sint64" or type == "bool" {
            return 0;
        }
        if type == "fixed64" or type == "sfixed64" or type == "double" {
            return 1;
        }
        if type == "fixed32" or type == "sfixed32" or type == "float" {
            return 5;
        }
        return 2;
    }
}

# ============================================================
# CBOR Serializer (Simplified)
# ============================================================

class CBORSerializer {
    init() {
        self.buffer = [];
    }

    serialize(value) {
        self.buffer = [];
        self._writeValue(value);
        return join(self.buffer, "");
    }

    _writeValue(value) {
        if value == null {
            self._writeUInt8(0xF6);
        } else if type(value) == "boolean" {
            self._writeUInt8(value ? 0xF5 : 0xF4);
        } else if type(value) == "number" {
            if value == floor(value) {
                if value >= 0 and value <= 23 {
                    self._writeUInt8(value);
                } else if value >= 24 and value <= 255 {
                    self._writeUInt8(0x18);
                    self._writeUInt8(value);
                } else if value >= 256 and value <= 65535 {
                    self._writeUInt8(0x19);
                    self._writeUInt16(value);
                } else {
                    self._writeUInt8(0x1A);
                    self._writeUInt32(value);
                }
            } else {
                self._writeUInt8(0xFB);
                # Would write float64
            }
        } else if type(value) == "string" {
            let length = len(value);
            if length <= 31 {
                self._writeUInt8(0x60 + length);
            } else if length <= 255 {
                self._writeUInt8(0x78);
                self._writeUInt8(length);
            } else if length <= 65535 {
                self._writeUInt8(0x79);
                self._writeUInt16(length);
            }
            
            for i in range(length) {
                self._writeUInt8(value[i]);
            }
        } else if type(value) == "list" {
            let length = len(value);
            if length <= 31 {
                self._writeUInt8(0x80 + length);
            } else if length <= 255 {
                self._writeUInt8(0x98);
                self._writeUInt8(length);
            }
            
            for item in value {
                self._writeValue(item);
            }
        } else if type(value) == "map" {
            let length = len(keys(value));
            if length <= 31 {
                self._writeUInt8(0xA0 + length);
            }
            
            for key in keys(value) {
                self._writeValue(key);
                self._writeValue(value[key]);
            }
        }
    }

    _writeUInt8(value) {
        self.buffer = self.buffer + [value & 0xFF];
    }

    _writeUInt16(value) {
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeUInt32(value) {
        self._writeUInt8((value >> 24) & 0xFF);
        self._writeUInt8((value >> 16) & 0xFF);
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }
}

# ============================================================
# UBJSON Serializer
# ============================================================

class UBJSONSerializer {
    init() {
        self.buffer = [];
        self.optimizeNumbers = true;
    }

    serialize(value) {
        self.buffer = [];
        self._writeValue(value);
        return join(self.buffer, "");
    }

    _writeValue(value) {
        if value == null {
            self._writeUInt8(0x5A);  # Z
        } else if type(value) == "boolean" {
            self._writeUInt8(value ? 0x54 : 0x46);  # T or F
        } else if type(value) == "number" {
            if value == floor(value) {
                if value >= -128 and value <= 127 {
                    self._writeUInt8(0x69);  # i
                    self._writeInt8(value);
                } else if value >= -32768 and value <= 32767 {
                    self._writeUInt8(0x69);  # i
                    self._writeInt16(value);
                } else if value >= -2147483648 and value <= 2147483647 {
                    self._writeUInt8(0x6C);  # l
                    self._writeInt32(value);
                } else {
                    self._writeUInt8(0x4C);  # L
                    self._writeInt64(value);
                }
            } else {
                self._writeUInt8(0x64);  # d
                self._writeFloat64(value);
            }
        } else if type(value) == "string" {
            self._writeUInt8(0x53);  # S
            self._writeString(value);
        } else if type(value) == "list" {
            self._writeUInt8(0x5B);  # [
            for item in value {
                self._writeValue(item);
            }
            self._writeUInt8(0x5D);  # ]
        } else if type(value) == "map" {
            self._writeUInt8(0x7B);  # {
            for key in keys(value) {
                self._writeValue(key);
                self._writeValue(value[key]);
            }
            self._writeUInt8(0x7D);  # }
        }
    }

    _writeUInt8(value) {
        self.buffer = self.buffer + [value & 0xFF];
    }

    _writeInt8(value) {
        self._writeUInt8(value);
    }

    _writeInt16(value) {
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeInt32(value) {
        self._writeUInt8((value >> 24) & 0xFF);
        self._writeUInt8((value >> 16) & 0xFF);
        self._writeUInt8((value >> 8) & 0xFF);
        self._writeUInt8(value & 0xFF);
    }

    _writeInt64(value) {
        self._writeInt32((value >> 32) & 0xFFFFFFFF);
        self._writeInt32(value & 0xFFFFFFFF);
    }

    _writeFloat64(value) {
        let str = str(value);
        self._writeString(str);
    }

    _writeString(value) {
        self._writeUInt8(0x69);  # i for integer length
        self._writeInt8(len(value));
        
        for i in range(len(value)) {
            self._writeUInt8(value[i]);
        }
    }
}

# ============================================================
# Serialization Factory
# ============================================================

class SerializerFactory {
    static createBinary() {
        return BinarySerializer();
    }

    static createMessagePack() {
        return MessagePackSerializer();
    }

    static createCBOR() {
        return CBORSerializer();
    }

    static createUBJSON() {
        return UBJSONSerializer();
    }

    static createProtobuf(schema) {
        return ProtobufSerializer(schema);
    }

    static serialize(value, format) {
        let serializer = null;
        
        if format == FORMAT_BINARY {
            serializer = BinarySerializer();
        } else if format == FORMAT_MSGPACK {
            serializer = MessagePackSerializer();
        } else if format == FORMAT_CBOR {
            serializer = CBORSerializer();
        } else if format == FORMAT_UBJSON {
            serializer = UBJSONSerializer();
        } else if format == FORMAT_JSON {
            return json.stringify(value);
        } else {
            return null;
        }
        
        return serializer.serialize(value);
    }

    static deserialize(data, format) {
        if format == FORMAT_BINARY {
            let deserializer = BinaryDeserializer(data);
            return deserializer.deserialize();
        } else if format == FORMAT_MSGPACK {
            let deserializer = MessagePackDeserializer(data);
            return deserializer.deserialize();
        } else if format == FORMAT_JSON {
            return json.parse(data);
        }
        
        return null;
    }
}

# ============================================================
# Schema Builder
# ============================================================

class SchemaBuilder {
    init(name) {
        self.schema = ProtobufSchema(name);
    }

    addField(number, name, type, options) {
        self.schema.addField(number, name, type, 
            options["repeated"] ?? false, 
            options["required"] ?? false);
        return self;
    }

    addEnum(name, values) {
        self.schema.addEnum(name, values);
        return self;
    }

    build() {
        return self.schema;
    }
}

# ============================================================
# Utility Functions
# ============================================================

fn serializeBinary(value) {
    return BinarySerializer().serialize(value);
}

fn deserializeBinary(data) {
    return BinaryDeserializer(data).deserialize();
}

fn serializeMsgPack(value) {
    return MessagePackSerializer().serialize(value);
}

fn deserializeMsgPack(data) {
    return MessagePackDeserializer(data).deserialize();
}

fn serializeJSON(value) {
    return json.stringify(value);
}

fn deserializeJSON(data) {
    return json.parse(data);
}

fn serialize(value, format) {
    return SerializerFactory.serialize(value, format);
}

fn deserialize(data, format) {
    return SerializerFactory.deserialize(data, format);
}

fn createSchema(name) {
    return SchemaBuilder(name);
}

fn createProtobufSchema(name) {
    return ProtobufSchema(name);
}

# ============================================================
# Export
# ============================================================

{
    "BinarySerializer": BinarySerializer,
    "BinaryDeserializer": BinaryDeserializer,
    "MessagePackSerializer": MessagePackSerializer,
    "MessagePackDeserializer": MessagePackDeserializer,
    "CBORSerializer": CBORSerializer,
    "UBJSONSerializer": UBJSONSerializer,
    "ProtobufSchema": ProtobufSchema,
    "ProtobufSerializer": ProtobufSerializer,
    "SerializerFactory": SerializerFactory,
    "SchemaBuilder": SchemaBuilder,
    "serializeBinary": serializeBinary,
    "deserializeBinary": deserializeBinary,
    "serializeMsgPack": serializeMsgPack,
    "deserializeMsgPack": deserializeMsgPack,
    "serializeJSON": serializeJSON,
    "deserializeJSON": deserializeJSON,
    "serialize": serialize,
    "deserialize": deserialize,
    "createSchema": createSchema,
    "createProtobufSchema": createProtobufSchema,
    "FORMAT_BINARY": FORMAT_BINARY,
    "FORMAT_MSGPACK": FORMAT_MSGPACK,
    "FORMAT_PROTOBUF": FORMAT_PROTOBUF,
    "FORMAT_JSON": FORMAT_JSON,
    "FORMAT_CBOR": FORMAT_CBOR,
    "FORMAT_UBJSON": FORMAT_UBJSON,
    "VERSION": VERSION
}
