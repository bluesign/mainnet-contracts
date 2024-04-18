import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

pub contract betaLilaiNFT: NonFungibleToken, ViewResolver{ 
    /// Total supply of betaLilaiNFTs in existence
    pub var totalSupply: UInt64
    
    /// The event that is emitted when the contract is created
    pub event ContractInitialized()
    
    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)
    
    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)
    
    /// The event that is emitted when the Lilaiputia field of an NFT is updated
    pub event LilaiputiaUpdated(id: UInt64, updater: Address?, newLilaiputiaData: String)
    
    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let MinterStoragePath: StoragePath
    
    /// The core resource that represents a Non Fungible Token.
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver{ 
        /// The unique ID that each NFT has
        pub let id: UInt64
        
        /// Metadata fields
        pub let name: String
        
        pub let description: String
        
        pub let thumbnail: String
        
        priv let royalties: [MetadataViews.Royalty]
        
        priv let metadata:{ String: AnyStruct}
        
        priv var lilaiputia: String // Mutable field for Lilaiputia data
        
        init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}, lilaiputia: String){ // Changed type to String 
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
            self.lilaiputia = lilaiputia
        }
        
        /// Function to update the Lilaiputia field
        pub fun updateLilaiputia(newLilaiputiaData: String){ 
            self.lilaiputia = newLilaiputiaData
            emit LilaiputiaUpdated(id: self.id, updater: self.owner?.address, newLilaiputiaData: newLilaiputiaData)
        }
        
        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type]{ 
            return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
        }
        
        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            switch view{ 
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: "Lilaiputian NFTs", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(editionList)
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(self.royalties)
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("http://www.lilaiputia.com/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(storagePath: betaLilaiNFT.CollectionStoragePath, publicPath: betaLilaiNFT.CollectionPublicPath, providerPath: /private/betaLilaiNFTCollection, publicCollection: Type<&betaLilaiNFT.Collection{betaLilaiNFT.betaLilaiNFTCollectionPublic}>(), publicLinkedType: Type<&betaLilaiNFT.Collection{betaLilaiNFT.betaLilaiNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(), providerLinkedType: Type<&betaLilaiNFT.Collection{betaLilaiNFT.betaLilaiNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(), createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection{ 
                            return <-betaLilaiNFT.createEmptyCollection()
                        })
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "lilaiputia.mypinata.cloud"), mediaType: "image/svg+xml")
                    return MetadataViews.NFTCollectionDisplay(name: "The Lilai Collection", description: "A collection of unique NFTs for the Lilai universe.", externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/lilaipuita")})
                case Type<MetadataViews.Traits>():
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)
                    let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                    let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
                    traitsView.addTrait(fooTrait)
                    return traitsView
            }
            return nil
        }
    }
    
    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface betaLilaiNFTCollectionPublic{ 
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowbetaLilaiNFT(id: UInt64): &betaLilaiNFT.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow betaLilaiNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }
    
    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: betaLilaiNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection{ 
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @betaLilaiNFT.NFT
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
        
        pub fun borrowbetaLilaiNFT(id: UInt64): &betaLilaiNFT.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &betaLilaiNFT.NFT
            }
            return nil
        }
        
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}{ 
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let betaLilaiNFT = nft as! &betaLilaiNFT.NFT
            return betaLilaiNFT as &AnyResource{MetadataViews.Resolver}
        }
        
        destroy(){ 
            destroy self.ownedNFTs
        }
    }
    
    pub fun createEmptyCollection(): @NonFungibleToken.Collection{ 
        return <-create Collection()
    }
    
    pub resource NFTMinter{ 
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], lilaiputiaData: String){ // Updated parameter name for Lilaiputia data 
            let metadata:{ String: AnyStruct} ={} 
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = (recipient.owner!).address
            metadata["foo"] = "bar"
            // Set the Lilaiputia field with the provided data
            let lilaiputia = lilaiputiaData
            var newNFT <- create NFT(id: betaLilaiNFT.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata, lilaiputia: lilaiputia) // Assign the Lilaiputia data directly
            recipient.deposit(token: <-newNFT)
            betaLilaiNFT.totalSupply = betaLilaiNFT.totalSupply + UInt64(1)
        }
    }
    
    pub fun resolveView(_ view: Type): AnyStruct?{ 
        switch view{ 
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(storagePath: betaLilaiNFT.CollectionStoragePath, publicPath: betaLilaiNFT.CollectionPublicPath, providerPath: /private/betaLilaiNFTCollection, publicCollection: Type<&betaLilaiNFT.Collection{betaLilaiNFT.betaLilaiNFTCollectionPublic}>(), publicLinkedType: Type<&betaLilaiNFT.Collection{betaLilaiNFT.betaLilaiNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(), providerLinkedType: Type<&betaLilaiNFT.Collection{betaLilaiNFT.betaLilaiNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(), createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection{ 
                        return <-betaLilaiNFT.createEmptyCollection()
                    })
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "lilaiputia.mypinata.cloud"), mediaType: "image/svg+xml")
                return MetadataViews.NFTCollectionDisplay(name: "The Lilai Collection", description: "A diverse collection of NFTs within the Lilai universe.", externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("hhttps://twitter.com/lilaiputia")})
        }
        return nil
    }
    
    pub fun getViews(): [Type]{ 
        return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
    }
    
    init(){ 
        self.totalSupply = 0
        self.CollectionStoragePath = /storage/betaLilaiNFTCollection
        self.CollectionPublicPath = /public/betaLilaiNFTCollection
        self.MinterStoragePath = /storage/betaLilaiNFTMinter
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        self.account.link<&betaLilaiNFT.Collection{NonFungibleToken.CollectionPublic, betaLilaiNFT.betaLilaiNFTCollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)
        emit ContractInitialized()
    }
}
