/*
    Adapted from: Genies.cdc
    Author: Rhea Myers rhea.myers@dapperlabs.com
    Author: Sadie Freeman sadie.freeman@dapperlabs.com
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

/*
    AllDay is structured similarly to Genies and TopShot.
    Unlike TopShot, we use resources for all entities and manage access to their data
    by copying it to structs (this simplifies access control, in particular write access).
    We also encapsulate resource creation for the admin in member functions on the parent type.
    
    There are 5 levels of entity:
    1. Series
    2. Sets
    3. Plays
    4. Editions
    4. Moment NFT (an NFT)
    
    An Edition is created with a combination of a Series, Set, and Play
    Moment NFTs are minted out of Editions.

    Note that we cache some information (Series names/ids, counts of entities) rather
    than calculate it each time.
    This is enabled by encapsulation and saves gas for entity lifecycle operations.
 */

// The AllDay NFTs and metadata contract
//
pub contract AllDay: NonFungibleToken{ 
    //------------------------------------------------------------
    // Events
    //------------------------------------------------------------
    
    
    // Contract Events
    //
    pub event ContractInitialized()
    
    // NFT Collection Events
    //
    pub event Withdraw(id: UInt64, from: Address?)
    
    pub event Deposit(id: UInt64, to: Address?)
    
    // Series Events
    //
    // Emitted when a new series has been created by an admin
    pub event SeriesCreated(id: UInt64, name: String)
    
    // Emitted when a series is closed by an admin
    pub event SeriesClosed(id: UInt64)
    
    // Set Events
    //
    // Emitted when a new set has been created by an admin
    pub event SetCreated(id: UInt64, name: String)
    
    // Play Events
    //
    // Emitted when a new play has been created by an admin
    pub event PlayCreated(id: UInt64, classification: String, metadata:{ String: String})
    
    // Edition Events
    //
    // Emitted when a new edition has been created by an admin
    pub event EditionCreated(id: UInt64, seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String)
    
    // Emitted when an edition is either closed by an admin, or the max amount of moments have been minted
    pub event EditionClosed(id: UInt64)
    
    // NFT Events
    //
    pub event MomentNFTMinted(id: UInt64, editionID: UInt64, serialNumber: UInt64)
    
    pub event MomentNFTBurned(id: UInt64)
    
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
    // Publicly readable contract state
    //------------------------------------------------------------
    
    // Entity Counts
    //
    pub var totalSupply: UInt64
    
    pub var nextSeriesID: UInt64
    
    pub var nextSetID: UInt64
    
    pub var nextPlayID: UInt64
    
    pub var nextEditionID: UInt64
    
    //------------------------------------------------------------
    // Internal contract state
    //------------------------------------------------------------
    
    // Metadata Dictionaries
    //
    // This is so we can find Series by their names (via seriesByID)
    priv let seriesIDByName:{ String: UInt64}
    
    priv let seriesByID: @{UInt64: Series}
    
    priv let setIDByName:{ String: UInt64}
    
    priv let setByID: @{UInt64: Set}
    
    priv let playByID: @{UInt64: Play}
    
    priv let editionByID: @{UInt64: Edition}
    
    //------------------------------------------------------------
    // Series
    //------------------------------------------------------------
    
    // A public struct to access Series data
    //
    pub struct SeriesData{ 
        pub let id: UInt64
        
        pub let name: String
        
        pub let active: Bool
        
        // initializer
        //
        init(id: UInt64){ 
            let series = &AllDay.seriesByID[id] as                                                   
                                                   // A top-level Series with a unique ID and name
                                                   //
                                                   
                                                   // Close this series
                                                   //
                                                   
                                                   // initializer
                                                   //
                                                   
                                                   // Cache the new series's name => ID
                                                   // Increment for the nextSeriesID
                                                   
                                                   // Get the publicly available data for a Series by id
                                                   //
                                                   
                                                   // Get the publicly available data for a Series by name
                                                   //
                                                   
                                                   // Get all series names (this will be *long*)
                                                   //
                                                   
                                                   // Get series id for name
                                                   //
                                                   
                                                   //------------------------------------------------------------
                                                   // Set
                                                   //------------------------------------------------------------
                                                   
                                                   
                                                   // A public struct to access Set data
                                                   //
                                                   
                                                   // member function to check the setPlaysInEditions to see if this Set/Play combination already exists
                                                   
                                                   // initializer
                                                   //
                                                   &AllDay.Series
            self.id = series.id
            self.name = series.name
            
            // A top level Set with a unique ID and a name
            //
            self                // Store a dictionary of all the Plays which are paired with the Set inside Editions
                // This enforces only one Set/Play unique pair can be used for an Edition
                
                // member function to insert a new Play to the setPlaysInEditions dictionary
                .active = series                                
                                // initializer
                                //
                                .active
        }
    }
    
    // Cache the new set's name => ID
    pub resource Series{ 
        pub let                // Increment for the nextSeriesID
                id: UInt64
        
        pub let name                    
                    // Get the publicly available data for a Set
                    //
                    : String
        
        pub var active: Bool
        
        pub fun close(){ 
            pre{ 
                
                // Get the publicly available data for a Set by name
                //
                self.active                            
                            // Get all set names (this will be *long*)
                            //
                            
                            //------------------------------------------------------------
                            // Play
                            //------------------------------------------------------------
                            
                            
                            // A public struct to access Play data
                            //
                            
                            // initializer
                            //
                            
                            // A top level Play with a unique ID and a classification
                            //
                            // Contents writable if borrowed!
                            // This is deliberate, as it allows admins to update the data.
                            
                            // initializer
                            //
                            
                            // Get the publicly available data for a Play
                            //
                            
                            //------------------------------------------------------------
                            // Edition
                            //------------------------------------------------------------
                            
                            
                            // A public struct to access Edition data
                            //
                            
                            // member function to check if max edition size has been reached
                            == true                                   
                                   // initializer
                                   //
                                   :
                    
                    // A top level Edition that contains a Series, Set, and Play
                    //
                    // Null value indicates that there is unlimited minting potential for the Edition
                    // Updates each time we mint a new moment for the Edition to keep a running total
                    
                    // Close this edition so that no more Moment NFTs can be minted in it
                    //
                    "not active"
            }
            self.active = false
            emit SeriesClosed(id: self.id)
        }
        
        // Mint a Moment NFT in this edition, with the given minting mintingDate.
        // Note that this will panic if the max mint size has already been reached.
        //
        init(name: String){ 
            pre{ 
                
                // Create the Moment NFT, filled out with our information
                // Keep a running total (you'll notice we used this as the serial number)
                
                // initializer
                //
                
                // If an edition size is not set, it has unlimited minting potential
                
                // Get the publicly available data for an Edition
                //
                
                //------------------------------------------------------------
                // NFT
                //------------------------------------------------------------
                
                
                // A Moment NFT
                //
                
                // Destructor
                //
                
                // NFT initializer
                //
                
                //------------------------------------------------------------
                // Collection
                //------------------------------------------------------------
                
                
                // A public collection interface that allows Moment NFTs to be borrowed
                //
                // If the result isn't nil, the id of the returned reference
                // should be the same as the argument to the function
                
                // An NFT Collection
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
                
                // borrowMomentNFT gets a reference to an NFT in the collection
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
                // Borrow a Series
                //
                
                // Borrow a Set
                //
                
                // Borrow a Play
                //
                
                // Borrow an Edition
                //
                
                // Create a Series
                //
                // Create and store the new series
                
                // Return the new ID for convenience
                
                // Close a Series
                //
                
                // Create a Set
                //
                // Create and store the new set
                
                // Return the new ID for convenience
                
                // Create a Play
                //
                // Create and store the new play
                
                // Return the new ID for convenience
                
                // Create an Edition
                //
                
                // Close an Edition
                //
                
                // Mint a single NFT
                // The Edition for the given ID must already exist
                //
                // Make sure the edition we are creating this NFT in exists
                
                //------------------------------------------------------------
                // Contract lifecycle
                //------------------------------------------------------------
                
                
                // AllDay contract initializer
                //
                // Set the named paths
                
                // Initialize the entity counts
                
                // Initialize the metadata lookup dictionaries
                
                // Create an Admin resource and save it to storage
                // Link capabilites to the admin constrained to the Minter
                // and Metadata interfaces
                
                // Let the world know we are here
                !AllDay.seriesIDByName.containsKey(name):
                    "A Series with that name already exists"
            }
            self.id = AllDay.nextSeriesID
            self.name = name
            self.active = true
            AllDay.seriesIDByName[name] = self.id
            AllDay.nextSeriesID = self.id + 1 as UInt64
            emit SeriesCreated(id: self.id, name: self.name)
        }
    }
    
    pub fun getSeriesData(id: UInt64): AllDay.SeriesData{ 
        pre{ 
            AllDay.seriesByID[id] != nil:
                "Cannot borrow series, no such id"
        }
        return AllDay.SeriesData(id: id)
    }
    
    pub fun getSeriesDataByName(name: String): AllDay.SeriesData{ 
        pre{ 
            AllDay.seriesIDByName[name] != nil:
                "Cannot borrow series, no such name"
        }
        let id = AllDay.seriesIDByName[name]!
        return AllDay.SeriesData(id: id)
    }
    
    pub fun getAllSeriesNames(): [String]{ 
        return AllDay.seriesIDByName.keys
    }
    
    pub fun getSeriesIDByName(name: String): UInt64?{ 
        return AllDay.seriesIDByName[name]
    }
    
    pub struct SetData{ 
        pub let id: UInt64
        
        pub let name: String
        
        pub var setPlaysInEditions:{ UInt64: Bool}
        
        pub fun setPlayExistsInEdition(playID: UInt64): Bool{ 
            return self.setPlaysInEditions.containsKey(playID)
        }
        
        init(id: UInt64){ 
            let set = &AllDay.setByID[id] as &AllDay.Set
            self.id = id
            self.name = set.name
            self.setPlaysInEditions = set.setPlaysInEditions
        }
    }
    
    pub resource Set{ 
        pub let id: UInt64
        
        pub let name: String
        
        pub var setPlaysInEditions:{ UInt64: Bool}
        
        pub fun insertNewPlay(playID: UInt64){ 
            self.setPlaysInEditions[playID] = true
        }
        
        init(name: String){ 
            pre{ 
                !AllDay.setIDByName.containsKey(name):
                    "A Set with that name already exists"
            }
            self.id = AllDay.nextSetID
            self.name = name
            self.setPlaysInEditions ={} 
            AllDay.setIDByName[name] = self.id
            AllDay.nextSetID = self.id + 1 as UInt64
            emit SetCreated(id: self.id, name: self.name)
        }
    }
    
    pub fun getSetData(id: UInt64): AllDay.SetData{ 
        pre{ 
            AllDay.setByID[id] != nil:
                "Cannot borrow set, no such id"
        }
        return AllDay.SetData(id: id)
    }
    
    pub fun getSetDataByName(name: String): AllDay.SetData{ 
        pre{ 
            AllDay.setIDByName[name] != nil:
                "Cannot borrow set, no such name"
        }
        let id = AllDay.setIDByName[name]!
        return AllDay.SetData(id: id)
    }
    
    pub fun getAllSetNames(): [String]{ 
        return AllDay.setIDByName.keys
    }
    
    pub struct PlayData{ 
        pub let id: UInt64
        
        pub let classification: String
        
        pub let metadata:{ String: String}
        
        init(id: UInt64){ 
            let play = &AllDay.playByID[id] as &AllDay.Play
            self.id = id
            self.classification = play.classification
            self.metadata = play.metadata
        }
    }
    
    pub resource Play{ 
        pub let id: UInt64
        
        pub let classification: String
        
        pub let metadata:{ String: String}
        
        init(classification: String, metadata:{ String: String}){ 
            self.id = AllDay.nextPlayID
            self.classification = classification
            self.metadata = metadata
            AllDay.nextPlayID = self.id + 1 as UInt64
            emit PlayCreated(id: self.id, classification: self.classification, metadata: self.metadata)
        }
    }
    
    pub fun getPlayData(id: UInt64): AllDay.PlayData{ 
        pre{ 
            AllDay.playByID[id] != nil:
                "Cannot borrow play, no such id"
        }
        return AllDay.PlayData(id: id)
    }
    
    pub struct EditionData{ 
        pub let id: UInt64
        
        pub let seriesID: UInt64
        
        pub let setID: UInt64
        
        pub let playID: UInt64
        
        pub var maxMintSize: UInt64?
        
        pub let tier: String
        
        pub var numMinted: UInt64
        
        pub fun maxEditionMintSizeReached(): Bool{ 
            return self.numMinted == self.maxMintSize
        }
        
        init(id: UInt64){ 
            let edition = &AllDay.editionByID[id] as &AllDay.Edition
            self.id = id
            self.seriesID = edition.seriesID
            self.playID = edition.playID
            self.setID = edition.setID
            self.maxMintSize = edition.maxMintSize
            self.tier = edition.tier
            self.numMinted = edition.numMinted
        }
    }
    
    pub resource Edition{ 
        pub let id: UInt64
        
        pub let seriesID: UInt64
        
        pub let setID: UInt64
        
        pub let playID: UInt64
        
        pub let tier: String
        
        pub var maxMintSize: UInt64?
        
        pub var numMinted: UInt64
        
        access(contract) fun close(){ 
            pre{ 
                self.numMinted != self.maxMintSize:
                    "max number of minted moments has already been reached"
            }
            self.maxMintSize = self.numMinted
            emit EditionClosed(id: self.id)
        }
        
        pub fun mint(): @AllDay.NFT{ 
            pre{ 
                self.numMinted != self.maxMintSize:
                    "max number of minted moments has been reached"
            }
            let momentNFT <- create NFT(id: AllDay.totalSupply + 1, editionID: self.id, serialNumber: self.numMinted + 1)
            AllDay.totalSupply = AllDay.totalSupply + 1
            self.numMinted = self.numMinted + 1 as UInt64
            return <-momentNFT
        }
        
        init(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String){ 
            pre{ 
                maxMintSize != 0:
                    "max mint size is zero, must either be null or greater than 0"
                AllDay.seriesByID.containsKey(seriesID):
                    "seriesID does not exist"
                AllDay.setByID.containsKey(setID):
                    "setID does not exist"
                AllDay.playByID.containsKey(playID):
                    "playID does not exist"
                SeriesData(id: seriesID).active == true:
                    "cannot create an Edition with a closed Series"
                SetData(id: setID).setPlayExistsInEdition(playID: playID) != true:
                    "set play combination already exists in an edition"
            }
            self.id = AllDay.nextEditionID
            self.seriesID = seriesID
            self.setID = setID
            self.playID = playID
            if maxMintSize == 0{ 
                self.maxMintSize = nil
            } else{ 
                self.maxMintSize = maxMintSize
            }
            self.tier = tier
            self.numMinted = 0 as UInt64
            AllDay.nextEditionID = AllDay.nextEditionID + 1 as UInt64
            AllDay.setByID[setID]?.insertNewPlay(playID: playID)
            emit EditionCreated(id: self.id, seriesID: self.seriesID, setID: self.setID, playID: self.playID, maxMintSize: self.maxMintSize, tier: self.tier)
        }
    }
    
    pub fun getEditionData(id: UInt64): EditionData{ 
        pre{ 
            AllDay.editionByID[id] != nil:
                "Cannot borrow edition, no such id"
        }
        return AllDay.EditionData(id: id)
    }
    
    pub resource NFT: NonFungibleToken.INFT{ 
        pub let id: UInt64
        
        pub let editionID: UInt64
        
        pub let serialNumber: UInt64
        
        pub let mintingDate: UFix64
        
        destroy(){ 
            emit MomentNFTBurned(id: self.id)
        }
        
        init(id: UInt64, editionID: UInt64, serialNumber: UInt64){ 
            pre{ 
                AllDay.editionByID[editionID] != nil:
                    "no such editionID"
                EditionData(id: editionID).maxEditionMintSizeReached() != true:
                    "max edition size already reached"
            }
            self.id = id
            self.editionID = editionID
            self.serialNumber = serialNumber
            self.mintingDate = getCurrentBlock().timestamp
            emit MomentNFTMinted(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
        }
    }
    
    pub resource interface MomentNFTCollectionPublic{ 
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection){} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowMomentNFT(id: UInt64): &AllDay.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Moment NFT reference: The ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MomentNFTCollectionPublic{ 
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @AllDay.NFT
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
        
        pub fun borrowMomentNFT(id: UInt64): &AllDay.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &AllDay.NFT
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
        pub fun mintNFT(editionID: UInt64): @AllDay.NFT{} 
    }
    
    pub resource Admin: NFTMinter{ 
        pub fun borrowSeries(id: UInt64): &AllDay.Series{ 
            pre{ 
                AllDay.seriesByID[id] != nil:
                    "Cannot borrow series, no such id"
            }
            return &AllDay.seriesByID[id] as &AllDay.Series
        }
        
        pub fun borrowSet(id: UInt64): &AllDay.Set{ 
            pre{ 
                AllDay.setByID[id] != nil:
                    "Cannot borrow Set, no such id"
            }
            return &AllDay.setByID[id] as &AllDay.Set
        }
        
        pub fun borrowPlay(id: UInt64): &AllDay.Play{ 
            pre{ 
                AllDay.playByID[id] != nil:
                    "Cannot borrow Play, no such id"
            }
            return &AllDay.playByID[id] as &AllDay.Play
        }
        
        pub fun borrowEdition(id: UInt64): &AllDay.Edition{ 
            pre{ 
                AllDay.editionByID[id] != nil:
                    "Cannot borrow edition, no such id"
            }
            return &AllDay.editionByID[id] as &AllDay.Edition
        }
        
        pub fun createSeries(name: String): UInt64{ 
            let series <- create AllDay.Series(name: name)
            let seriesID = series.id
            AllDay.seriesByID[series.id] <-! series
            return seriesID
        }
        
        pub fun closeSeries(id: UInt64): UInt64{ 
            let series = &AllDay.seriesByID[id] as &AllDay.Series
            series.close()
            return series.id
        }
        
        pub fun createSet(name: String): UInt64{ 
            let set <- create AllDay.Set(name: name)
            let setID = set.id
            AllDay.setByID[set.id] <-! set
            return setID
        }
        
        pub fun createPlay(classification: String, metadata:{ String: String}): UInt64{ 
            let play <- create AllDay.Play(classification: classification, metadata: metadata)
            let playID = play.id
            AllDay.playByID[play.id] <-! play
            return playID
        }
        
        pub fun createEdition(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String): UInt64{ 
            let edition <- create Edition(seriesID: seriesID, setID: setID, playID: playID, maxMintSize: maxMintSize, tier: tier)
            let editionID = edition.id
            AllDay.editionByID[edition.id] <-! edition
            return editionID
        }
        
        pub fun closeEdition(id: UInt64): UInt64{ 
            let edition = &AllDay.editionByID[id] as &AllDay.Edition
            edition.close()
            return edition.id
        }
        
        pub fun mintNFT(editionID: UInt64): @AllDay.NFT{ 
            pre{ 
                AllDay.editionByID.containsKey(editionID):
                    "No such EditionID"
            }
            return <-self.borrowEdition(id: editionID).mint()
        }
    }
    
    init(){ 
        self.CollectionStoragePath = /storage/AllDayNFTCollection
        self.CollectionPublicPath = /public/AllDayNFTCollection
        self.AdminStoragePath = /storage/AllDayAdmin
        self.MinterPrivatePath = /private/AllDayMinter
        self.totalSupply = 0
        self.nextSeriesID = 1
        self.nextSetID = 1
        self.nextPlayID = 1
        self.nextEditionID = 1
        self.seriesByID <-{} 
        self.seriesIDByName ={} 
        self.setIDByName ={} 
        self.setByID <-{} 
        self.playByID <-{} 
        self.editionByID <-{} 
        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)
        self.account.link<&AllDay.Admin{AllDay.NFTMinter}>(self.MinterPrivatePath, target: self.AdminStoragePath)
        emit ContractInitialized()
    }
}
