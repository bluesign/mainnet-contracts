/*
    Adapted from: AllDay.cdc
    Author: Innocent Abdullahi innocent.abdullahi@dapperlabs.com
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

/*
    DapperSport is structured similarly to AllDay.
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

/// The DapperSport NFTs and metadata contract
//
pub contract DapperSport: NonFungibleToken{ 
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
    /// Emitted when a new series has been created by an admin
    pub event SeriesCreated(id: UInt64, name: String)
    
    /// Emitted when a series is closed by an admin
    pub event SeriesClosed(id: UInt64)
    
    // Set Events
    //
    /// Emitted when a new set has been created by an admin
    pub event SetCreated(id: UInt64, name: String)
    
    /// Emitted when a Set is locked, meaning Editions cannot be created with the set
    pub event SetLocked(setID: UInt64)
    
    // Play Events
    //
    /// Emitted when a new play has been created by an admin
    pub event PlayCreated(id: UInt64, classification: String, metadata:{ String: String})
    
    // Edition Events
    //
    /// Emitted when a new edition has been created by an admin
    pub event EditionCreated(id: UInt64, seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String)
    
    /// Emitted when an edition is either closed by an admin, or the max amount of moments have been minted
    pub event EditionClosed(id: UInt64)
    
    // NFT Events
    //
    /// Emitted when a moment nft is minted
    pub event MomentNFTMinted(id: UInt64, editionID: UInt64, serialNumber: UInt64)
    
    /// Emitted when a moment nft resource is destroyed
    pub event MomentNFTBurned(id: UInt64, editionID: UInt64, serialNumber: UInt64)
    
    //------------------------------------------------------------
    // Named values
    //------------------------------------------------------------
    
    /// Named Paths
    ///
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let AdminStoragePath: StoragePath
    
    pub let MinterPrivatePath: PrivatePath
    
    //------------------------------------------------------------
    // Publicly readable contract state
    //------------------------------------------------------------
    
    /// Entity Counts
    ///
    pub var totalSupply: UInt64
    
    pub var nextSeriesID: UInt64
    
    pub var nextSetID: UInt64
    
    pub var nextPlayID: UInt64
    
    pub var nextEditionID: UInt64
    
    //------------------------------------------------------------
    // Internal contract state
    //------------------------------------------------------------
    
    /// Metadata Dictionaries
    ///
    /// This is so we can find Series by their names (via seriesByID)
    priv let seriesIDByName:{ String: UInt64}
    
    priv let seriesByID: @{UInt64: Series}
    
    priv let setIDByName:{ String: UInt64}
    
    priv let setByID: @{UInt64: Set}
    
    priv let playByID: @{UInt64: Play}
    
    priv let editionByID: @{UInt64: Edition}
    
    //------------------------------------------------------------
    // Series
    //------------------------------------------------------------
    
    /// A public struct to access Series data
    ///
    pub struct SeriesData{ 
        pub let id: UInt64
        
        pub let name: String
        
        pub let active: Bool
        
        /// initializer
        //
        init(id: UInt64){ 
            let series = (&DapperSport.seriesByID[id] as                                                         
                                                         /// A top-level Series with a unique ID and name
                                                         ///
                                                         
                                                         /// Close this series
                                                         ///
                                                         
                                                         /// initializer
                                                         ///
                                                         
                                                         // Cache the new series's name => ID
                                                         // Increment for the nextSeriesID
                                                         
                                                         /// Get the publicly available data for a Series by id
                                                         ///
                                                         
                                                         /// Get the publicly available data for a Series by name
                                                         ///
                                                         
                                                         /// Get all series names (this will be *long*)
                                                         ///
                                                         
                                                         /// Get series id by name
                                                         ///
                                                         
                                                         //------------------------------------------------------------
                                                         // Set
                                                         //------------------------------------------------------------
                                                         
                                                         
                                                         /// A public struct to access Set data
                                                         ///
                                                         
                                                         /// member function to check the setPlaysInEditions to see if this Set/Play combination already exists
                                                         
                                                         /// initializer
                                                         ///
                                                         &DapperSport.Series?)!
            self.id = series.id
            self.name = series.name
            self.active = series.active
        }
    }
    
    /// A top level Set with a unique ID and a name
    ///
    pub resource Series{ 
        pub let id: UInt64
        
        pub let name: String
        
        /// Store a dictionary of all the Plays which are paired with the Set inside Editions
        /// This enforces only one Set/Play unique pair can be used for an Edition
        pub var active: Bool
        
        pub            
            // Indicates if the Set is currently locked.
            // When a Set is created, it is unlocked
            // and Editions can be created with it.
            // When a Set is locked, new Editions cannot be created with the Set.
            // A Set can never be changed from locked to unlocked,
            // the decision to lock a Set is final.
            // If a Set is locked, Moments can still be minted from the
            // Editions already created from the Set.
            fun close(){ 
            pre{ 
                self                    
                    /// member function to insert a new Play to the setPlaysInEditions dictionary
                    .active                            
                            /// returns the plays added to the set in an edition
                            
                            /// initializer
                            ///
                            
                            // Cache the new set's name => ID
                            // Increment for the nextSeriesID
                            
                            // lock() locks the Set so that no more Plays can be added to it
                            //
                            // Pre-Conditions:
                            // The Set should not be locked
                            
                            /// Get the publicly available data for a Set
                            ///
                            == true:
                    
                    /// Get the publicly available data for a Set by name
                    ///
                    
                    /// Get all set names (this will be *long*)
                    ///
                    
                    //------------------------------------------------------------
                    // Play
                    //------------------------------------------------------------
                    
                    
                    /// A public struct to access Play data
                    ///
                    
                    /// initializer
                    ///
                    
                    /// A top level Play with a unique ID and a classification
                    //
                    
                    /// returns the metadata set for this play
                    
                    /// initializer
                    ///
                    
                    /// Get the publicly available data for a Play
                    ///
                    
                    //------------------------------------------------------------
                    // Edition
                    //------------------------------------------------------------
                    
                    
                    /// A public struct to access Edition data
                    ///
                    
                    /// member function to check if max edition size has been reached
                    
                    /// initializer
                    ///
                    
                    /// A top level Edition that contains a Series, Set, and Play
                    ///
                    /// Null value indicates that there is unlimited minting potential for the Edition
                    /// Updates each time we mint a new moment for the Edition to keep a running total
                    
                    /// Close this edition so that no more Moment NFTs can be minted in it
                    ///
                    "series is not active"
            }
            self.active = false
            emit SeriesClosed(id: self.id)
        }
        
        /// Mint a Moment NFT in this edition, with the given minting mintingDate.
        /// Note that this will panic if the max mint size has already been reached.
        ///
        init(name: String){ 
            pre{ 
                
                // Create the Moment NFT, filled out with our information
                // Keep a running total (you'll notice we used this as the serial number)
                
                /// initializer
                ///
                !DapperSport.seriesIDByName.containsKey(name):
                    "A Series with that name already exists"
            }
            self.id = DapperSport.nextSeriesID
            self.name = name
            self.active = true
            DapperSport.seriesIDByName[name]                                             
                                             // If an edition size is not set, it has unlimited minting potential
                                             = self.id
            DapperSport.nextSeriesID = self.id + 1 as UInt64
            emit SeriesCreated(id: self.id, name: self.name)
        }
    }
    
    /// Get the publicly available data for an Edition
    ///
    pub fun getSeriesData(id: UInt64): DapperSport.SeriesData{ 
        pre{ 
            DapperSport.seriesByID[id]                                       
                                       //------------------------------------------------------------
                                       // NFT
                                       //------------------------------------------------------------
                                       
                                       
                                       /// A Moment NFT
                                       ///
                                       
                                       /// Destructor
                                       ///
                                       
                                       /// NFT initializer
                                       ///
                                       != nil:
                "Cannot borrow series, no such id"
        }
        return DapperSport.SeriesData(id: id)
    }
    
    /// get the name of an nft
    ///
    pub fun getSeriesDataByName(name: String): DapperSport.SeriesData                                                                     
                                                                     /// get the description of an nft
                                                                     ///
                                                                     
                                                                     /// get a thumbnail image that represents this nft
                                                                     ///
                                                                     // TODO: change to image for DapperSport
                                                                     
                                                                     /// get the metadata view types available for this nft
                                                                     ///
                                                                     
                                                                     /// resolve a metadata view type returning the properties of the view type
                                                                     ///
                                                                     ?{ 
        let id = DapperSport.seriesIDByName[name]
        if id              
              //------------------------------------------------------------
              // Collection
              //------------------------------------------------------------
              
              
              /// A public collection interface that allows Moment NFTs to be borrowed
              ///
              // If the result isn't nil, the id of the returned reference
              // should be the same as the argument to the function
              == nil{ 
            return nil
        }
        
        /// An NFT Collection
        ///
        return DapperSport.SeriesData(id                                        /// dictionary of NFT conforming tokens
                                        /// NFT is a resource type with an UInt64 ID field
                                        ///
                                        : id                                            
                                            /// withdraw removes an NFT from the collection and moves it to the caller
                                            ///
                                            
                                            /// deposit takes a NFT and adds it to the collections dictionary
                                            /// and adds the ID to the id array
                                            ///
                                            
                                            // add the new token to the dictionary which removes the old one
                                            
                                            /// batchDeposit takes a Collection object as an argument
                                            /// and deposits each contained NFT into this Collection
                                            ///
                                            // Get an array of the IDs to be deposited
                                            
                                            // Iterate through the keys in the collection and deposit each one
                                            
                                            // Destroy the empty Collection
                                            
                                            /// getIDs returns an array of the IDs that are in the collection
                                            ///
                                            
                                            /// borrowNFT gets a reference to an NFT in the collection
                                            //
                                            !)
    }
    
    /// borrowMomentNFT gets a reference to an NFT in the collection
    ///
    pub fun getAllSeriesNames(): [String]{ 
        return DapperSport.seriesIDByName.keys
    }
    
    pub fun getSeriesIDByName(name: String): UInt64?{ 
        return DapperSport.seriesIDByName[name]
    }
    
    /// Collection destructor
    ///
    pub struct SetData{ 
        pub            
            /// Collection initializer
            ///
            let id                  
                  /// public function that anyone can call to create a new empty collection
                  ///
                  : UInt64
        
        pub let name                    
                    //------------------------------------------------------------
                    // Admin
                    //------------------------------------------------------------
                    
                    
                    /// An interface containing the Admin function that allows minting NFTs
                    ///
                    // Mint a single NFT
                    // The Edition for the given ID must already exist
                    //
                    : String
        
        pub let                
                /// A resource that allows managing metadata and minting NFTs
                ///
                locked: Bool
        
        /// Borrow a Series
        ///
        pub var setPlaysInEditions:{ UInt64: Bool}
        
        pub fun setPlayExistsInEdition(playID                                             
                                             /// Borrow a Set
                                             ///
                                             : UInt64): Bool{ 
            return self.setPlaysInEditions.containsKey(playID)
        }
        
        /// Borrow a Play
        ///
        init(id: UInt64){ 
            let set                    
                    /// Borrow an Edition
                    ///
                    
                    /// Create a Series
                    ///
                    // Create and store the new series
                    = (                       
                       // Return the new ID for convenience
                       
                       /// Close a Series
                       ///
                       &DapperSport.setByID[id] as &DapperSport.Set?)!
            self.id                    
                    /// Create a Set
                    ///
                    // Create and store the new set
                    = id
            self.name                      
                      // Return the new ID for convenience
                      
                      /// Locks a Set
                      ///
                      = set.name
            self.locked                        
                        /// Create a Play
                        ///
                        // Create and store the new play
                        = set.locked
            self.setPlaysInEditions                                    
                                    // Return the new ID for convenience
                                    
                                    /// Create an Edition
                                    ///
                                    = set.getSetPlaysInEditions()
        }
    
    /// Close an Edition
    ///
    }
    
    /// Mint a single NFT
    /// The Edition for the given ID must already exist
    ///
    pub resource Set{ 
        pub let id                  // Make sure the edition we are creating this NFT in exists
                  : UInt64
        
        pub let name: String
        
        priv             
             //------------------------------------------------------------
             // Contract lifecycle
             //------------------------------------------------------------
             
             
             /// DapperSport contract initializer
             ///
             var                 // Set the named paths
                 setPlaysInEditions                                   
                                   // Initialize the entity counts
                                   
                                   // Initialize the metadata lookup dictionaries
                                   
                                   // Create an Admin resource and save it to storage
                                   :{ UInt64                                            // Link capabilites to the admin constrained to the Minter
                                            // and Metadata interfaces
                                            : Bool                                                  
                                                  // Let the world know we are here
                                                  }
        
        pub var locked: Bool
        
        pub fun insertNewPlay(playID: UInt64){ 
            self.setPlaysInEditions[playID] = true
        }
        
        pub fun getSetPlaysInEditions():{ UInt64: Bool}{ 
            return self.setPlaysInEditions
        }
        
        init(name: String){ 
            pre{ 
                !DapperSport.setIDByName.containsKey(name):
                    "A Set with that name already exists"
            }
            self.id = DapperSport.nextSetID
            self.name = name
            self.setPlaysInEditions ={} 
            self.locked = false
            DapperSport.setIDByName[name] = self.id
            DapperSport.nextSetID = self.id + 1 as UInt64
            emit SetCreated(id: self.id, name: self.name)
        }
        
        pub fun lock(){ 
            if !self.locked{ 
                self.locked = true
                emit SetLocked(setID: self.id)
            }
        }
    }
    
    pub fun getSetData(id: UInt64): DapperSport.SetData?{ 
        if DapperSport.setByID[id] == nil{ 
            return nil
        }
        return DapperSport.SetData(id: id!)
    }
    
    pub fun getSetDataByName(name: String): DapperSport.SetData?{ 
        let id = DapperSport.setIDByName[name]
        if id == nil{ 
            return nil
        }
        return DapperSport.SetData(id: id!)
    }
    
    pub fun getAllSetNames(): [String]{ 
        return DapperSport.setIDByName.keys
    }
    
    pub struct PlayData{ 
        pub let id: UInt64
        
        pub let classification: String
        
        pub let metadata:{ String: String}
        
        init(id: UInt64){ 
            let play = (&DapperSport.playByID[id] as &DapperSport.Play?)!
            self.id = id
            self.classification = play.classification
            self.metadata = play.getMetadata()
        }
    }
    
    pub resource Play{ 
        pub let id: UInt64
        
        pub let classification: String
        
        priv let metadata:{ String: String}
        
        pub fun getMetadata():{ String: String}{ 
            return self.metadata
        }
        
        init(classification: String, metadata:{ String: String}){ 
            self.id = DapperSport.nextPlayID
            self.classification = classification
            self.metadata = metadata
            DapperSport.nextPlayID = self.id + 1 as UInt64
            emit PlayCreated(id: self.id, classification: self.classification, metadata: self.metadata)
        }
    }
    
    pub fun getPlayData(id: UInt64): DapperSport.PlayData?{ 
        if DapperSport.playByID[id] == nil{ 
            return nil
        }
        return DapperSport.PlayData(id: id!)
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
            let edition = (&DapperSport.editionByID[id] as &DapperSport.Edition?)!
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
        
        pub fun mint(): @DapperSport.NFT{ 
            pre{ 
                self.numMinted != self.maxMintSize:
                    "max number of minted moments has been reached"
            }
            let momentNFT <- create NFT(editionID: self.id, serialNumber: self.numMinted + 1)
            DapperSport.totalSupply = DapperSport.totalSupply + 1
            self.numMinted = self.numMinted + 1 as UInt64
            return <-momentNFT
        }
        
        init(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String){ 
            pre{ 
                maxMintSize != 0:
                    "max mint size is zero, must either be null or greater than 0"
                DapperSport.seriesByID.containsKey(seriesID):
                    "seriesID does not exist"
                DapperSport.setByID.containsKey(setID):
                    "setID does not exist"
                DapperSport.playByID.containsKey(playID):
                    "playID does not exist"
                (DapperSport.getSeriesData(id: seriesID)!).active == true:
                    "cannot create an Edition with a closed Series"
                (DapperSport.getSetData(id: setID)!).locked == false:
                    "cannot create an Edition with a locked Set"
                (DapperSport.getSetData(id: setID)!).setPlayExistsInEdition(playID: playID) == false:
                    "set play combination already exists in an edition"
            }
            self.id = DapperSport.nextEditionID
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
            DapperSport.nextEditionID = DapperSport.nextEditionID + 1 as UInt64
            DapperSport.setByID[setID]?.insertNewPlay(playID: playID)
            emit EditionCreated(id: self.id, seriesID: self.seriesID, setID: self.setID, playID: self.playID, maxMintSize: self.maxMintSize, tier: self.tier)
        }
    }
    
    pub fun getEditionData(id: UInt64): EditionData?{ 
        if DapperSport.editionByID[id] == nil{ 
            return nil
        }
        return DapperSport.EditionData(id: id)
    }
    
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver{ 
        pub let id: UInt64
        
        pub let editionID: UInt64
        
        pub let serialNumber: UInt64
        
        pub let mintingDate: UFix64
        
        destroy(){ 
            emit MomentNFTBurned(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
        }
        
        init(editionID: UInt64, serialNumber: UInt64){ 
            pre{ 
                DapperSport.editionByID[editionID] != nil:
                    "no such editionID"
                EditionData(id: editionID).maxEditionMintSizeReached() != true:
                    "max edition size already reached"
            }
            self.id = self.uuid
            self.editionID = editionID
            self.serialNumber = serialNumber
            self.mintingDate = getCurrentBlock().timestamp
            emit MomentNFTMinted(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
        }
        
        pub fun name(): String{ 
            let editionData = DapperSport.getEditionData(id: self.editionID)!
            let fullName: String = DapperSport.PlayData(id: editionData.playID).metadata["PlayerJerseyName"] ?? ""
            let playType: String = DapperSport.PlayData(id: editionData.playID).metadata["PlayType"] ?? ""
            return fullName.concat(" ").concat(playType)
        }
        
        pub fun description(): String{ 
            let editionData = DapperSport.getEditionData(id: self.editionID)!
            let setName: String = (DapperSport.SetData(id: editionData.setID)!).name
            let serialNumber: String = self.serialNumber.toString()
            let seriesNumber: String = editionData.seriesID.toString()
            return "A series ".concat(seriesNumber).concat(" ").concat(setName).concat(" moment with serial number ").concat(serialNumber)
        }
        
        pub fun thumbnail(): MetadataViews.HTTPFile{ 
            let editionData = DapperSport.getEditionData(id: self.editionID)!
            switch editionData.tier{ 
                default:
                    return MetadataViews.HTTPFile(url: "https://ipfs.dapperlabs.com/ipfs/QmPvr5zTwji1UGpun57cbj719MUBsB5syjgikbwCMPmruQ")
            }
        }
        
        pub fun getViews(): [Type]{ 
            return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Traits>()]
        }
        
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            switch view{ 
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: self.thumbnail())
                case Type<MetadataViews.Editions>():
                    let editionData = DapperSport.getEditionData(id: self.editionID)!
                    let editionInfo = MetadataViews.Edition(name: nil, number: editionData.id, max: editionData.maxMintSize)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(editionList)
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.serialNumber)
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(storagePath: DapperSport.CollectionStoragePath, publicPath: DapperSport.CollectionPublicPath, providerPath: /private/dapperSportCollection, publicCollection: Type<&DapperSport.Collection{DapperSport.MomentNFTCollectionPublic}>(), publicLinkedType: Type<&DapperSport.Collection{DapperSport.MomentNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(), providerLinkedType: Type<&DapperSport.Collection{DapperSport.MomentNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(), createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection{ 
                            return <-DapperSport.createEmptyCollection()
                        })
                case Type<MetadataViews.Traits>():
                    let editiondata = DapperSport.getEditionData(id: self.editionID)!
                    let playdata = DapperSport.getPlayData(id: editiondata.playID)!
                    return MetadataViews.dictToTraits(dict: playdata.metadata, excludedNames: nil)
            }
            return nil
        }
    }
    
    pub resource interface MomentNFTCollectionPublic{ 
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection){} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowMomentNFT(id: UInt64): &DapperSport.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Moment NFT reference: The ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MomentNFTCollectionPublic, MetadataViews.ResolverCollection{ 
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @DapperSport.NFT
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
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
        
        pub fun borrowMomentNFT(id: UInt64): &DapperSport.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &DapperSport.NFT
            } else{ 
                return nil
            }
        }
        
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{ 
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let dapperSportNFT = nft as! &DapperSport.NFT
            return dapperSportNFT as &AnyResource{MetadataViews.Resolver}
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
        pub fun mintNFT(editionID: UInt64): @DapperSport.NFT{} 
    }
    
    pub resource Admin: NFTMinter{ 
        pub fun borrowSeries(id: UInt64): &DapperSport.Series{ 
            pre{ 
                DapperSport.seriesByID[id] != nil:
                    "Cannot borrow series, no such id"
            }
            return (&DapperSport.seriesByID[id] as &DapperSport.Series?)!
        }
        
        pub fun borrowSet(id: UInt64): &DapperSport.Set{ 
            pre{ 
                DapperSport.setByID[id] != nil:
                    "Cannot borrow Set, no such id"
            }
            return (&DapperSport.setByID[id] as &DapperSport.Set?)!
        }
        
        pub fun borrowPlay(id: UInt64): &DapperSport.Play{ 
            pre{ 
                DapperSport.playByID[id] != nil:
                    "Cannot borrow Play, no such id"
            }
            return (&DapperSport.playByID[id] as &DapperSport.Play?)!
        }
        
        pub fun borrowEdition(id: UInt64): &DapperSport.Edition{ 
            pre{ 
                DapperSport.editionByID[id] != nil:
                    "Cannot borrow edition, no such id"
            }
            return (&DapperSport.editionByID[id] as &DapperSport.Edition?)!
        }
        
        pub fun createSeries(name: String): UInt64{ 
            let series <- create DapperSport.Series(name: name)
            let seriesID = series.id
            DapperSport.seriesByID[series.id] <-! series
            return seriesID
        }
        
        pub fun closeSeries(id: UInt64): UInt64{ 
            let series = (&DapperSport.seriesByID[id] as &DapperSport.Series?)!
            series.close()
            return series.id
        }
        
        pub fun createSet(name: String): UInt64{ 
            let set <- create DapperSport.Set(name: name)
            let setID = set.id
            DapperSport.setByID[set.id] <-! set
            return setID
        }
        
        pub fun lockSet(id: UInt64): UInt64{ 
            let set = (&DapperSport.setByID[id] as &DapperSport.Set?)!
            set.lock()
            return set.id
        }
        
        pub fun createPlay(classification: String, metadata:{ String: String}): UInt64{ 
            let play <- create DapperSport.Play(classification: classification, metadata: metadata)
            let playID = play.id
            DapperSport.playByID[play.id] <-! play
            return playID
        }
        
        pub fun createEdition(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String): UInt64{ 
            let edition <- create Edition(seriesID: seriesID, setID: setID, playID: playID, maxMintSize: maxMintSize, tier: tier)
            let editionID = edition.id
            DapperSport.editionByID[edition.id] <-! edition
            return editionID
        }
        
        pub fun closeEdition(id: UInt64): UInt64{ 
            let edition = (&DapperSport.editionByID[id] as &DapperSport.Edition?)!
            edition.close()
            return edition.id
        }
        
        pub fun mintNFT(editionID: UInt64): @DapperSport.NFT{ 
            pre{ 
                DapperSport.editionByID.containsKey(editionID):
                    "No such EditionID"
            }
            return <-self.borrowEdition(id: editionID).mint()
        }
    }
    
    init(){ 
        self.CollectionStoragePath = /storage/DapperSportNFTCollection
        self.CollectionPublicPath = /public/DapperSportNFTCollection
        self.AdminStoragePath = /storage/DapperSportAdmin
        self.MinterPrivatePath = /private/DapperSportMinter
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
        self.account.link<&DapperSport.Admin{DapperSport.NFTMinter}>(self.MinterPrivatePath, target: self.AdminStoragePath)
        emit ContractInitialized()
    }
}
