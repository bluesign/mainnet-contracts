pub contract EVM{ 
    pub        
        /// EVMAddress is an EVM-compatible address
        struct EVMAddress{ 
        pub let                
                /// Bytes of the address
                bytes: [UInt8; 20]
        
        /// Constructs a new EVM address from the given byte representation
        init(bytes: [UInt8; 20]){ 
            self.bytes = bytes
        }
    }
    
    pub fun encodeABI(_ values: [AnyStruct]): [UInt8]{ 
        return InternalEVM.encodeABI(values)
    }
    
    pub fun decodeABI(types: [Type], data: [UInt8]): [AnyStruct]{ 
        return InternalEVM.decodeABI(types: types, data: data)
    }
    
    pub fun encodeABIWithSignature(
        _ signature: String,
        _ values: [
            AnyStruct
        ]
    ): [
        UInt8
    ]{ 
        let methodID =
            HashAlgorithm.KECCAK_256.hash(signature.utf8).slice(
                from: 0,
                upTo: 4
            )
        let arguments = InternalEVM.encodeABI(values)
        return methodID.concat(arguments)
    }
    
    pub fun decodeABIWithSignature(
        _ signature: String,
        types: [
            Type
        ],
        data: [
            UInt8
        ]
    ): [
        AnyStruct
    ]{ 
        let methodID =
            HashAlgorithm.KECCAK_256.hash(signature.utf8).slice(
                from: 0,
                upTo: 4
            )
        for byte in methodID{ 
            if byte != data.removeFirst(){ 
                panic("signature mismatch")
            }
        }
        return InternalEVM.decodeABI(types: types, data: data)
    }
}
