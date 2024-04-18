import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract QuestReward: NonFungibleToken{ 
    
    // -----------------------------------------------------------------------
    // NonFungibleToken Standard Events
    // -----------------------------------------------------------------------
    pub event ContractInitialized()
    
    pub event Withdraw(id: UInt64, from: Address?)
    
    pub event Deposit(id: UInt64, to: Address?)
    
    // -----------------------------------------------------------------------
    // Contract Events
    // -----------------------------------------------------------------------
    pub event Minted(id: UInt64, minterID: UInt64, rewardTemplateID: UInt32, rewardTemplate: RewardTemplate, minterAddress: Address?)
    
    pub event RewardTemplateAdded(minterID: UInt64, minterAddress: Address?, rewardTemplateID: UInt32, name: String, description: String, image: String)
    
    pub event RewardTemplateUpdated(minterID: UInt64, minterAddress: Address?, rewardTemplateID: UInt32, name: String, description: String, image: String)
    
    // -----------------------------------------------------------------------
    // Named Paths
    // -----------------------------------------------------------------------
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let CollectionPrivatePath: PrivatePath
    
    // -----------------------------------------------------------------------
    // Contract Fields
    // -----------------------------------------------------------------------
    pub var totalSupply: UInt64
    
    pub var rewardTemplateSupply: UInt32
    
    pub var minterSupply: UInt64
    
    priv var numberMintedPerRewardTemplate:{ UInt32: UInt64}
    
    // -----------------------------------------------------------------------
    // Future Contract Extensions
    // -----------------------------------------------------------------------
    priv var metadata:{ String: AnyStruct}
    
    priv var resources: @{String: AnyResource}
    
    pub struct RewardTemplate{ 
        pub let minterID: UInt64
        
        pub let id: UInt32
        
        pub let name: String
        
        pub let description: String
        
        pub let image: String
        
        init(minterID: UInt64, id: UInt32, name: String, description: String, image: String){ 
            self.minterID = minterID
            self.id = id
            self.name = name
            self.description = description
            self.image = image
        }
    }
    
    pub resource interface Public{ 
        pub let id: UInt64
        
        pub let minterID: UInt64
        
        pub let rewardTemplateID: UInt32
        
        pub let dateMinted: UFix64
        
        pub var revealed: Bool
    }
    
    pub resource NFT: Public, NonFungibleToken.INFT{ 
        pub let id: UInt64
        
        pub let minterID: UInt64
        
        pub let rewardTemplateID: UInt32
        
        pub let dateMinted: UFix64
        
        pub var revealed: Bool
        
        priv var metadata:{ String: AnyStruct}
        
        priv var resources: @{String: AnyResource}
        
        init(minterID: UInt64, rewardTemplateID: UInt32, rewardTemplate: RewardTemplate, minterAddress: Address?){ 
            self.id = self.uuid
            self.minterID = minterID
            self.rewardTemplateID = rewardTemplateID
            self.dateMinted = getCurrentBlock().timestamp
            self.revealed = false
            self.metadata ={} 
            self.resources <-{} 
            QuestReward.totalSupply = QuestReward.totalSupply + 1
            QuestReward.numberMintedPerRewardTemplate[rewardTemplateID] = QuestReward.numberMintedPerRewardTemplate[rewardTemplateID]! + 1
            emit Minted(id: self.id, minterID: self.minterID, rewardTemplateID: self.rewardTemplateID, rewardTemplate: rewardTemplate, minterAddress: minterAddress)
        }
        
        pub fun reveal(){ 
            self.revealed = true
        }
        
        destroy(){ 
            destroy self.resources
        }
    }
    
    pub resource interface CollectionPublic{ 
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowQuestReward(id: UInt64): &QuestReward.NFT{Public}?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow QuestReward reference: The ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic{ 
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw QuestReward from Collection: Missing NFT")
            emit Withdraw(id: withdrawID, from: self.owner?.address)
            return <-token
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @QuestReward.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        pub fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{ 
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
        
        pub fun borrowQuestReward(id: UInt64): &QuestReward.NFT{Public}?{ 
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return (ref as! &QuestReward.NFT{Public}?)!
        }
        
        pub fun borrowEntireQuestReward(id: UInt64): &QuestReward.NFT?{ 
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return (ref as! &QuestReward.NFT?)!
        }
        
        destroy(){ 
            destroy self.ownedNFTs
        }
    }
    
    pub resource interface MinterPublic{ 
        pub let id: UInt64
        
        pub let name: String
        
        pub fun getRewardTemplate(id: UInt32): RewardTemplate?{} 
        
        pub fun getRewardTemplates():{ UInt32: RewardTemplate}{} 
    }
    
    pub resource Minter: MinterPublic{ 
        pub let id: UInt64
        
        pub let name: String
        
        priv var rewardTemplates:{ UInt32: RewardTemplate}
        
        priv var metadata:{ String: AnyStruct}
        
        priv var resources: @{String: AnyResource}
        
        init(name: String){ 
            self.id = QuestReward.minterSupply
            self.name = name
            self.rewardTemplates ={} 
            self.metadata ={} 
            self.resources <-{} 
            QuestReward.minterSupply = QuestReward.minterSupply + 1
        }
        
        pub fun mintReward(rewardTemplateID: UInt32): @NFT{ 
            pre{ 
                self.rewardTemplates[rewardTemplateID] != nil:
                    "Reward Template does not exist"
            }
            return <-create NFT(minterID: self.id, rewardTemplateID: rewardTemplateID, rewardTemplate: self.getRewardTemplate(id: rewardTemplateID)!, minterAddress: self.owner?.address)
        }
        
        pub fun addRewardTemplate(name: String, description: String, image: String){ 
            let id: UInt32 = QuestReward.rewardTemplateSupply
            self.rewardTemplates[id] = RewardTemplate(minterID: self.id, id: id, name: name, description: description, image: image)
            QuestReward.rewardTemplateSupply = QuestReward.rewardTemplateSupply + 1
            QuestReward.numberMintedPerRewardTemplate[id] = 0
            emit RewardTemplateAdded(minterID: self.id, minterAddress: self.owner?.address, rewardTemplateID: id, name: name, description: description, image: image)
        }
        
        pub fun updateRewardTemplate(id: UInt32, name: String, description: String, image: String){ 
            pre{ 
                self.rewardTemplates[id] != nil:
                    "Reward Template does not exist"
            }
            self.rewardTemplates[id] = RewardTemplate(minterID: self.id, id: id, name: name, description: description, image: image)
            emit RewardTemplateUpdated(minterID: self.id, minterAddress: self.owner?.address, rewardTemplateID: id, name: name, description: description, image: image)
        }
        
        pub fun getRewardTemplate(id: UInt32): RewardTemplate?{ 
            return self.rewardTemplates[id]
        }
        
        pub fun getRewardTemplates():{ UInt32: RewardTemplate}{ 
            return self.rewardTemplates
        }
        
        destroy(){ 
            destroy self.resources
        }
    }
    
    pub fun createEmptyCollection(): @NonFungibleToken.Collection{ 
        return <-create Collection()
    }
    
    pub fun createMinter(name: String): @Minter{ 
        return <-create Minter(name: name)
    }
    
    pub fun getNumberMintedPerRewardTemplateKeys(): [UInt32]{ 
        return self.numberMintedPerRewardTemplate.keys
    }
    
    pub fun getNumberMintedPerRewardTemplate(id: UInt32): UInt64?{ 
        return self.numberMintedPerRewardTemplate[id]
    }
    
    pub fun getNumberMintedPerRewardTemplates():{ UInt32: UInt64}{ 
        return self.numberMintedPerRewardTemplate
    }
    
    init(){ 
        self.CollectionStoragePath = /storage/WonderlandQuestRewardCollection_2
        self.CollectionPublicPath = /public/WonderlandQuestRewardCollection_2
        self.CollectionPrivatePath = /private/WonderlandQuestRewardCollection_2
        self.totalSupply = 0
        self.rewardTemplateSupply = 0
        self.minterSupply = 0
        self.numberMintedPerRewardTemplate ={} 
        self.metadata ={} 
        self.resources <-{} 
        emit ContractInitialized()
    }
}
