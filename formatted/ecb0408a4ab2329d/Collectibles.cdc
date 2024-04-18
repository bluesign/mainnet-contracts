import CapsuleNFT from "./CapsuleNFT.cdc"

pub contract Collectibles: CapsuleNFT{ 
    pub var totalMinted: UInt64
    
    pub event ContractInitialized()
    
    pub event CollectionCreated()
    
    pub event CollectionDestroyed(length: Int)
    
    pub event Withdraw(id: String, size: UInt64, from: Address?)
    
    pub event Deposit(id: String, size: UInt64, to: Address?)
    
    pub event Minted(id: String)
    
    pub event CollectibleMinted(id: String, name: String, collection: String, type: String, rarity: String, edition: String, mediaUri: String, mintedTime: String, resourceId: UInt64)
    
    pub event CollectibleDestroyed(id: String)
    
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let MinterStoragePath: StoragePath
    
    /// NFT:
    /// A Collectible as an NFT
    pub resource NFT: CapsuleNFT.INFT{ 
        pub let id: String
        
        pub let name: String
        
        pub let collection: String
        
        pub let type: String
        
        pub let rarity: String
        
        pub let edition: String
        
        pub let mediaUri: String
        
        pub let mintedTime: String
        
        init(id: String, name: String, collection: String, type: String, rarity: String, edition: String, mediaUri: String, mintedTime: String){ 
            self.id = id
            self.name = name
            self.collection = collection
            self.type = type
            self.rarity = rarity
            self.edition = edition
            self.mediaUri = mediaUri
            self.mintedTime = mintedTime
        }
        
        destroy(){ 
            emit CollectibleDestroyed(id: self.id)
        }
    }
    
    /// CollectiblesCollectionPublic:
    /// This is the interface that users can cast their Collectible Collection as,
    /// in order to allow others to deposit a Collectible into their Collection. 
    /// It also allows for reading the details of an Collectible in the Collection.
    pub resource interface CollectiblesCollectionPublic{ 
        pub fun deposit(token: @CapsuleNFT.NFT){} 
        
        pub fun getIDs(): [String]{} 
        
        pub fun borrowNFT(id: String): &CapsuleNFT.NFT{} 
        
        pub fun borrowCollectible(id: String): &Collectibles.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Collectible reference: the ID of the returned reference is incorrect"
            }
        }
    }
    
    /// Collection:
    /// A collection of Collectibles NFTs owned by an account
    pub resource Collection: CollectiblesCollectionPublic, CapsuleNFT.Provider, CapsuleNFT.Receiver, CapsuleNFT.CollectionPublic{ 
        // dictionary of NFT conforming tokens
        // NFT is a resource type with a `String` ID field
        pub var ownedNFTs: @{String: CapsuleNFT.NFT}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        /// Removes an NFT from the collection and moves it to the caller
        pub fun withdraw(id: String): @CapsuleNFT.NFT{ 
            let address: Address? = self.owner?.address
            let account: PublicAccount = getAccount(address!)
            let startUsed: UInt64 = account.storageUsed
            let token: @CapsuleNFT.NFT <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")
            let endUsed: UInt64 = account.storageUsed
            let delta: UInt64 = endUsed - startUsed
            emit Withdraw(id: token.id, size: delta, from: address)
            return <-token
        }
        
        /// Takes an NFT, adds it to the Collection dictionary and adds the ID to the id array
        pub fun deposit(token: @CapsuleNFT.NFT){ 
            let address: Address? = self.owner?.address
            let account: PublicAccount = getAccount(address!)
            let startUsed: UInt64 = account.storageUsed
            let token: @Collectibles.NFT <- token as! @Collectibles.NFT
            let id: String = token.id
            // Add the new token to the dictionary which removes the old one
            let oldToken: @CapsuleNFT.NFT? <- self.ownedNFTs[id] <- token
            let endUsed: UInt64 = account.storageUsed
            let delta: UInt64 = endUsed - startUsed
            emit Deposit(id: id, size: delta, to: address)
            destroy oldToken
        }
        
        /// Returns an array of the IDs that are in the collection
        pub fun getIDs(): [String]{ 
            return self.ownedNFTs.keys
        }
        
        /// Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: String): &CapsuleNFT.NFT{ 
            return (&self.ownedNFTs[id] as &CapsuleNFT.NFT?)!
        }
        
        /// Gets a reference to a Collectible in the Collection
        pub fun borrowCollectible(id: String): &Collectibles.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                // Create an authorised reference to allow downcasting
                let ref: auth &CapsuleNFT.NFT = (&self.ownedNFTs[id] as auth &CapsuleNFT.NFT?)!
                return ref as! &Collectibles.NFT
            } else{ 
                return nil
            }
        }
        
        destroy(){ 
            let collectionLength = self.ownedNFTs.length
            destroy self.ownedNFTs
            emit CollectionDestroyed(length: collectionLength)
        }
    }
    
    /// Public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @CapsuleNFT.Collection{ 
        emit CollectionCreated()
        return <-create Collection()
    }
    
    /// Resource that an admin or similar would own to be able to mint new NFTs
    pub resource NFTMinter{ 
        /// Mints a new Collectible. 
        /// Deposits it in the recipients Collection using their PublicCollection reference.
        pub fun mintCollectible(recipientCollection: &{CapsuleNFT.CollectionPublic}, id: String, name: String, collection: String, type: String, rarity: String, edition: String, mediaUri: String, mintedTime: String){ 
            // Create a new Collectible NFT
            var collectible: @Collectibles.NFT <- create NFT(id: id, name: name, collection: collection, type: type, rarity: rarity, edition: edition, mediaUri: mediaUri, mintedTime: mintedTime)
            // Emit Events
            emit CollectibleMinted(id: id, name: name, collection: collection, type: type, rarity: rarity, edition: edition, mediaUri: mediaUri, mintedTime: mintedTime, resourceId: collectible.uuid)
            // Increment the total of minted Collectibles
            Collectibles.totalMinted = Collectibles.totalMinted + 1
            
            // Deposit it in the recipient's account using their reference
            recipientCollection.deposit(token: <-collectible)
        }
    }
    
    init(){ 
        // Initialize the total of minted Collectibles
        self.totalMinted = 0
        
        // Set the named paths
        self.CollectionStoragePath = /storage/CapsuleCollectiblesCollection
        self.CollectionPublicPath = /public/CapsuleCollectiblesCollection
        self.MinterStoragePath = /storage/CapsuleCollectiblesMinter
        
        // Create a Collection resource and save it to storage
        let collection: @Collectibles.Collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        
        // Create a public capability for the collection
        self.account.link<&Collectibles.Collection{CapsuleNFT.CollectionPublic, Collectibles.CollectiblesCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        
        // Create a Minter resource and save it to storage
        let minter: @Collectibles.NFTMinter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)
        emit ContractInitialized()
    }
}
