import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract DoodlePackTypes{ 
    pub event ContractInitialized()
    
    pub event PackTypeRegistered(id: UInt64)
    
    pub var totalSupply: UInt64
    
    access(contract) let packTypes:{ UInt64: PackType}
    
    // Number of times a pack type has been minted
    pub var packTypesMintedCount:{ UInt64: UInt64} // packTypeId => mintedCount
    
    // Number of times a template distribution has been minted
    pub var templateDistributionsMintedCount:{ UInt64:{ UInt64: UInt64}} // packTypeId => templateDistributionId => mintedCount
    
    priv let extra:{ String: AnyStruct}
    
    pub enum Collection: UInt8{ 
        pub case Wearables
        
        pub case Redeemables
    }
    
    pub struct PackType{ 
        pub let id: UInt64
        
        // Number of tokens that should be minted per pack
        pub let amountOfTokens: UInt8
        
        pub var name: String
        
        pub var description: String
        
        pub var thumbnail: MetadataViews.Media
        
        pub var image: MetadataViews.Media
        
        pub var templateDistributions: [TemplateDistribution]
        
        // Max amount of packs that can be minted
        pub var maxSupply: UInt64?
        
        priv let extra:{ String: AnyStruct}
        
        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: MetadataViews.Media,
            image: MetadataViews.Media,
            amountOfTokens: UInt8,
            templateDistributions: [
                TemplateDistribution
            ],
            maxSupply: UInt64?
        ){ 
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.image = image
            self.amountOfTokens = amountOfTokens
            self.templateDistributions = templateDistributions
            self.maxSupply = maxSupply
            self.extra ={} 
            DoodlePackTypes.totalSupply = DoodlePackTypes.totalSupply + 1
            
            // If there is a limited amount of packs to be minted,
            // validate that each distribution has a max mint amount of templates
            // and that the sum of all max mint amounts is equal to the total packs max supply,
            // multiplied by the amount of tokens in each pack.
            if maxSupply != nil{ 
                var totalMaxMint: UInt64 = 0
                for templateDistribution in templateDistributions{ 
                    if templateDistribution.maxMint == nil{ 
                        panic("Can't have unlimited mints in a distribution if the pack type has a limited supply")
                    }
                    totalMaxMint = totalMaxMint + templateDistribution.maxMint!
                }
                if totalMaxMint != maxSupply! * UInt64(amountOfTokens){ 
                    panic("Total max mint must be equal to max supply multiplied by amount of tokens")
                }
            }
        }
    }
    
    access(contract) fun validateTemplateDistributions(
        amountOfTokens: UInt8,
        templateDistributions: [
            TemplateDistribution
        ]
    ){ 
        pre{ 
            amountOfTokens > 0:
                "Amount of tokens must be greater than 0"
            templateDistributions.length > 0:
                "Template distributions must be greater than 0"
        }
        var minAmount: UInt8 = 0
        var maxAmount: UInt8 = 0
        for templateDistribution in templateDistributions{ 
            minAmount = minAmount + templateDistribution.minAmount
            maxAmount = maxAmount + templateDistribution.maxAmount
        }
        if amountOfTokens < minAmount{ 
            panic("Amount of tokens must be greater than or equal to total min amount")
        }
        if amountOfTokens > maxAmount{ 
            panic("Amount of tokens must be less than or equal to total max amount")
        }
        var totalProbability: UFix64 = 0.0
        for templateDistribution in templateDistributions{ 
            for templateProbability in templateDistribution.templateProbabilities{ 
                totalProbability = totalProbability + templateProbability.probability
            }
        }
        if totalProbability != 1.0{ 
            panic("Total probability must be 1.0 but is ".concat(totalProbability.toString()))
        }
    }
    
    pub struct TemplateDistribution{ 
        pub let id: UInt64
        
        pub var templateProbabilities: [TemplateProbability]
        
        // Min amount of tokens in this distribution that must be minted in a single pack
        pub var minAmount: UInt8
        
        // Max amount of tokens in this distribution that can be minted in a single pack
        pub var maxAmount: UInt8
        
        // Max amount of tokens in this distribution that can be minted across all packs
        pub var maxMint: UInt64?
        
        priv let extra:{ String: AnyStruct}
        
        init(
            id: UInt64,
            templateProbabilities: [
                TemplateProbability
            ],
            minAmount: UInt8,
            maxAmount: UInt8,
            maxMint: UInt64?
        ){ 
            pre{ 
                templateProbabilities.length > 0:
                    "Template probabilities must be greater than 0"
                maxAmount > 0:
                    "Max amount must be greater than 0"
                maxAmount >= minAmount:
                    "Max amount must be greater than or equal to min amount"
                maxMint == nil || maxMint! > 0:
                    "Max mint must be greater than 0"
            }
            self.id = id
            self.templateProbabilities = templateProbabilities
            self.minAmount = minAmount
            self.maxAmount = maxAmount
            self.maxMint = maxMint
            self.extra ={} 
        }
    }
    
    pub struct TemplateProbability{ 
        pub let collection: Collection
        
        pub let templateId: UInt64
        
        pub let probability: UFix64
        
        priv let extra:{ String: AnyStruct}
        
        init(collection: Collection, templateId: UInt64, probability: UFix64){ 
            self.collection = collection
            self.templateId = templateId
            self.probability = probability
            self.extra ={} 
        }
    }
    
    pub fun getPackType(id: UInt64): DoodlePackTypes.PackType?{ 
        return self.packTypes[id]
    }
    
    pub fun getPackTypes(): [DoodlePackTypes.PackType]{ 
        return self.packTypes.values
    }
    
    access(account) fun addPackType(
        id: UInt64,
        name: String,
        description: String,
        thumbnail: MetadataViews.Media,
        image: MetadataViews.Media,
        amountOfTokens: UInt8,
        templateDistributions: [
            TemplateDistribution
        ],
        maxSupply: UInt64?
    ): DoodlePackTypes.PackType{ 
        pre{ 
            name.length > 0:
                "Name must be greater than 0"
            description.length > 0:
                "Description must be greater than 0"
            amountOfTokens > 0:
                "Amount of tokens must be greater than 0"
            templateDistributions.length > 0:
                "Template distributions must be greater than 0"
        }
        DoodlePackTypes.validateTemplateDistributions(
            amountOfTokens: amountOfTokens,
            templateDistributions: templateDistributions
        )
        let packType =
            PackType(
                id: id,
                name: name,
                description: description,
                thumbnail: thumbnail,
                image: image,
                amountOfTokens: amountOfTokens,
                templateDistributions: templateDistributions,
                maxSupply: maxSupply
            )
        emit PackTypeRegistered(id: id)
        DoodlePackTypes.packTypes[id] = packType
        return packType
    }
    
    access(account) fun addMintedCountToPackType(
        typeId: UInt64,
        amount: UInt64
    ){ 
        if DoodlePackTypes.packTypes[typeId] == nil{ 
            panic("No pack type found")
        }
        DoodlePackTypes.packTypesMintedCount[typeId] = DoodlePackTypes
                .getPackTypesMintedCount(typeId: typeId)
            + 1
    }
    
    access(account) fun addMintedCountToTemplateDistribution(
        typeId: UInt64,
        templateDistributionId: UInt64,
        amount: UInt64
    ){ 
        let packType: DoodlePackTypes.PackType =
            DoodlePackTypes.packTypes[typeId] ?? panic("No pack type found")
        if packType.templateDistributions[templateDistributionId] == nil{ 
            panic("No template distribution found")
        }
        let templateDistributionsMintedCount =
            DoodlePackTypes.templateDistributionsMintedCount[typeId] ??{} 
        templateDistributionsMintedCount[templateDistributionId] = (
                templateDistributionsMintedCount[templateDistributionId] ?? 0
            )
            + 1
        DoodlePackTypes.templateDistributionsMintedCount[
            typeId
        ] = templateDistributionsMintedCount
    }
    
    pub fun getPackTypesMintedCount(typeId: UInt64): UInt64{ 
        return DoodlePackTypes.packTypesMintedCount[typeId] ?? 0
    }
    
    pub fun getTemplateDistributionMintedCount(
        typeId: UInt64,
        templateDistributionId: UInt64
    ): UInt64{ 
        let templateDistributionsMintedCount =
            DoodlePackTypes.templateDistributionsMintedCount[typeId] ??{} 
        return templateDistributionsMintedCount[templateDistributionId] ?? 0
    }
    
    init(){ 
        self.totalSupply = 0
        self.packTypes ={} 
        self.packTypesMintedCount ={} 
        self.templateDistributionsMintedCount ={} 
        self.extra ={} 
        emit ContractInitialized()
    }
}
