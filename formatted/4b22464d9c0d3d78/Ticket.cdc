import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

import ViewResolver from "./ViewResolver.cdc"

pub contract Ticket: NonFungibleToken, ViewResolver{ 
    
    /// Total supply of TicketNFTs in existence
    pub var totalSupply: UInt64
    
    /// The event that is emitted when the contract is created
    pub event ContractInitialized()
    
    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)
    
    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)
    
    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let MinterStoragePath: StoragePath
    
    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver{ 
        
        /// The unique ID that each NFT has
        pub let id: UInt64
        
        /// Metadata fields
        pub let name: String
        
        pub let description: String
        
        pub let thumbnail: String
        
        priv let royalties: [MetadataViews.Royalty]
        
        priv let metadata:{ String: AnyStruct}
        
        init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
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
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "METAnMEMORY NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(editionList)
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(self.royalties)
                case Type<MetadataViews.ExternalURL>():
                    //return MetadataViews.ExternalURL("https://n.bayeasy.cn/".concat(self.id.toString()))
                    return MetadataViews.ExternalURL("http://www.metanmemory.com:11880/")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(storagePath: Ticket.CollectionStoragePath, publicPath: Ticket.CollectionPublicPath, providerPath: /private/ticketCollection, publicCollection: Type<&Ticket.Collection{Ticket.TicketCollectionPublic}>(), publicLinkedType: Type<&Ticket.Collection{Ticket.TicketCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(), providerLinkedType: Type<&Ticket.Collection{Ticket.TicketCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(), createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection{ 
                            return <-Ticket.createEmptyCollection()
                        })
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media: MetadataViews.Media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://image.bayeasy.cn/images-datas/nft/mnm.jpg"), mediaType: "image/png")
                    return MetadataViews.NFTCollectionDisplay(name: "METAnMEMORY", description: "METAnMEMORY\u{6570}\u{5b57}\u{85cf}\u{54c1}SaaS\u{6280}\u{672f}\u{670d}\u{52a1}\u{ff0c}\u{63d0}\u{4f9b}\u{4ee5}\u{6570}\u{5b57}\u{85cf}\u{54c1}\u{53ca}\u{533a}\u{5757}\u{94fe}\u{6280}\u{672f}\u{7684}SaaS\u{8d4b}\u{80fd}\u{670d}\u{52a1}\u{ff0c}\u{6253}\u{9020}\u{5bcc}\u{6709}\u{5a31}\u{4e50}\u{6027}\u{3001}\u{6536}\u{85cf}\u{6027}\u{53ca}\u{5b9e}\u{9645}\u{4e1a}\u{52a1}\u{4ef7}\u{503c}\u{7684}NFT\u{4ea7}\u{54c1}\u{5f62}\u{6001}\u{ff0c}\u{4e3a}\u{4f01}\u{4e1a}\u{5e02}\u{573a}\u{589e}\u{52a0}\u{65b0}\u{7684}\u{8425}\u{9500}\u{89e6}\u{70b9}\u{3002}\u{901a}\u{8fc7}\u{533a}\u{5757}\u{94fe}\u{6280}\u{672f}\u{5b9e}\u{73b0}\u{4e86}IP\u{5546}\u{4e1a}\u{4ef7}\u{503c}\u{7684}\u{591a}\u{5143}\u{5f00}\u{53d1}\u{ff0c}\u{8fdb}\u{4e00}\u{6b65}\u{62d3}\u{5c55}\u{4e86}\u{573a}\u{666f}\u{5e94}\u{7528}\u{7684}\u{5546}\u{4e1a}\u{8fb9}\u{754c}\u{ff0c}\u{8d4b}\u{4e88}\u{4e86}\u{5e02}\u{573a}\u{66f4}\u{5927}\u{7684}\u{60f3}\u{8c61}\u{7a7a}\u{95f4}\u{3002}", externalURL: MetadataViews.ExternalURL("http://www.metanmemory.com:11880/"), squareImage: media, bannerImage: media, socials:{} )
                //"twitter": MetadataViews.ExternalURL("https://n.bayeasy.cn/")
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView: MetadataViews.Traits = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
                    
                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)
                    
                    // foo is a trait with its own rarity
                    //let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                    //let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
                    //traitsView.addTrait(fooTrait)
                    
                    return traitsView
            }
            return nil
        }
    }
    
    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface TicketCollectionPublic{ 
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowTicket(id: UInt64): &Ticket.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Ticket reference: the ID of the returned reference is incorrect"
            }
        }
    }
    
    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: TicketCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection{ 
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @Ticket.NFT
            let id: UInt64 = token.id
            
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }
        
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{ 
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
        
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowTicket(id: UInt64): &Ticket.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Ticket.NFT
            }
            return nil
        }
        
        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}{ 
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ticket = nft as! &Ticket.NFT
            return ticket as &AnyResource{MetadataViews.Resolver}
        }
        
        destroy(){ 
            destroy self.ownedNFTs
        }
    }
    
    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection{ 
        return <-create Collection()
    }
    
    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    pub resource NFTMinter{ 
        
        /// Mints a new NFT with a new ID and deposit it in the
        /// recipients collection using their collection reference
        ///
        /// @param recipient: A capability to the collection where the new NFT will be deposited
        /// @param name: The name for the NFT metadata
        /// @param description: The description for the NFT metadata
        /// @param thumbnail: The thumbnail for the NFT metadata
        /// @param royalties: An array of Royalty structs, see MetadataViews docs 
        ///     
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], extraAttr: [String]){ 
            let metadata:{ String: AnyStruct} ={} 
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = (recipient.owner!).address
            metadata["extraAttr"] = extraAttr
            
            // this piece of metadata will be used to show embedding rarity into a trait
            // metadata["foo"] = "bar"
            
            
            // create a new NFT
            var newNFT <- create NFT(id: Ticket.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata)
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
            Ticket.totalSupply = Ticket.totalSupply + UInt64(1)
        }
    }
    
    /// Allows anyone to create a new NFTMinter resource
    pub fun createMintNFT(): @Ticket.NFTMinter{ 
        return <-create NFTMinter()
    }
    
    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct?{ 
        switch view{ 
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(storagePath: Ticket.CollectionStoragePath, publicPath: Ticket.CollectionPublicPath, providerPath: /private/ticketCollection, publicCollection: Type<&Ticket.Collection{Ticket.TicketCollectionPublic}>(), publicLinkedType: Type<&Ticket.Collection{Ticket.TicketCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(), providerLinkedType: Type<&Ticket.Collection{Ticket.TicketCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(), createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection{ 
                        return <-Ticket.createEmptyCollection()
                    })
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://image.bayeasy.cn/images-datas/nft/mnm.jpg"), mediaType: "image/png")
        }
        return nil
    }
    
    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type]{ 
        return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
    }
    
    init(){ 
        // Initialize the total supply
        self.totalSupply = 0
        
        // Set the named paths
        self.CollectionStoragePath = /storage/ticketCollection
        self.CollectionPublicPath = /public/ticketCollection
        self.MinterStoragePath = /storage/ticketMinter
        
        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        
        // create a public capability for the collection
        self.account.link<&Ticket.Collection{NonFungibleToken.CollectionPublic, Ticket.TicketCollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        
        // Create a Minter resource and save it to storage
        let minter: @Ticket.NFTMinter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)
        emit ContractInitialized()
    }
}
