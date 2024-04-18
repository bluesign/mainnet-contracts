/*
    Escrow Contract for managing NFTs in a Leaderboard Context.
    Holds NFTs in Escrow account awaiting transfer or burn.

    Authors:
        Corey Humeston: corey.humeston@dapperlabs.com
        Deewai Abdullahi: innocent.abdullahi@dapperlabs.com
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract Escrow{ 
    // Event emitted when a new leaderboard is created.
    pub event LeaderboardCreated(name: String, nftType: Type)
    
    // Event emitted when an NFT is deposited to a leaderboard.
    pub event EntryDeposited(
        leaderboardName: String,
        nftID: UInt64,
        owner: Address
    )
    
    // Event emitted when an NFT is returned to the original collection from a leaderboard.
    pub event EntryReturnedToCollection(
        leaderboardName: String,
        nftID: UInt64,
        owner: Address
    )
    
    // Event emitted when an NFT is burned from a leaderboard.
    pub event EntryBurned(leaderboardName: String, nftID: UInt64)
    
    // Named Paths
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let CollectionPrivatePath: PrivatePath
    
    pub struct LeaderboardInfo{ 
        pub let name: String
        
        pub let nftType: Type
        
        pub let entriesLength: Int
        
        init(name: String, nftType: Type, entriesLength: Int){ 
            self.name = name
            self.nftType = nftType
            self.entriesLength = entriesLength
        }
    }
    
    // The resource representing a leaderboard.
    pub resource Leaderboard{ 
        pub var collection: @NonFungibleToken.Collection
        
        pub var entriesData:{ UInt64: LeaderboardEntry}
        
        pub let name: String
        
        pub let nftType: Type
        
        pub var entriesLength: Int
        
        pub var metadata:{ String: AnyStruct}
        
        // Adds an NFT entry to the leaderboard.
        pub fun addEntryToLeaderboard(
            nft: @NonFungibleToken.NFT,
            ownerAddress: Address,
            metadata:{ 
                String: AnyStruct
            }
        ){ 
            pre{ 
                nft.isInstance(self.nftType):
                    "This NFT cannot be used for leaderboard. NFT is not of the correct type."
            }
            let nftID = nft.id
            
            // Create the entry and add it to the entries map
            let entry =
                LeaderboardEntry(
                    nftID: nftID,
                    ownerAddress: ownerAddress,
                    metadata: metadata
                )
            self.entriesData[nftID] = entry
            self.collection.deposit(token: <-nft)
            
            // Increment entries length.
            self.entriesLength = self.entriesLength + 1
            emit EntryDeposited(
                leaderboardName: self.name,
                nftID: nftID,
                owner: ownerAddress
            )
        }
        
        // Withdraws an NFT entry from the leaderboard.
        access(contract) fun transferNftToCollection(
            nftID: UInt64,
            depositCap: Capability<&{NonFungibleToken.CollectionPublic}>
        ){ 
            // Check to see if the entry exists.
            pre{ 
                self.entriesData[nftID] != nil:
                    "Entry does not exist with this NFT ID"
                depositCap.address == (self.entriesData[nftID]!).ownerAddress:
                    "Only the owner of the entry can withdraw it"
                depositCap.check():
                    "Deposit capability is not valid"
            }
            self.entriesData.remove(key: nftID)!
            let token <- self.collection.withdraw(withdrawID: nftID)
            let receiverCollection =
                depositCap.borrow() as &{NonFungibleToken.CollectionPublic}?
                ?? panic(
                    "Could not borrow the NFT receiver from the capability"
                )
            (receiverCollection!).deposit(token: <-token)
            emit EntryReturnedToCollection(
                leaderboardName: self.name,
                nftID: nftID,
                owner: depositCap.address
            )
            
            // Decrement entries length.
            self.entriesLength = self.entriesLength - 1
        }
        
        // Burns an NFT entry from the leaderboard.
        access(contract) fun burn(nftID: UInt64){ 
            // Check to see if the entry exists.
            pre{ 
                self.entriesData[nftID] != nil:
                    "Entry does not exist with this NFT ID"
            }
            self.entriesData.remove(key: nftID)!
            let token <- self.collection.withdraw(withdrawID: nftID)
            emit EntryBurned(leaderboardName: self.name, nftID: nftID)
            
            // Decrement entries length.
            self.entriesLength = self.entriesLength - 1
            destroy token
        }
        
        // Destructor for Leaderboard resource.
        destroy(){ 
            destroy self.collection
        }
        
        init(
            name: String,
            nftType: Type,
            collection: @NonFungibleToken.Collection
        ){ 
            self.name = name
            self.nftType = nftType
            self.collection <- collection
            self.entriesLength = 0
            self.metadata ={} 
            self.entriesData ={} 
        }
    }
    
    // The resource representing an NFT entry in a leaderboard.
    pub struct LeaderboardEntry{ 
        pub let nftID: UInt64
        
        pub let ownerAddress: Address
        
        pub var metadata:{ String: AnyStruct}
        
        init(
            nftID: UInt64,
            ownerAddress: Address,
            metadata:{ 
                String: AnyStruct
            }
        ){ 
            self.nftID = nftID
            self.ownerAddress = ownerAddress
            self.metadata = metadata
        }
    }
    
    // An interface containing the Collection function that gets leaderboards by name.
    pub resource interface ICollectionPublic{ 
        pub fun getLeaderboardInfo(name: String): LeaderboardInfo?{} 
        
        pub fun addEntryToLeaderboard(
            nft: @NonFungibleToken.NFT,
            leaderboardName: String,
            ownerAddress: Address,
            metadata:{ 
                String: AnyStruct
            }
        ){} 
    }
    
    pub resource interface ICollectionPrivate{ 
        pub fun createLeaderboard(
            name: String,
            nftType: Type,
            collection: @NonFungibleToken.Collection
        ){} 
        
        pub fun transferNftToCollection(
            leaderboardName: String,
            nftID: UInt64,
            depositCap: Capability<&{NonFungibleToken.CollectionPublic}>
        ){} 
        
        pub fun burn(leaderboardName: String, nftID: UInt64){} 
    }
    
    // The resource representing a collection.
    pub resource Collection: ICollectionPublic, ICollectionPrivate{ 
        // A dictionary holding leaderboards.
        priv var leaderboards: @{String: Leaderboard}
        
        // Creates a new leaderboard and stores it.
        pub fun createLeaderboard(name: String, nftType: Type, collection: @NonFungibleToken.Collection){ 
            if self.leaderboards[name] != nil{ 
                panic("Leaderboard already exists with this name")
            }
            
            // Create a new leaderboard resource.
            let newLeaderboard <- create Leaderboard(name: name, nftType: nftType, collection: <-collection)
            
            // Store the leaderboard for future access.
            self.leaderboards[name] <-! newLeaderboard
            
            // Emit the event.
            emit LeaderboardCreated(name: name, nftType: nftType)
        }
        
        // Returns leaderboard info with the given name.
        pub fun getLeaderboardInfo(name: String): LeaderboardInfo?{ 
            let leaderboard = &self.leaderboards[name] as &Leaderboard?
            if leaderboard == nil{ 
                return nil
            }
            return LeaderboardInfo(name: (leaderboard!).name, nftType: (leaderboard!).nftType, entriesLength: (leaderboard!).entriesLength)
        }
        
        // Call addEntry.
        pub fun addEntryToLeaderboard(nft: @NonFungibleToken.NFT, leaderboardName: String, ownerAddress: Address, metadata:{ String: AnyStruct}){ 
            let leaderboard = &self.leaderboards[leaderboardName] as &Leaderboard?
            if leaderboard == nil{ 
                panic("Leaderboard does not exist with this name")
            }
            (leaderboard!).addEntryToLeaderboard(nft: <-nft, ownerAddress: ownerAddress, metadata: metadata)
        }
        
        // Calls transferNftToCollection.
        pub fun transferNftToCollection(leaderboardName: String, nftID: UInt64, depositCap: Capability<&{NonFungibleToken.CollectionPublic}>){ 
            let leaderboard = &self.leaderboards[leaderboardName] as &Leaderboard?
            if leaderboard == nil{ 
                panic("Leaderboard does not exist with this name")
            }
            (leaderboard!).transferNftToCollection(nftID: nftID, depositCap: depositCap)
        }
        
        // Calls burn.
        pub fun burn(leaderboardName: String, nftID: UInt64){ 
            let leaderboard = &self.leaderboards[leaderboardName] as &Leaderboard?
            if leaderboard == nil{ 
                panic("Leaderboard does not exist with this name")
            }
            (leaderboard!).burn(nftID: nftID)
        }
        
        // Destructor for Collection resource.
        destroy(){ 
            destroy self.leaderboards
        }
        
        init(){ 
            self.leaderboards <-{} 
        }
    }
    
    init(){ 
        self.CollectionStoragePath = /storage/EscrowLeaderboardCollection
        self.CollectionPrivatePath = /private/EscrowLeaderboardCollectionAccess
        self.CollectionPublicPath = /public/EscrowLeaderboardCollectionInfo
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        self.account.link<&Collection{ICollectionPrivate}>(
            self.CollectionPrivatePath,
            target: self.CollectionStoragePath
        )
        self.account.link<&Collection{ICollectionPublic}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )
    }
}
