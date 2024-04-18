pub contract Veriphoto{ 
    pub event ImageHashRecordCreated(creator: Address)
    
    pub event ImageRegistered(
        imageHash: String,
        owner: Address,
        metadata: ImageMetadata
    )
    
    pub let imageHashRecordStoragePath: StoragePath
    
    pub let imageHashRecordMetadataReaderPath: PrivatePath
    
    pub let imageHashRecordVerifierPath: PublicPath
    
    pub let accountRegistry:{ Address: Bool}
    
    pub var oracleAddress: Address
    
    pub struct ImageMetadata{ 
        pub let imageTimestamp: UFix64
        
        pub let extras:{ String: String}?
        
        pub var blockTimestamp: UFix64?
        
        access(contract) fun setBlockTimestamp(){ 
            self.blockTimestamp = getCurrentBlock().timestamp
        }
        
        init(imageTimestamp: UFix64, extras:{ String: String}?){ 
            self.imageTimestamp = imageTimestamp
            self.extras = extras
            self.blockTimestamp = nil
        }
    }
    
    pub resource interface Verifier{ 
        pub fun verifyImage(imageHash: String): Bool{} 
    }
    
    pub resource interface MetadataReader{ 
        pub fun getImageMetadata(imageHash: String): ImageMetadata?{} 
    }
    
    pub resource ImageHashRecord: Verifier, MetadataReader{ 
        pub let creator: Address
        
        priv let imageMetadata:{ String: ImageMetadata}
        
        // question: make imageHash and hexSignature [UInt8] and rename hexSig to just signature ?
        pub fun registerImage(imageHash: String, hexSignature: String, metadata: ImageMetadata){ 
            pre{ 
                (self.owner!).address == self.creator:
                    "collection is not owned by creator"
                Veriphoto.accountRegistry[self.creator]! == true:
                    "account has been invalidated"
                metadata.blockTimestamp == nil:
                    "metadata.blockTimestamp has already been set"
            }
            
            // verify image signature
            let creatorKey: PublicKey = (getAccount(self.creator).keys.get(keyIndex: 0)!).publicKey
            let isSignatureValid = creatorKey.verify(signature: hexSignature.decodeHex(), signedData: imageHash.utf8, domainSeparationTag: "", hashAlgorithm: HashAlgorithm.SHA3_256)
            assert(isSignatureValid, message: "invalid signature")
            metadata.setBlockTimestamp()
            self.imageMetadata.insert(key: imageHash, metadata)
            emit ImageRegistered(imageHash: imageHash, owner: (self.owner!).address, metadata: metadata)
        }
        
        pub fun deregisterImage(imageHash: String){ 
            pre{ 
                (self.owner!).address == self.creator:
                    "collection is not owned by creator"
                Veriphoto.accountRegistry[self.creator]! == true:
                    "account has been invalidated"
            }
            self.imageMetadata.remove(key: imageHash)
        }
        
        pub fun verifyImage(imageHash: String): Bool{ 
            pre{ 
                (self.owner!).address == self.creator:
                    "collection is not owned by creator"
                Veriphoto.accountRegistry[self.creator]! == true:
                    "account has been invalidated"
            }
            return self.imageMetadata.containsKey(imageHash)
        }
        
        pub fun getImageMetadata(imageHash: String): ImageMetadata?{ 
            pre{ 
                (self.owner!).address == self.creator:
                    "collection is not owned by creator"
                Veriphoto.accountRegistry[self.creator]! == true:
                    "account has been invalidated"
            }
            return self.imageMetadata[imageHash]
        }
        
        init(creator: Address){ 
            self.creator = creator
            self.imageMetadata ={} 
        }
    }
    
    pub fun createEmptyImageHashRecord(
        creator: Address,
        oracleHexSignature: String,
        ownerHexSignature: String
    ): @ImageHashRecord{ 
        pre{ 
            !self.accountRegistry.containsKey(creator):
                "account already registered: ".concat(creator.toString())
        }
        
        // verify oracle signature
        let oracleKey: PublicKey =
            (getAccount(self.oracleAddress).keys.get(keyIndex: 0)!).publicKey
        let isVerificationSignatureValid =
            oracleKey.verify(
                signature: oracleHexSignature.decodeHex(),
                signedData: creator.toString().utf8,
                domainSeparationTag: "",
                hashAlgorithm: HashAlgorithm.SHA3_256
            )
        assert(
            isVerificationSignatureValid,
            message: "invalid oracle signature"
        )
        
        // verify owner signature
        let creatorKey: PublicKey =
            (getAccount(creator).keys.get(keyIndex: 0)!).publicKey
        let isSignatureValid =
            creatorKey.verify(
                signature: ownerHexSignature.decodeHex(),
                signedData: oracleHexSignature.utf8,
                domainSeparationTag: "",
                hashAlgorithm: HashAlgorithm.SHA3_256
            )
        assert(isSignatureValid, message: "invalid owner signature")
        self.accountRegistry.insert(key: creator, true)
        emit ImageHashRecordCreated(creator: creator)
        return <-create ImageHashRecord(creator: creator)
    }
    
    // TODO: move to admin resource (after testing)
    // question: change from oracleAddress to a storable PublicKey? provides more privacy
    access(account) fun updateOracleAddress(newOracle: Address){ 
        self.oracleAddress = newOracle
    }
    
    // TODO: move to admin resource (after testing)
    access(account) fun updateAccountStatus(creator: Address, isValid: Bool){ 
        pre{ 
            self.accountRegistry.containsKey(creator):
                "account not registered: ".concat(creator.toString())
        }
        self.accountRegistry[creator] = isValid
    }
    
    init(){ 
        self.imageHashRecordStoragePath = /storage/veriphotoImageHashRecord
        self
            .imageHashRecordMetadataReaderPath = /private/veriphotoImageHashRecord
        self.imageHashRecordVerifierPath = /public/veriphotoImageHashRecord
        self.accountRegistry ={} 
        self.oracleAddress = self.account.address
    }
}
