import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

/// FlowUp contract to store inscriptions
///
pub contract FlowUp{ 
    pub        /* --- Events --- *//// Event emitted when the contract is initialized
        event ContractInitialized()
    
    pub event              /// Event emitted when a new inscription is created
              InscriptionCreated(
        id: UInt64,
        mimeType: String,
        metadata: [
            UInt8
        ],
        value: UFix64,
        metaProtocol: String?,
        encoding: String?,
        parentId: UInt64?
    )
    
    pub event InscriptionBurned(id: UInt64)
    
    pub event InscriptionExtracted(id: UInt64, value: UFix64)
    
    pub event InscriptionFused(from: UInt64, to: UInt64, value: UFix64)
    
    pub event InscriptionArchived(id: UInt64)
    
    /* --- Variable, Enums and Structs --- */    pub var totalInscriptions: UInt64
    
    /* --- Interfaces & Resources --- *//// The rarity of a Inscription value
    ///
    pub enum ValueRarity: UInt8{ 
        pub case Common
        
        pub case Uncommon
        
        pub case Rare
        
        pub case SuperRare
        
        pub case Epic
        
        pub case Legendary
    }
    
    /// The data of an inscription
    ///
    pub struct InscriptionData{ 
        pub            /// whose value is the MIME type of the inscription
            let mimeType: String
        
        /// The metadata content of the inscription
        pub let metadata: [UInt8]
        
        /// The protocol used to encode the metadata
        pub let metaProtocol: String?
        
        /// The encoding used to encode the metadata
        pub let encoding: String?
        
        /// The timestamp of the inscription
        pub let createdAt: UFix64
        
        init(
            _ mimeType: String,
            _ metadata: [
                UInt8
            ],
            _ metaProtocol: String?,
            _ encoding: String?
        ){ 
            self.mimeType = mimeType
            self.metadata = metadata
            self.metaProtocol = metaProtocol
            self.encoding = encoding
            self.createdAt = getCurrentBlock().timestamp
        }
    }
    
    /// The metadata view for FlowUp Inscription
    ///
    pub struct InscriptionView{ 
        pub let id: UInt64
        
        pub let parentId: UInt64?
        
        pub let data: FlowUp.InscriptionData
        
        pub let value: UFix64
        
        pub let extractable: Bool
        
        init(
            id: UInt64,
            parentId: UInt64?,
            data: FlowUp.InscriptionData,
            value: UFix64,
            extractable: Bool
        ){ 
            self.id = id
            self.parentId = parentId
            self.data = data
            self.value = value
            self.extractable = extractable
        }
    }
    
    /// The public interface to the inscriptions
    ///
    pub resource interface InscriptionPublic{ 
        pub            // identifiers
            fun getId(): UInt64{} 
        
        pub fun getParentId(): UInt64?{} 
        
        // data
        pub fun getData(): InscriptionData{} 
        
        pub fun getMimeType(): String{} 
        
        pub fun getMetadata(): [UInt8]{} 
        
        pub fun getMetaProtocol(): String?{} 
        
        pub fun getContentEncoding(): String?{} 
        
        // attributes
        pub fun getMinCost(): UFix64{} 
        
        pub fun getInscriptionValue(): UFix64{} 
        
        pub fun getInscriptionRarity(): ValueRarity{} 
        
        pub fun isExtracted(): Bool{} 
        
        pub fun isExtractable(): Bool{} 
    }
    
    /// The resource that stores the inscriptions
    ///
    pub resource Inscription: InscriptionPublic, MetadataViews.Resolver{ 
        /// the id of the inscription
        priv let id: UInt64
        
        /// the id of the parent inscription
        priv let parentId: UInt64?
        
        /// the data of the inscription
        priv let data: InscriptionData
        
        /// the inscription value
        priv var value: @FlowToken.Vault?
        
        init(value: @FlowToken.Vault, mimeType: String, metadata: [UInt8], metaProtocol: String?, encoding: String?, parentId: UInt64?){ 
            post{ 
                self.isValueValid():
                    "Inscription value should be bigger than minimium $FLOW at least."
            }
            self.id = FlowUp.totalInscriptions
            FlowUp.totalInscriptions = FlowUp.totalInscriptions + 1
            self.parentId = parentId
            self.data = InscriptionData(mimeType, metadata, metaProtocol, encoding)
            self.value <- value
        }
        
        destroy(){ 
            destroy self.value
            emit InscriptionBurned(id: self.id)
        }
        
        /** ------ Functionality ------  *//// Check if the inscription is extracted
        ///
        pub fun isExtracted(): Bool{ 
            return self.value == nil
        }
        
        /// Check if the inscription is not extracted and has an owner
        ///
        pub fun isExtractable(): Bool{ 
            return !self.isExtracted() && self.owner != nil
        }
        
        /// Check if the inscription value is valid
        ///
        pub fun isValueValid(): Bool{ 
            return self.value?.balance ?? panic("No value") >= self.getMinCost()
        }
        
        /// Fuse the inscription with another inscription
        ///
        pub fun fuse(_ other: @Inscription){ 
            pre{ 
                !self.isExtracted():
                    "Inscription already extracted"
            }
            let otherValue <- other.extract()
            let from = other.getId()
            let fusedValue = otherValue.balance
            destroy other
            let selfValue = (&self.value as &FlowToken.Vault?)!
            selfValue.deposit(from: <-otherValue)
            emit InscriptionFused(from: from, to: self.getId(), value: fusedValue)
        }
        
        /// Extract the inscription value
        ///
        pub fun extract(): @FlowToken.Vault{ 
            pre{ 
                !self.isExtracted():
                    "Inscription already extracted"
            }
            post{ 
                self.isExtracted():
                    "Inscription not extracted"
            }
            let balance = self.value?.balance ?? panic("No value")
            let res <- self.value <- nil
            emit InscriptionExtracted(id: self.id, value: balance)
            return <-res!
        }
        
        /// Extract a part of the inscription value, but keep the inscription be not extracted
        ///
        pub fun partialExtract(_ amount: UFix64): @FlowToken.Vault{ 
            pre{ 
                !self.isExtracted():
                    "Inscription already extracted"
            }
            post{ 
                self.isValueValid():
                    "Inscription value should be bigger than minimium $FLOW at least."
                !self.isExtracted():
                    "Inscription should not be extracted"
            }
            let ret <- self.value?.withdraw(amount: amount) ?? panic("No value")
            assert(ret.balance == amount, message: "Returned value should be equal to the amount")
            emit InscriptionExtracted(id: self.id, value: amount)
            return <-(ret as! @FlowToken.Vault)
        }
        
        /// Get the minimum value of the inscription
        ///
        pub fun getMinCost(): UFix64{ 
            let data = self.data
            return FlowUp.estimateValue(index: self.getId(), mimeType: data.mimeType, data: data.metadata, protocol: data.metaProtocol, encoding: data.encoding)
        }
        
        /// Get the value of the inscription
        ///
        pub fun getInscriptionValue(): UFix64{ 
            return self.value?.balance ?? 0.0
        }
        
        /// Get the rarity of the inscription
        ///
        pub fun getInscriptionRarity(): ValueRarity{ 
            let value = self.value?.balance ?? 0.0
            if value <= 0.1{ // 0.001 ~ 0.1 
                return ValueRarity.Common
            } else if value <= 10.0{ // 0.1 ~ 10 
                return ValueRarity.Uncommon
            } else if value <= 1000.0{ // 10 ~ 1000 
                return ValueRarity.Rare
            } else if value <= 10000.0{ // 1000 ~ 10000 
                return ValueRarity.SuperRare
            } else if value <= 100000.0{ // 10000 ~ 100000 
                return ValueRarity.Epic
            } else{ // 100000 ~ 
                return ValueRarity.Legendary
            }
        }
        
        /** ---- Implementation of InscriptionPublic ---- */        pub fun getId(): UInt64{ 
            return self.id
        }
        
        pub fun getParentId(): UInt64?{ 
            return self.parentId
        }
        
        pub fun getData(): InscriptionData{ 
            return self.data
        }
        
        pub fun getMimeType(): String{ 
            return self.data.mimeType
        }
        
        pub fun getMetadata(): [UInt8]{ 
            return self.data.metadata
        }
        
        pub fun getMetaProtocol(): String?{ 
            return self.data.metaProtocol
        }
        
        pub fun getContentEncoding(): String?{ 
            return self.data.encoding
        }
        
        /** ---- Implementation of MetadataViews.Resolver ---- */        pub fun getViews(): [Type]{ 
            return [Type<FlowUp.InscriptionView>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Rarity>(), Type<MetadataViews.Traits>()]
        }
        
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            let rarity = self.getInscriptionRarity()
            let ratityView = MetadataViews.Rarity(UFix64(rarity.rawValue), UFix64(ValueRarity.Legendary.rawValue), nil)
            let mimeType = self.getMimeType()
            let metadata = self.getMetadata()
            let encoding = self.getContentEncoding()
            let isUTF8 = encoding == "utf8" || encoding == "utf-8" || encoding == nil
            let fileView = MetadataViews.HTTPFile(url: "data:".concat(mimeType).concat(";").concat(isUTF8 ? "utf8;charset=UTF-8" : encoding!).concat(",").concat(isUTF8 ? String.fromUTF8(metadata)! : encoding == "hex" ? String.encodeHex(metadata) : ""))
            switch view{ 
                case Type<FlowUp.InscriptionView>():
                    return FlowUp.InscriptionView(id: self.getId(), parentId: self.getParentId(), data: self.getData(), value: self.getInscriptionValue(), extractable: self.isExtractable())
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.getId())
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(name: "FlowUp Inscription #".concat(self.getId().toString()), description: "FlowUp is a decentralized protocol to store and exchange inscriptions.", thumbnail: fileView)
                case Type<MetadataViews.Medias>():
                    return MetadataViews.Medias([MetadataViews.Media(file: fileView, mediaType: mimeType)])
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://flowup.world/")
                case Type<MetadataViews.Rarity>():
                    return ratityView
                case Type<MetadataViews.Traits>():
                    return MetadataViews.Traits([MetadataViews.Trait(name: "id", value: self.getId(), nil, nil), MetadataViews.Trait(name: "mimeType", value: self.getMimeType(), nil, nil), MetadataViews.Trait(name: "metaProtocol", value: self.getMetaProtocol(), nil, nil), MetadataViews.Trait(name: "encoding", value: self.getContentEncoding(), nil, nil), MetadataViews.Trait(name: "rarity", value: rarity.rawValue, nil, ratityView)])
            }
            return nil
        }
    }
    
    pub resource interface ArchivedInscriptionsPublic{ 
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowInscription(_ id: UInt64): &FlowUp.Inscription{
            FlowUp.InscriptionPublic
        }?{} 
    }
    
    /// The resource that stores the archived inscriptions
    ///
    pub resource ArchivedInscriptions{ 
        priv let inscriptions: @{UInt64: FlowUp.Inscription}
        
        init(){ 
            self.inscriptions <-{} 
        }
        
        destroy(){ 
            destroy self.inscriptions
        }
        
        // --- Public Methods ---
        
        pub fun getIDs(): [UInt64]{ 
            return self.inscriptions.keys
        }
        
        pub fun borrowInscription(_ id: UInt64): &FlowUp.Inscription{
            FlowUp.InscriptionPublic
        }?{ 
            return self.borrowInscriptionWritableRef(id)
        }
        
        // --- Private Methods ---
        
        pub fun archive(_ ins: @FlowUp.Inscription){ 
            pre{ 
                ins.isExtracted():
                    "Inscription should be extracted"
            }
            // inscription id should be unique
            let id = ins.getId()
            let old <- self.inscriptions.insert(key: id, <-ins)
            emit InscriptionArchived(id: id)
            destroy old
        }
        
        pub fun borrowInscriptionWritableRef(
            _ id: UInt64
        ): &FlowUp.Inscription?{ 
            return &self.inscriptions[id] as &FlowUp.Inscription?
        }
    }
    
    /* --- Methods --- *//// Create a new inscription
    ///
    pub fun createInscription(
        value: @FlowToken.Vault,
        mimeType: String,
        metadata: [
            UInt8
        ],
        metaProtocol: String?,
        encoding: String?,
        parentId: UInt64?
    ): @Inscription{ 
        let bal = value.balance
        let ins <-
            create Inscription(
                value: <-value,
                mimeType: mimeType,
                metadata: metadata,
                metaProtocol: metaProtocol,
                encoding: encoding,
                parentId: parentId
            )
        // emit event
        emit InscriptionCreated(
            id: ins.getId(),
            mimeType: ins.getMimeType(),
            metadata: ins.getMetadata(),
            value: bal,
            metaProtocol: ins.getMetaProtocol(),
            encoding: ins.getContentEncoding(),
            parentId: ins.getParentId()
        )
        return <-ins
    }
    
    pub fun estimateValue(
        index: UInt64,
        mimeType: String,
        data: [
            UInt8
        ],
        protocol: String?,
        encoding: String?
    ): UFix64{ 
        let currIdxValue = UFix64(index / UInt64(UInt8.max) + 1)
        let maxIdxValue = 1000.0
        let estimatedIndexValue =
            currIdxValue < maxIdxValue ? currIdxValue : maxIdxValue
        let bytes =
            UFix64(
                (
                    mimeType.length + (protocol != nil ? (protocol!).length : 0)
                    + (encoding != nil ? (encoding!).length : 0)
                )
                * 3
            )
            + UFix64(data.length)
            + estimatedIndexValue
        return bytes * 0.0002
    }
    
    /// Get the storage path of a inscription
    ///
    pub fun getFlowUpStoragePath(index: UInt64): StoragePath{ 
        let prefix = "FlowUp_".concat(self.account.address.toString())
        return StoragePath(
            identifier: prefix.concat("_").concat(index.toString())
        )!
    }
    
    pub fun getArchivedFlowUpStoragePath(): StoragePath{ 
        let prefix = "FlowUp_".concat(self.account.address.toString())
        return StoragePath(identifier: prefix.concat("_archived"))!
    }
    
    init(){ 
        self.totalInscriptions = 0
        emit ContractInitialized()
    }
}
