import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

/*
    Genies is structured similarly to TopShot.
    Unlike TopShot, we use resources for all entities and manage access to their data
    by copying it to structs (this simplifies access control, in particular write access).
    We also encapsulate resource creation for the admin in member functions on the parent type.
    
    There are 4 levels of entity:
    1. Series.
    2. Genies Collection (not to be confused with an NFT Collection).
    3. Edition.
    4. Genies NFT (an NFT).
    Each exists conceptually within the thing above it.
    And each must be created or closed by the thing above it.

    Note that we cache some information (Series names/ids, counts of deactivated entities) rather
    than calculate it each time.
    This is enabled by encapsulation and saves gas for entity lifecycle operations.

    Note that the behaviours of Series.closeAllCollections(), Series.deactivate(), and Series.init()
    are kept separate to allow ending one series in various ways without starting another.
    They are called in the correct order in Admin.advanceSeries().
 */

// The Genies NFTs and metadata contract
//
pub contract Genies: NonFungibleToken{ 
    //------------------------------------------------------------
    // Events
    //------------------------------------------------------------
    
    
    // Contract Events
    //
    pub event ContractInitialized()
    
    // NFT Collection (not Genies Collection!) Events
    //
    pub event Withdraw(id: UInt64, from: Address?)
    
    pub event Deposit(id: UInt64, to: Address?)
    
    // Series Events
    //
    // Emitted when a new series has been triggered by an admin
    pub event NewSeriesStarted(newCurrentSeries: UInt32, name: String, metadata:{ String: String})
    
    pub event SeriesDeactivated(id: UInt32)
    
    // Collection Events
    //
    pub event CollectionCreated(id: UInt32, seriesID: UInt32, name: String, metadata:{ String: String})
    
    pub event CollectionClosed(id: UInt32)
    
    // Edition Events
    //
    pub event EditionCreated(id: UInt32, collectionID: UInt32, name: String, metadata:{ String: String})
    
    pub event EditionRetired(id: UInt32)
    
    // NFT Events
    //
    pub event NFTMinted(id: UInt64, editionID: UInt32, serialNumber: UInt32)
    
    pub event NFTBurned(id: UInt64)
    
    //------------------------------------------------------------
    // Named values
    //------------------------------------------------------------
    
    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let AdminStoragePath: StoragePath
    
    pub let MinterPrivatePath: PrivatePath
    
    //------------------------------------------------------------
    // Publcly readable contract state
    //------------------------------------------------------------
    
    // Entity Counts
    //
    pub var totalSupply: UInt64
    
    pub var currentSeriesID: UInt32
    
    pub var nextCollectionID: UInt32
    
    pub var nextEditionID: UInt32
    
    //------------------------------------------------------------
    // Internal contract state
    //------------------------------------------------------------
    
    // Metadata Dictionaries
    //
    // This is so we can find Series by their names (via seriesByID)
    priv let seriesIDByName:{ String: UInt32}
    
    // This avoids storing Series in an array where the index is off by one
    priv let seriesByID: @{UInt32: Series}
    
    priv let collectionByID: @{UInt32: GeniesCollection}
    
    priv let editionByID: @{UInt32: Edition}
    
    //------------------------------------------------------------
    // Series
    //------------------------------------------------------------
    
    // A public struct to access Series data
    //
    pub struct SeriesData{ 
        pub let id: UInt32
        
        pub let name: String
        
        pub let metadata:{ String: String}
        
        pub let active: Bool
        
        pub let collectionIDs: [UInt32]
        
        pub let collectionsOpen: UInt32
        
        // initializer
        //
        init(id: UInt32){ 
            let series = &Genies.seriesByID[id] as                                                   
                                                   // A top-level Series with a unique ID and name
                                                   //
                                                   // Contents writable if borrowed!
                                                   // This is deliberate, as it allows admins to update the data.
                                                   // We manage this list, but need to access it to fill out the struct,
                                                   // so it is access(contract)
                                                   
                                                   // Deactivate this series
                                                   //
                                                   
                                                   // Create and add a collection to the series.
                                                   // You can only do so via this function, which updates the relevant fields.
                                                   //
                                                   
                                                   // Close a collection, and update the relevant fields
                                                   //
                                                   &Genies.Series
            self.id = series.id
            self                
                // Recursively ensure that all of the collections are closed,
                // and all the editions in each are retired,
                // allowing advanceSeries to proceed
                // 
                .name = series.name
            self.metadata                          
                          // initializer
                          // We pass in ID as the lofic for it is more complex than it should be,
                          // and we don't want to spread it out.
                          //
                          = series.metadata
            self.active = series.active
            self.collectionIDs = series.collectionIDs
            self.collectionsOpen                                 
                                 // Get the publicly available data for a Series by id
                                 //
                                 
                                 // Get the publicly available data for a Series by name
                                 //
                                 = series.collectionsOpen
        }
    
    // Get all series names (this will be *long*)
    //
    }
    
    // Get series id for name
    //
    pub resource Series{ 
        pub let id                  
                  //------------------------------------------------------------
                  // GeniesCollection
                  //------------------------------------------------------------
                  
                  
                  // A public struct to access GeniesCollection data
                  //
                  : UInt32
        
        pub let name: String
        
        pub let metadata:{ String: String}
        
        access(contract) let collectionIDs: [UInt32]
        
        pub var collectionsOpen: UInt32
        
        // initializer
        //
        pub var active                      
                      // A Genies collection (not to be confused with a NonFungibleToken.Collection) within a series
                      //
                      : Bool
        
        pub fun deactivate(){ 
            pre{ 
                self                    // Contents writable if borrowed!
                    // This is deliberate, as it allows admins to update the data.
                    // We manage this list, but need to access it to fill out the struct,
                    // so it is access(contract)
                    
                    // Create and add an Edition to the series.
                    // You can only do so via this function, which updates the relevant fields.
                    //
                    .active == true:
                    "not active"
                self.collectionsOpen                                     
                                     // Close an Edition, and update the relevant fields
                                     //
                                     
                                     // Retire all of the Editions, allowing this collection to be closed
                                     // 
                                     
                                     // Close the collection
                                     // access(contract) to enforce calling through its parent series
                                     //
                                     == 0:
                    "must closeAllCollections before deactivating"
            }
            self.active = false
            emit SeriesDeactivated(id: self.id)
        }
        
        // initializer
        //
        pub fun addCollection(collectionName: String, collectionMetadata:{ String: String}): UInt32{ 
            pre{ 
                self.active                            
                            // Get the publicly available data for a GeniesCollection
                            // Not an NFT Collection!
                            //
                            
                            //------------------------------------------------------------
                            // Edition
                            //------------------------------------------------------------
                            
                            
                            // A public struct to access Edition data
                            //
                            
                            // initializer
                            //
                            
                            // An Edition (NFT type) within a Genies collection
                            //
                            // Contents writable if borrowed!
                            // This is deliberate, as it allows admins to update the data.
                            
                            // Retire this edition so that no more Genies NFTs can be minted in it
                            // access(contract) to enforce calling through its parent GeniesCollection
                            //
                            == true:
                    "Cannot add collection to previous series"
            }
            let collection                           
                           // Mint a Genies NFT in this edition, with the given minting mintingDate.
                           // Note that this will panic if this edition is retired.
                           //
                           
                           // Keep a running total (you'll notice we used this as the serial number
                           // and pre-increment it so that serial numbers start at 1 ).
                           
                           // Create the Genies NFT, filled out with our information
                           <- create Genies.GeniesCollection(seriesID: self.id, name: collectionName                                                                                                    
                                                                                                    // initializer
                                                                                                    //
                                                                                                    , metadata: collectionMetadata)
            let collectionID = collection.id
            Genies.collectionByID[collectionID]                                                
                                                // Get the publicly available data for an Edition
                                                //
                                                
                                                //------------------------------------------------------------
                                                // NFT
                                                //------------------------------------------------------------
                                                
                                                
                                                // A Genies NFT
                                                //
                                                
                                                // Destructor
                                                //
                                                
                                                // NFT initializer
                                                //
                                                
                                                //------------------------------------------------------------
                                                // Collection
                                                //------------------------------------------------------------
                                                
                                                
                                                // A public collection interface that allows Genies NFTs to be borrowed
                                                //
                                                // If the result isn't nil, the id of the returned reference
                                                // should be the same as the argument to the function
                                                
                                                // An NFT Collection (not to be confused with a GeniesCollection)
                                                //
                                                // dictionary of NFT conforming tokens
                                                // NFT is a resource type with an UInt64 ID field
                                                //
                                                
                                                // withdraw removes an NFT from the collection and moves it to the caller
                                                //
                                                
                                                // deposit takes a NFT and adds it to the collections dictionary
                                                // and adds the ID to the id array
                                                //
                                                
                                                // add the new token to the dictionary which removes the old one
                                                
                                                // batchDeposit takes a Collection object as an argument
                                                // and deposits each contained NFT into this Collection
                                                //
                                                // Get an array of the IDs to be deposited
                                                
                                                // Iterate through the keys in the collection and deposit each one
                                                
                                                // Destroy the empty Collection
                                                
                                                // getIDs returns an array of the IDs that are in the collection
                                                //
                                                
                                                // borrowNFT gets a reference to an NFT in the collection
                                                //
                                                
                                                // borrowGeniesNFT gets a reference to an NFT in the collection
                                                //
                                                
                                                // Collection destructor
                                                //
                                                
                                                // Collection initializer
                                                //
                                                
                                                // public function that anyone can call to create a new empty collection
                                                //
                                                
                                                //------------------------------------------------------------
                                                // Admin
                                                //------------------------------------------------------------
                                                
                                                
                                                // An interface containing the Admin function that allows minting NFTs
                                                //
                                                // Mint a single NFT
                                                // The Edition for the given ID must already exist
                                                //
                                                
                                                // A resource that allows managing metadata and minting NFTs
                                                //
                                                // Create a new series and set it to be the current one, deactivating the previous one if needed.
                                                // You probably want to call closeAllCollections() on the current series before this.
                                                //
                                                
                                                // The contract starts with currentSeriesID 0 but no entry for series zero.
                                                // We have to call advanceSeries to create series 0, so we have to handle that special case.
                                                // This test handles that case.
                                                // Its body will be called every time after the initial advance, which is what we want.
                                                // Make sure everything in the series is closed
                                                // Deactivate the current series
                                                // Advance the currentSeriesID
                                                
                                                // Create and store the new series
                                                <-! collection
            
            // Cache the new series's name => ID
            self.collectionIDs.append(                                      
                                      // Return the new ID for convenience
                                      collectionID)
            self.collectionsOpen                                 
                                 // Borrow a Series
                                 //
                                 
                                 // Borrow a Genies Collection. Not an NFT Collection!
                                 //
                                 
                                 // Borrow an Edition
                                 //
                                 
                                 // Mint a single NFT
                                 // The Edition for the given ID must already exist
                                 //
                                 // Make sure the edition we are creating this NFT in exists
                                 
                                 //------------------------------------------------------------
                                 // Contract lifecycle
                                 //------------------------------------------------------------
                                 
                                 
                                 // Genies contract initializer
                                 //
                                 // Set the named paths
                                 = self.collectionsOpen                                                        
                                                        // Initialize the entity counts
                                                        
                                                        // Initialize the metadata lookup dictionaries
                                                        
                                                        // Create an Admin resource and save it to storage
                                                        // Link capabilites to the admin constrained to the Minter
                                                        // and Metadata interfaces
                                                        
                                                        // Let the world know we are here
                                                        + 1 as UInt32
            return collectionID
        }
        
        pub fun closeGeniesCollection(collectionID: UInt32){ 
            pre{ 
                Genies.collectionByID[collectionID] != nil:
                    "no such collectionID"
            }
            let collection = &Genies.collectionByID[collectionID] as &Genies.GeniesCollection
            collection.close()
            self.collectionsOpen = self.collectionsOpen - 1 as UInt32
        }
        
        pub fun closeAllGeniesCollections(){ 
            for collectionID in self.collectionIDs{ 
                let collection = &Genies.collectionByID[collectionID] as &Genies.GeniesCollection
                if collection.open{ 
                    collection.retireAllEditions()
                    self.closeGeniesCollection(collectionID: collectionID)
                }
            }
        }
        
        init(id: UInt32, name: String, metadata:{ String: String}){ 
            pre{ 
                !Genies.seriesIDByName.containsKey(name):
                    "A Series with that name already exists"
            }
            self.id = id
            self.name = name
            self.metadata = metadata
            self.collectionIDs = []
            self.collectionsOpen = 0 as UInt32
            self.active = true
            emit NewSeriesStarted(newCurrentSeries: self.id, name: self.name, metadata: self.metadata)
        }
    }
    
    pub fun getSeriesData(id: UInt32): Genies.SeriesData{ 
        pre{ 
            Genies.seriesByID[id] != nil:
                "Cannot borrow series, no such id"
        }
        return Genies.SeriesData(id: id)
    }
    
    pub fun getSeriesDataByName(name: String): Genies.SeriesData{ 
        pre{ 
            Genies.seriesIDByName[name] != nil:
                "Cannot borrow series, no such name"
        }
        let id = Genies.seriesIDByName[name]!
        return Genies.SeriesData(id: id)
    }
    
    pub fun getAllSeriesNames(): [String]{ 
        return Genies.seriesIDByName.keys
    }
    
    pub fun getSeriesIDByName(name: String): UInt32?{ 
        return Genies.seriesIDByName[name]
    }
    
    pub struct GeniesCollectionData{ 
        pub let id: UInt32
        
        pub let seriesID: UInt32
        
        pub let name: String
        
        pub let metadata:{ String: String}
        
        pub let open: Bool
        
        pub let editionIDs: [UInt32]
        
        pub let editionsActive: UInt32
        
        init(id: UInt32){ 
            let collection = &Genies.collectionByID[id] as &Genies.GeniesCollection
            self.id = id
            self.seriesID = collection.seriesID
            self.name = collection.name
            self.metadata = collection.metadata
            self.open = collection.open
            self.editionIDs = collection.editionIDs
            self.editionsActive = collection.editionsActive
        }
    }
    
    pub resource GeniesCollection{ 
        pub let id: UInt32
        
        pub let seriesID: UInt32
        
        pub let name: String
        
        pub let metadata:{ String: String}
        
        pub var open: Bool
        
        access(contract) let editionIDs: [UInt32]
        
        pub var editionsActive: UInt32
        
        pub fun addEdition(editionName: String, editionMetadata:{ String: String}): UInt32{ 
            pre{ 
                self.open == true:
                    "Cannot add edition to closed collection"
            }
            let edition <- create Genies.Edition(collectionID: self.id, name: editionName, metadata: editionMetadata)
            let editionID = edition.id
            Genies.editionByID[editionID] <-! edition
            self.editionIDs.append(editionID)
            self.editionsActive = self.editionsActive + 1 as UInt32
            return editionID
        }
        
        pub fun retireEdition(editionID: UInt32){ 
            pre{ 
                Genies.editionByID[editionID] != nil:
                    "editionID doesn't exist"
            }
            let edition = &Genies.editionByID[editionID] as &Edition
            edition.retire()
            self.editionsActive = self.editionsActive - 1 as UInt32
        }
        
        pub fun retireAllEditions(){ 
            for editionID in self.editionIDs{ 
                self.retireEdition(editionID: editionID)
            }
        }
        
        access(contract) fun close(){ 
            pre{ 
                self.editionsActive == 0:
                    "All editions in this collection must be closed before closing it"
            }
            self.open = false
            emit CollectionClosed(id: self.id)
        }
        
        init(seriesID: UInt32, name: String, metadata:{ String: String}){ 
            pre{ 
                Genies.seriesByID.containsKey(seriesID) != nil:
                    "seriesID does not exist"
            }
            self.id = Genies.nextCollectionID
            self.seriesID = seriesID
            self.name = name
            self.metadata = metadata
            self.editionIDs = []
            self.editionsActive = 0 as UInt32
            self.open = true
            Genies.nextCollectionID = Genies.nextCollectionID + 1 as UInt32
            emit CollectionCreated(id: self.id, seriesID: self.seriesID, name: self.name, metadata: self.metadata)
        }
    }
    
    pub fun getGeniesCollectionData(id: UInt32): Genies.GeniesCollectionData{ 
        pre{ 
            Genies.collectionByID[id] != nil:
                "Cannot borrow Genies collection, no such id"
        }
        return GeniesCollectionData(id: id)
    }
    
    pub struct EditionData{ 
        pub let id: UInt32
        
        pub let collectionID: UInt32
        
        pub let name: String
        
        pub let metadata:{ String: String}
        
        pub let open: Bool
        
        pub let numMinted: UInt32
        
        init(id: UInt32){ 
            let edition = &Genies.editionByID[id] as &Genies.Edition
            self.id = id
            self.collectionID = edition.collectionID
            self.name = edition.name
            self.metadata = edition.metadata
            self.open = edition.open
            self.numMinted = edition.numMinted
        }
    }
    
    pub resource Edition{ 
        pub let id: UInt32
        
        pub let collectionID: UInt32
        
        pub let name: String
        
        pub let metadata:{ String: String}
        
        pub var numMinted: UInt32
        
        pub var open: Bool
        
        access(contract) fun retire(){ 
            pre{ 
                self.open == true:
                    "already retired"
            }
            self.open = false
            emit EditionRetired(id: self.id)
        }
        
        pub fun mint(): @Genies.NFT{ 
            pre{ 
                self.open:
                    "edition closed, cannot mint"
            }
            self.numMinted = self.numMinted + 1 as UInt32
            let geniesNFT <- create NFT(id: Genies.totalSupply, editionID: self.id, serialNumber: self.numMinted)
            Genies.totalSupply = Genies.totalSupply + 1
            return <-geniesNFT
        }
        
        init(collectionID: UInt32, name: String, metadata:{ String: String}){ 
            pre{ 
                Genies.collectionByID.containsKey(collectionID):
                    "collectionID does not exist"
            }
            self.id = Genies.nextEditionID
            self.collectionID = collectionID
            self.name = name
            self.metadata = metadata
            self.numMinted = 0 as UInt32
            self.open = true
            Genies.nextEditionID = Genies.nextEditionID + 1 as UInt32
            emit EditionCreated(id: self.id, collectionID: self.collectionID, name: self.name, metadata: self.metadata)
        }
    }
    
    pub fun getEditionData(id: UInt32): EditionData{ 
        pre{ 
            Genies.editionByID[id] != nil:
                "Cannot borrow edition, no such id"
        }
        let edition = &Genies.editionByID[id] as &Genies.Edition
        return EditionData(id: id)
    }
    
    pub resource NFT: NonFungibleToken.INFT{ 
        pub let id: UInt64
        
        pub let editionID: UInt32
        
        pub let serialNumber: UInt32
        
        pub let mintingDate: UFix64
        
        destroy(){ 
            emit NFTBurned(id: self.id)
        }
        
        init(id: UInt64, editionID: UInt32, serialNumber: UInt32){ 
            pre{ 
                Genies.editionByID[editionID] != nil:
                    "no such editionID"
                (&Genies.editionByID[editionID] as &Edition).open:
                    "editionID is retired"
            }
            self.id = id
            self.editionID = editionID
            self.serialNumber = serialNumber
            self.mintingDate = getCurrentBlock().timestamp
            emit NFTMinted(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
        }
    }
    
    pub resource interface GeniesNFTCollectionPublic{ 
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection){} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowGeniesNFT(id: UInt64): &Genies.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Genies NFT reference: The ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GeniesNFTCollectionPublic{ 
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @Genies.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection){ 
            let keys = tokens.getIDs()
            for key in keys{ 
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }
            destroy tokens
        }
        
        pub fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{ 
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }
        
        pub fun borrowGeniesNFT(id: UInt64): &Genies.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Genies.NFT
            } else{ 
                return nil
            }
        }
        
        destroy(){ 
            destroy self.ownedNFTs
        }
        
        init(){ 
            self.ownedNFTs <-{} 
        }
    }
    
    pub fun createEmptyCollection(): @NonFungibleToken.Collection{ 
        return <-create Collection()
    }
    
    pub resource interface NFTMinter{ 
        pub fun mintNFT(editionID: UInt32): @Genies.NFT{} 
    }
    
    pub resource Admin: NFTMinter{ 
        pub fun advanceSeries(nextSeriesName: String, nextSeriesMetadata:{ String: String}): UInt32{ 
            pre{ 
                Genies.seriesByID[Genies.currentSeriesID] == nil || (&Genies.seriesByID[Genies.currentSeriesID] as &Genies.Series).collectionsOpen == 0:
                    "All collections must be closed before advancing the series"
            }
            if Genies.seriesByID[Genies.currentSeriesID] != nil{ 
                let currentSeries = &Genies.seriesByID[Genies.currentSeriesID] as &Genies.Series
                if currentSeries.active{ 
                    currentSeries.closeAllGeniesCollections()
                    currentSeries.deactivate()
                    Genies.currentSeriesID = Genies.currentSeriesID + 1 as UInt32
                }
            }
            let series <- create Genies.Series(id: Genies.currentSeriesID, name: nextSeriesName, metadata: nextSeriesMetadata)
            Genies.seriesByID[Genies.currentSeriesID] <-! series
            Genies.seriesIDByName[nextSeriesName] = Genies.currentSeriesID
            return Genies.currentSeriesID
        }
        
        pub fun borrowSeries(id: UInt32): &Genies.Series{ 
            pre{ 
                Genies.seriesByID[id] != nil:
                    "Cannot borrow series, no such id"
            }
            return &Genies.seriesByID[id] as &Genies.Series
        }
        
        pub fun borrowGeniesCollection(id: UInt32): &Genies.GeniesCollection{ 
            pre{ 
                Genies.collectionByID[id] != nil:
                    "Cannot borrow Genies collection, no such id"
            }
            return &Genies.collectionByID[id] as &Genies.GeniesCollection
        }
        
        pub fun borrowEdition(id: UInt32): &Genies.Edition{ 
            pre{ 
                Genies.editionByID[id] != nil:
                    "Cannot borrow edition, no such id"
            }
            return &Genies.editionByID[id] as &Genies.Edition
        }
        
        pub fun mintNFT(editionID: UInt32): @Genies.NFT{ 
            pre{ 
                Genies.editionByID.containsKey(editionID):
                    "No such EditionID"
            }
            return <-self.borrowEdition(id: editionID).mint()
        }
    }
    
    init(){ 
        self.CollectionStoragePath = /storage/GeniesNFTCollection
        self.CollectionPublicPath = /public/GeniesNFTCollection
        self.AdminStoragePath = /storage/GeniesAdmin
        self.MinterPrivatePath = /private/GeniesMinter
        self.totalSupply = 0
        self.currentSeriesID = 0
        self.nextCollectionID = 0
        self.nextEditionID = 0
        self.seriesByID <-{} 
        self.seriesIDByName ={} 
        self.collectionByID <-{} 
        self.editionByID <-{} 
        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)
        self.account.link<&Genies.Admin{Genies.NFTMinter}>(self.MinterPrivatePath, target: self.AdminStoragePath)
        emit ContractInitialized()
    }
}
