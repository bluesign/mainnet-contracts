/*
    Adapted from: AllDay.cdc
    Author: Innocent Abdullahi innocent.abdullahi@dapperlabs.com
*/

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

/*
    Golazos is structured similarly to AllDay.
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

/// The Golazos NFTs and metadata contract
//
pub contract Golazos: NonFungibleToken{ 
    // -----------------------------------------------------------------------
    // Golazos deployment variables
    // -----------------------------------------------------------------------
    
    pub fun RoyaltyAddress(): Address{ 
        return 0x87ca73a41bb50ad5
    }
    
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
            let series = (&Golazos.seriesByID[id] as                                                     
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
                                                     &Golazos.Series?)!
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
                !Golazos.seriesIDByName.containsKey(name):
                    "A Series with that name already exists"
            }
            self.id = Golazos.nextSeriesID
            self.name = name
            self.active = true
            Golazos.seriesIDByName[name]                                         
                                         // If an edition size is not set, it has unlimited minting potential
                                         = self.id
            Golazos.nextSeriesID = self.id + 1 as UInt64
            emit SeriesCreated(id: self.id, name: self.name)
        }
    }
    
    /// Get the publicly available data for an Edition
    ///
    pub fun getSeriesData(id: UInt64): Golazos.SeriesData{ 
        pre{ 
            Golazos.seriesByID[id]                                   
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
        return Golazos.SeriesData(id: id)
    }
    
    pub fun getSeriesDataByName(name: String): Golazos.SeriesData                                                                 
                                                                 /// get the name of an nft
                                                                 ///
                                                                 
                                                                 /// get the description of an nft
                                                                 ///
                                                                 
                                                                 /// get a thumbnail image that represents this nft
                                                                 ///
                                                                 
                                                                 /// get the metadata view types available for this nft
                                                                 ///
                                                                 
                                                                 /// resolve a metadata view type returning the properties of the view type
                                                                 ///
                                                                 ?{ 
        let id = Golazos.seriesIDByName[name]
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
        return Golazos.SeriesData(id                                    /// dictionary of NFT conforming tokens
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
        return Golazos.seriesIDByName.keys
    }
    
    pub fun getSeriesIDByName(name: String): UInt64?{ 
        return Golazos.seriesIDByName[name]
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
                       &Golazos.setByID[id] as &Golazos.Set?)!
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
             
             
             /// Golazos contract initializer
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
                !Golazos.setIDByName.containsKey(name):
                    "A Set with that name already exists"
            }
            self.id = Golazos.nextSetID
            self.name = name
            self.setPlaysInEditions ={} 
            self.locked = false
            Golazos.setIDByName[name] = self.id
            Golazos.nextSetID = self.id + 1 as UInt64
            emit SetCreated(id: self.id, name: self.name)
        }
        
        pub fun lock(){ 
            if !self.locked{ 
                self.locked = true
                emit SetLocked(setID: self.id)
            }
        }
    }
    
    pub fun getSetData(id: UInt64): Golazos.SetData?{ 
        if Golazos.setByID[id] == nil{ 
            return nil
        }
        return Golazos.SetData(id: id!)
    }
    
    pub fun getSetDataByName(name: String): Golazos.SetData?{ 
        let id = Golazos.setIDByName[name]
        if id == nil{ 
            return nil
        }
        return Golazos.SetData(id: id!)
    }
    
    pub fun getAllSetNames(): [String]{ 
        return Golazos.setIDByName.keys
    }
    
    pub struct PlayData{ 
        pub let id: UInt64
        
        pub let classification: String
        
        pub let metadata:{ String: String}
        
        init(id: UInt64){ 
            let play = (&Golazos.playByID[id] as &Golazos.Play?)!
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
            self.id = Golazos.nextPlayID
            self.classification = classification
            self.metadata = metadata
            Golazos.nextPlayID = self.id + 1 as UInt64
            emit PlayCreated(id: self.id, classification: self.classification, metadata: self.metadata)
        }
    }
    
    pub fun getPlayData(id: UInt64): Golazos.PlayData?{ 
        if Golazos.playByID[id] == nil{ 
            return nil
        }
        return Golazos.PlayData(id: id!)
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
            let edition = (&Golazos.editionByID[id] as &Golazos.Edition?)!
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
        
        pub fun mint(): @Golazos.NFT{ 
            pre{ 
                self.numMinted != self.maxMintSize:
                    "max number of minted moments has been reached"
            }
            let momentNFT <- create NFT(editionID: self.id, serialNumber: self.numMinted + 1)
            Golazos.totalSupply = Golazos.totalSupply + 1
            self.numMinted = self.numMinted + 1 as UInt64
            return <-momentNFT
        }
        
        init(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String){ 
            pre{ 
                maxMintSize != 0:
                    "max mint size is zero, must either be null or greater than 0"
                Golazos.seriesByID.containsKey(seriesID):
                    "seriesID does not exist"
                Golazos.setByID.containsKey(setID):
                    "setID does not exist"
                Golazos.playByID.containsKey(playID):
                    "playID does not exist"
                (Golazos.getSeriesData(id: seriesID)!).active == true:
                    "cannot create an Edition with a closed Series"
                (Golazos.getSetData(id: setID)!).locked == false:
                    "cannot create an Edition with a locked Set"
                (Golazos.getSetData(id: setID)!).setPlayExistsInEdition(playID: playID) == false:
                    "set play combination already exists in an edition"
            }
            self.id = Golazos.nextEditionID
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
            Golazos.nextEditionID = Golazos.nextEditionID + 1 as UInt64
            Golazos.setByID[setID]?.insertNewPlay(playID: playID)
            emit EditionCreated(id: self.id, seriesID: self.seriesID, setID: self.setID, playID: self.playID, maxMintSize: self.maxMintSize, tier: self.tier)
        }
    }
    
    pub fun getEditionData(id: UInt64): EditionData?{ 
        if Golazos.editionByID[id] == nil{ 
            return nil
        }
        return Golazos.EditionData(id: id)
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
                Golazos.editionByID[editionID] != nil:
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
        
        pub fun assetPath(): String{ 
            let editionData = Golazos.getEditionData(id: self.editionID)!
            let playDataID: String = Golazos.PlayData(id: editionData.playID).metadata["PlayDataID"] ?? ""
            return "https://assets.laligagolazos.com/editions/".concat(playDataID).concat("/play_").concat(playDataID)
        }
        
        pub fun getImage(imageType: String, language: String): String{ 
            return self.assetPath().concat("__").concat(imageType).concat("_2880_2880_").concat(language).concat(".png")
        }
        
        pub fun getVideo(videoType: String, language: String): String{ 
            return self.assetPath().concat("__").concat(videoType).concat("_1080_1080_").concat(language).concat(".mp4")
        }
        
        pub fun name(): String{ 
            let editionData = Golazos.getEditionData(id: self.editionID)!
            let playerKnownName: String = Golazos.PlayData(id: editionData.playID).metadata["PlayerKnownName"] ?? ""
            let playerFirstName: String = Golazos.PlayData(id: editionData.playID).metadata["PlayerFirstName"] ?? ""
            let playerLastName: String = Golazos.PlayData(id: editionData.playID).metadata["PlayerLastName"] ?? ""
            let playType: String = Golazos.PlayData(id: editionData.playID).metadata["PlayType"] ?? ""
            var playerName = playerKnownName
            if playerName == ""{ 
                playerName = playerFirstName.concat(" ").concat(playerLastName)
            }
            return playType.concat(" by ").concat(playerName)
        }
        
        pub fun description(): String{ 
            let editionData = Golazos.getEditionData(id: self.editionID)!
            let metadata = Golazos.PlayData(id: editionData.playID).metadata
            let matchHomeTeam: String = metadata["MatchHomeTeam"] ?? ""
            let matchAwayTeam: String = metadata["MatchAwayTeam"] ?? ""
            let matchHomeScore: String = metadata["MatchHomeScore"] ?? ""
            let matchAwayScore: String = metadata["MatchAwayScore"] ?? ""
            let matchDay: String = metadata["MatchDay"] ?? ""
            let matchSeason: String = metadata["MatchSeason"] ?? ""
            return "LaLiga Golazos Moment from ".concat(matchHomeTeam).concat(" x ").concat(matchAwayTeam).concat(" (").concat(matchHomeScore).concat("-").concat(matchAwayScore).concat(") on Matchday ").concat(matchDay).concat(" (").concat(matchSeason).concat(")")
        }
        
        pub fun thumbnail(): MetadataViews.HTTPFile{ 
            let editionData = Golazos.getEditionData(id: self.editionID)!
            let playDataID: String = Golazos.PlayData(id: editionData.playID).metadata["PlayDataID"] ?? ""
            if playDataID == ""{ 
                return MetadataViews.HTTPFile(url: "https://ipfs.dapperlabs.com/ipfs/QmPvr5zTwji1UGpun57cbj719MUBsB5syjgikbwCMPmruQ")
            }
            return MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Hero_Black", language: "default"))
        }
        
        pub fun getViews(): [Type]{ 
            return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>()]
        }
        
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            switch view{ 
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: self.thumbnail())
                case Type<MetadataViews.Editions>():
                    let editionData = Golazos.getEditionData(id: self.editionID)!
                    let editionInfo = MetadataViews.Edition(name: nil, number: self.serialNumber, max: editionData.maxMintSize)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(editionList)
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.serialNumber)
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(storagePath: Golazos.CollectionStoragePath, publicPath: Golazos.CollectionPublicPath, providerPath: /private/dapperSportCollection, publicCollection: Type<&Golazos.Collection{Golazos.MomentNFTCollectionPublic}>(), publicLinkedType: Type<&Golazos.Collection{Golazos.MomentNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(), providerLinkedType: Type<&Golazos.Collection{Golazos.MomentNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(), createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection{ 
                            return <-Golazos.createEmptyCollection()
                        })
                case Type<MetadataViews.Traits>():
                    return MetadataViews.dictToTraits(dict: self.getTraits(), excludedNames: nil)
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://laligagolazos.com/moments/".concat(self.id.toString()))
                case Type<MetadataViews.Medias>():
                    return MetadataViews.Medias(items: [MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Hero_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Hero_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Front_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Front_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Legal_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Legal_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Details_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Details_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Popout_Black", language: "default")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Popout_Black", language: "es")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Idle_Black", language: "default")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Idle_Black", language: "es")), mediaType: "video/mp4")])
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.laligagolazos.com/static/golazos-logos/Golazos_Logo_Horizontal_B.png"), mediaType: "image/png")
                    let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.laligagolazos.com/static/golazos-logos/Golazos_Logo_Primary_B.png"), mediaType: "image/png")
                    return MetadataViews.NFTCollectionDisplay(name: "Laliga Golazos", description: "Collect LaLiga's biggest Moments and get closer to the game than ever before", externalURL: MetadataViews.ExternalURL("https://laligagolazos.com/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "instagram": MetadataViews.ExternalURL(" https://instagram.com/laligaonflow"), "twitter": MetadataViews.ExternalURL("https://twitter.com/LaLigaGolazos"), "discord": MetadataViews.ExternalURL("https://discord.gg/LaLigaGolazos"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/LaLigaGolazos/")})
                case Type<MetadataViews.Royalties>():
                    let royaltyReceiver: Capability<&{FungibleToken.Receiver}> = getAccount(Golazos.RoyaltyAddress()).getCapability<&AnyResource{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
                    return MetadataViews.Royalties(royalties: [MetadataViews.Royalty(receiver: royaltyReceiver, cut: 0.05, description: "Laliga Golazos marketplace royalty")])
            }
            return nil
        }
        
        pub fun getTraits():{ String: AnyStruct}{ 
            let edition: EditionData = Golazos.getEditionData(id: self.editionID)!
            let play: PlayData = Golazos.getPlayData(id: edition.playID)!
            let series: SeriesData = Golazos.getSeriesData(id: edition.seriesID)!
            let set: SetData = Golazos.getSetData(id: edition.setID)!
            let traitDictionary:{ String: AnyStruct} ={ "editionTier": edition.tier, "seriesName": series.name, "setName": set.name, "serialNumber": self.serialNumber}
            for name in play.metadata.keys{ 
                let value = play.metadata[name] ?? ""
                if value != ""{ 
                    traitDictionary.insert(key: name, value)
                }
            }
            return traitDictionary
        }
    }
    
    pub resource interface MomentNFTCollectionPublic{ 
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection){} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowMomentNFT(id: UInt64): &Golazos.NFT?{ 
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
            let token <- token as! @Golazos.NFT
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
        
        pub fun borrowMomentNFT(id: UInt64): &Golazos.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Golazos.NFT
            } else{ 
                return nil
            }
        }
        
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{ 
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let dapperSportNFT = nft as! &Golazos.NFT
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
        pub fun mintNFT(editionID: UInt64): @Golazos.NFT{} 
    }
    
    pub resource Admin: NFTMinter{ 
        pub fun borrowSeries(id: UInt64): &Golazos.Series{ 
            pre{ 
                Golazos.seriesByID[id] != nil:
                    "Cannot borrow series, no such id"
            }
            return (&Golazos.seriesByID[id] as &Golazos.Series?)!
        }
        
        pub fun borrowSet(id: UInt64): &Golazos.Set{ 
            pre{ 
                Golazos.setByID[id] != nil:
                    "Cannot borrow Set, no such id"
            }
            return (&Golazos.setByID[id] as &Golazos.Set?)!
        }
        
        pub fun borrowPlay(id: UInt64): &Golazos.Play{ 
            pre{ 
                Golazos.playByID[id] != nil:
                    "Cannot borrow Play, no such id"
            }
            return (&Golazos.playByID[id] as &Golazos.Play?)!
        }
        
        pub fun borrowEdition(id: UInt64): &Golazos.Edition{ 
            pre{ 
                Golazos.editionByID[id] != nil:
                    "Cannot borrow edition, no such id"
            }
            return (&Golazos.editionByID[id] as &Golazos.Edition?)!
        }
        
        pub fun createSeries(name: String): UInt64{ 
            let series <- create Golazos.Series(name: name)
            let seriesID = series.id
            Golazos.seriesByID[series.id] <-! series
            return seriesID
        }
        
        pub fun closeSeries(id: UInt64): UInt64{ 
            let series = (&Golazos.seriesByID[id] as &Golazos.Series?)!
            series.close()
            return series.id
        }
        
        pub fun createSet(name: String): UInt64{ 
            let set <- create Golazos.Set(name: name)
            let setID = set.id
            Golazos.setByID[set.id] <-! set
            return setID
        }
        
        pub fun lockSet(id: UInt64): UInt64{ 
            let set = (&Golazos.setByID[id] as &Golazos.Set?)!
            set.lock()
            return set.id
        }
        
        pub fun createPlay(classification: String, metadata:{ String: String}): UInt64{ 
            let play <- create Golazos.Play(classification: classification, metadata: metadata)
            let playID = play.id
            Golazos.playByID[play.id] <-! play
            return playID
        }
        
        pub fun createEdition(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String): UInt64{ 
            let edition <- create Edition(seriesID: seriesID, setID: setID, playID: playID, maxMintSize: maxMintSize, tier: tier)
            let editionID = edition.id
            Golazos.editionByID[edition.id] <-! edition
            return editionID
        }
        
        pub fun closeEdition(id: UInt64): UInt64{ 
            let edition = (&Golazos.editionByID[id] as &Golazos.Edition?)!
            edition.close()
            return edition.id
        }
        
        pub fun mintNFT(editionID: UInt64): @Golazos.NFT{ 
            pre{ 
                Golazos.editionByID.containsKey(editionID):
                    "No such EditionID"
            }
            return <-self.borrowEdition(id: editionID).mint()
        }
    }
    
    init(){ 
        self.CollectionStoragePath = /storage/GolazosNFTCollection
        self.CollectionPublicPath = /public/GolazosNFTCollection
        self.AdminStoragePath = /storage/GolazosAdmin
        self.MinterPrivatePath = /private/GolazosMinter
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
        self.account.link<&Golazos.Admin{Golazos.NFTMinter}>(self.MinterPrivatePath, target: self.AdminStoragePath)
        emit ContractInitialized()
    }
}
