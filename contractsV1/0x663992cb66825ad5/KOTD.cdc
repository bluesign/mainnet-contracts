/*
This tool adds a new entitlemtent called TMP_ENTITLEMENT_OWNER to some functions that it cannot be sure if it is safe to make access(all)
those functions you should check and update their entitlemtents ( or change to all access )

Please see: 
https://cadence-lang.org/docs/cadence-migration-guide/nft-guide#update-all-pub-access-modfiers

IMPORTANT SECURITY NOTICE
Please familiarize yourself with the new entitlements feature because it is extremely important for you to understand in order to build safe smart contracts.
If you change pub to access(all) without paying attention to potential downcasting from public interfaces, you might expose private functions like withdraw 
that will cause security problems for your contract.

*/

	/* 
Central Smart Contract for KOTD x Niftory Battle Rap Collectibles

Heavily based off the Dapper Labs NBA Top Shot contract, with the following modifications:
-Nomenclature changes (e.g. 'Play' -> 'CollectibleItem')
-Small quality of life improvements, like named paths
-Data access improvements based off of Josh Hannan's "What I’ve learned since Top Shot" Cadence blogs
-Additional contract defined metadata at the Series, Set, and CollectibleItem level
-Functionality conveniences, such as closing all open sets & editions when starting a new Series

Much thanks to all the Dapper resouces and Discord help used in the adaptation of this contract!
 */

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract KOTD: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	// Emitted when a new CollectibleItem is created
	access(all)
	event CollectibleItemCreated(id: UInt32, metadata:{ String: String})
	
	// Emitted when a new series has been triggered by an admin
	access(all)
	event NewSeriesStarted(newCurrentSeries: UInt32)
	
	// Events for Set-Related actions
	//
	// Emitted when a new Set is created
	access(all)
	event SetCreated(setID: UInt32, series: UInt32)
	
	// Emitted when a new CollectibleItem is added to a Set
	access(all)
	event CollectibleItemAddedToSet(setID: UInt32, collectibleItemID: UInt32)
	
	// Emitted when a CollectibleItem is retired from a Set and cannot be used to mint
	access(all)
	event CollectibleItemRetiredFromSet(setID: UInt32, collectibleItemID: UInt32, numCollectibleItems: UInt32)
	
	// Emitted when a Set is locked, meaning CollectibleItems cannot be added
	access(all)
	event SetLocked(setID: UInt32)
	
	// Emitted when a Collectible is minted from a Set
	access(all)
	event CollectibleMinted(collectibleID: UInt64, collectibleItemID: UInt32, setID: UInt32, serialNumber: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a CollectibleItem is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a CollectibleItem is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Collectible is destroyed
	access(all)
	event CollectibleDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// Contract-level fields
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Series that this Set belongs to.
	// Series is a concept that indicates a group of Sets through time.
	// Many Sets can exist at a time, but only one Series.
	// ID of the current active Series
	access(all)
	var currentSeriesID: UInt32
	
	// Variable size dictionary of Series structs
	access(self)
	var seriesDatas:{ UInt32: Series}
	
	// Variable size dictionary of CollectibleItem structs
	access(self)
	var collectibleItemDatas:{ UInt32: CollectibleItem}
	
	// Variable size dictionary of Set resources
	access(self)
	var sets: @{UInt32: Set}
	
	// The ID that is used to create CollectibleItems. 
	// Every time a CollectibleItem is created, collectibleItemID is assigned 
	// to the new CollectibleItem's ID and then is incremented by 1.
	access(all)
	var nextCollectibleItemID: UInt32
	
	// The ID that is used to create Sets. Every time a Set is created
	// setID is assigned to the new set's ID and then is incremented by 1.
	access(all)
	var nextSetID: UInt32
	
	// totalSupply
	// The total number of KOTD Collectibles that have been minted
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// Contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	access(all)
	struct Series{ 
		access(all)
		let seriesID: UInt32
		
		access(all)
		let name: String?
		
		access(all)
		let seriesIdentityURL: String?
		
		init(seriesID: UInt32, name: String?, seriesIdentityURL: String?){ 
			self.seriesID = seriesID
			self.name = name
			self.seriesIdentityURL = seriesIdentityURL
		}
	}
	
	access(all)
	struct CurrSeriesData{ 
		access(all)
		let seriesID: UInt32
		
		access(all)
		let name: String?
		
		access(all)
		let seriesIdentityURL: String?
		
		init(){ 
			var referencedSeries = &KOTD.seriesDatas[KOTD.currentSeriesID] as &KOTD.Series?
			self.seriesID = referencedSeries.seriesID
			self.name = referencedSeries.name
			self.seriesIdentityURL = referencedSeries.seriesIdentityURL
		}
	}
	
	// CollectibleItem is a Struct that holds metadata associated 
	// with a moment, entity, or other representative collectible.
	// Collectible NFTs will all reference a single CollectibleItem as the owner of
	// its metadata. CllectibleItems are publicly accessible, so anyone can
	// read the metadata associated with a specific CollectibleItem ID
	access(all)
	struct CollectibleItem{ 
		
		// The unique ID for the CollectibleItem
		access(all)
		let collectibleItemID: UInt32
		
		//array of strings to capture names of any featured artists.  Could be used as keys for a royalty structure in a future marketplace.
		access(all)
		let featuredArtists: [String]
		
		// Stores all the metadata about the CollectibleItem as a string mapping
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}, featuredArtists: [String]){ 
			pre{ 
				metadata.length != 0:
					"New CollectibleItem metadata cannot be empty"
			}
			self.collectibleItemID = KOTD.nextCollectibleItemID
			self.metadata = metadata
			self.featuredArtists = featuredArtists
			
			// Increment the ID so that it isn't used again
			KOTD.nextCollectibleItemID = KOTD.nextCollectibleItemID + UInt32(1)
			emit CollectibleItemCreated(id: self.collectibleItemID, metadata: metadata)
		}
	}
	
	// A Set is a grouping of CollectibleItems that make up a related group of collectibles, 
	// like sets of baseball or Magic cards. A CollectibleItem can exist in multiple different sets.
	// SetData is a struct that is stored in a field of the contract.
	// Anyone can query the constant information
	// about a set by calling various getters located 
	// at the end of the contract. Only the admin has the ability 
	// to modify any data in the private Set resource.
	access(all)
	struct SetData{ 
		access(all)
		let setID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let setIdentityURL: String?
		
		access(all)
		let description: String?
		
		access(all)
		let series: Series
		
		access(all)
		var collectibleItems: [UInt32]
		
		access(all)
		var retired:{ UInt32: Bool}
		
		access(all)
		var locked: Bool
		
		access(all)
		var numberMintedPerCollectibleItem:{ UInt32: UInt32}
		
		init(setID: UInt32){ 
			var referencedSet = &KOTD.sets[setID] as &KOTD.Set?
			self.setID = referencedSet.setID
			self.name = referencedSet.name
			self.setIdentityURL = referencedSet.setIdentityURL
			self.description = referencedSet.description
			self.series = referencedSet.series
			self.collectibleItems = referencedSet.collectibleItems
			self.retired = referencedSet.retired
			self.locked = referencedSet.locked
			self.numberMintedPerCollectibleItem = referencedSet.numberMintedPerCollectibleItem
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// CollectibleItems from a set and mint Collectibles.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods.
	//
	// The admin can add CollectibleItems to a Set so that the set can mint Collectibles
	// that reference that playdata.
	// The Collectibles that are minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the CollectibleItem it references.
	// 
	// Admin can also retire CollectibleItems from the Set, meaning that the retired
	// CollectibleItem can no longer have Collectibles minted from it.
	//
	// If the admin locks the Set, no more CollectibleItems can be added to it, but 
	// Collectibles can still be minted.
	//
	// If retireAll() and lock() are called back-to-back, 
	// the Set is closed off forever and nothing more can be done with it.
	access(all)
	resource Set{ 
		
		// Unique ID for the set
		access(all)
		let setID: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Series that this Set belongs to.
		// Series is a concept that indicates a group of Sets through time.
		// Many Sets can exist at a time, but only one Series.
		access(all)
		let series: Series
		
		// Optional string to hold URL for an identity visual associated with a Set.
		access(all)
		let setIdentityURL: String?
		
		access(all)
		let description: String?
		
		// Array of collectibleItems that are a part of this set.
		// When a collectibleItem is added to the set, its ID gets appended here.
		// The ID does not get removed from this array when a CollectibleItem is retired.
		access(contract)
		var collectibleItems: [UInt32]
		
		// Map of CollectibleItem IDs that Indicates if a CollectibleItem in this Set can be minted.
		// When a CollectibleItem is added to a Set, it is mapped to false (not retired).
		// When a CollectibleItem is retired, this is set to true and cannot be changed.
		access(contract)
		var retired:{ UInt32: Bool}
		
		// Indicates if the Set is currently locked.
		// When a Set is created, it is unlocked 
		// and CollectibleItems are allowed to be added to it.
		// When a set is locked, CollectibleItems cannot be added.
		// A Set can never be changed from locked to unlocked,
		// the decision to lock a Set it is final.
		// If a Set is locked, CollectibleItems cannot be added, but
		// Collectibles can still be minted from CollectibleItems
		// that exist in the Set.
		access(all)
		var locked: Bool
		
		// Mapping of CollectibleItem IDs that indicates the number of Collectibles 
		// that have been minted for specific CollectibleItems in this Set.
		// When a Collectible is minted, this value is stored in the Collectible to
		// show its place in the Set, eg. 13 of 60.
		access(contract)
		var numberMintedPerCollectibleItem:{ UInt32: UInt32}
		
		init(name: String, setIdentityURL: String?, description: String?){ 
			pre{ 
				name.length > 0:
					"New Set name cannot be empty"
			}
			self.setID = KOTD.nextSetID
			self.name = name
			self.setIdentityURL = setIdentityURL
			self.description = description
			self.series = KOTD.seriesDatas[KOTD.currentSeriesID]!
			self.collectibleItems = []
			self.retired ={} 
			self.locked = false
			self.numberMintedPerCollectibleItem ={} 
			KOTD.nextSetID = KOTD.nextSetID + UInt32(1)
			emit SetCreated(setID: self.setID, series: self.series.seriesID)
		}
		
		// addCollectibleItem adds a collectibleItem to the set
		//
		// Parameters: collectibleItemID: The ID of the CollectibleItem that is being added
		//
		// Pre-Conditions:
		// The CollectibleItem needs to be an existing collectibleItem
		// The Set needs to be not locked
		// The CollectibleItem can't have already been added to the Set
		access(TMP_ENTITLEMENT_OWNER)
		fun addCollectibleItem(collectibleItemID: UInt32){ 
			pre{ 
				KOTD.collectibleItemDatas[collectibleItemID] != nil:
					"Cannot add the CollectibleItem to Set: CollectibleItem doesn't exist."
				!self.locked:
					"Cannot add the collectibleItem to the Set after the set has been locked."
				self.numberMintedPerCollectibleItem[collectibleItemID] == nil:
					"The collectibleItem has already beed added to the set."
			}
			
			// Add the CollectibleItem to the array of CollectibleItems
			self.collectibleItems.append(collectibleItemID)
			
			// Open the CollectibleItem up for minting
			self.retired[collectibleItemID] = false
			
			// Initialize the Collectible count to zero
			self.numberMintedPerCollectibleItem[collectibleItemID] = 0
			emit CollectibleItemAddedToSet(setID: self.setID, collectibleItemID: collectibleItemID)
		}
		
		// addCollectibleItems adds multiple CollectibleItems to the Set
		//
		// Parameters: collectibleItemIDs: The IDs of the CollectibleItems that are being added
		//					  as an array
		access(TMP_ENTITLEMENT_OWNER)
		fun addCollectibleItems(collectibleItemIDs: [UInt32]){ 
			for collectibleItem in collectibleItemIDs{ 
				self.addCollectibleItem(collectibleItemID: collectibleItem)
			}
		}
		
		// retireCollectibleItem retires a CollectibleItem from the Set so that it can't mint new Collectibles
		//
		// Parameters: collectibleItemID: The ID of the CollectibleItem that is being retired
		//
		// Pre-Conditions:
		// The CollectibleItem is part of the Set and not retired (available for minting).
		access(TMP_ENTITLEMENT_OWNER)
		fun retireCollectibleItem(collectibleItemID: UInt32){ 
			pre{ 
				self.retired[collectibleItemID] != nil:
					"Cannot retire the CollectibleItem: CollectibleItem doesn't exist in this set!"
			}
			if !self.retired[collectibleItemID]!{ 
				self.retired[collectibleItemID] = true
				emit CollectibleItemRetiredFromSet(setID: self.setID, collectibleItemID: collectibleItemID, numCollectibleItems: self.numberMintedPerCollectibleItem[collectibleItemID]!)
			}
		}
		
		// retireAll retires all the collectibleItems in the Set
		// Afterwards, none of the retired CollectibleItems will be able to mint new Collectibles
		access(TMP_ENTITLEMENT_OWNER)
		fun retireAll(){ 
			for collectibleItem in self.collectibleItems{ 
				self.retireCollectibleItem(collectibleItemID: collectibleItem)
			}
		}
		
		// lock() locks the Set so that no more CollectibleItems can be added to it
		//
		// Pre-Conditions:
		// The Set should not be locked
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setID: self.setID)
			}
		}
		
		// mintCollectible mints a new Collectible and returns the newly minted Collectible
		// 
		// Parameters: collectibleItemID: The ID of the CollectibleItem that the Collectible references
		//
		// Pre-Conditions:
		// The CollectibleItem must exist in the Set and be allowed to mint new Collectibles
		//
		// Returns: The NFT that was minted
		access(TMP_ENTITLEMENT_OWNER)
		fun mintCollectible(collectibleItemID: UInt32): @NFT{ 
			pre{ 
				self.retired[collectibleItemID] != nil:
					"Cannot mint the collectibleItem: This collectibleItem doesn't exist."
				!self.retired[collectibleItemID]!:
					"Cannot mint the collectibleItem from this collectibleItem: This collectibleItem has been retired."
			}
			
			// Gets the number of Collectibles that have been minted for this CollectibleItem
			// to use as this Collectible's serial number
			let numInPlay = self.numberMintedPerCollectibleItem[collectibleItemID]!
			
			// Mint the new collectibleItem
			let newCollectible: @NFT <- create NFT(serialNumber: numInPlay + UInt32(1), collectibleItemID: collectibleItemID, setID: self.setID)
			
			// Increment the count of Collectibles minted for this CollectibleItem
			self.numberMintedPerCollectibleItem[collectibleItemID] = numInPlay + UInt32(1)
			return <-newCollectible
		}
		
		// batchMintCollectible mints an arbitrary quantity of Collectibles 
		// and returns them as a Collection
		//
		// Parameters: collectibleItemID: the ID of the CollectibleItem that the Collectibles are minted for
		//			 quantity: The quantity of Collectibles to be minted
		//
		// Returns: Collection object that contains all the Collectibles that were minted
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintCollectible(collectibleItemID: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintCollectible(collectibleItemID: collectibleItemID))
				i = i + UInt64(1)
			}
			return <-newCollection
		}
	}
	
	access(all)
	struct CollectibleData{ 
		
		// The ID of the Set that the Collectible comes from
		access(all)
		let setID: UInt32
		
		// The ID of the CollectibleItem that the Collectible references
		access(all)
		let collectibleItemID: UInt32
		
		// The place in the edition that this Collectible was minted
		// Otherwise know as the serial number
		access(all)
		let serialNumber: UInt32
		
		init(setID: UInt32, collectibleItemID: UInt32, serialNumber: UInt32){ 
			self.setID = setID
			self.collectibleItemID = collectibleItemID
			self.serialNumber = serialNumber
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the CollectibleItems, Sets, and Collectibles  
	access(all)
	resource Admin{ 
		
		// createCollectibleItem creates a new CollectibleItem struct 
		// and stores it in the CollectibleItems dictionary in the KOTD smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//					   example: {"Player Name": "Kevin Durant", "Height": "7 feet"}
		//							   (because we all know Kevin Durant is not 6'9")
		//
		// Returns: the ID of the new CollectibleItem object
		access(TMP_ENTITLEMENT_OWNER)
		fun createCollectibleItem(metadata:{ String: String}, featuredArtists: [String]): UInt32{ 
			// Create the new CollectibleItem
			var newCollectibleItem = CollectibleItem(metadata: metadata, featuredArtists: featuredArtists)
			let newID = newCollectibleItem.collectibleItemID
			
			// Store it in the contract storage
			KOTD.collectibleItemDatas[newID] = newCollectibleItem
			return newID
		}
		
		// createSet creates a new Set resource and stores it
		// in the sets mapping in the KOTD contract
		//
		// Parameters: name: The name of the Set
		access(TMP_ENTITLEMENT_OWNER)
		fun createSet(name: String, setIdentityURL: String?, description: String?){ 
			// Create the new Set
			var newSet <- create Set(name: name, setIdentityURL: setIdentityURL, description: description)
			
			// Store it in the sets mapping field
			KOTD.sets[newSet.setID] <-! newSet
		}
		
		// borrowSet returns a reference to a set in the KOTD
		// contract so that the admin can call methods on it
		//
		// Parameters: setID: The ID of the Set that you want to
		// get a reference to
		//
		// Returns: A reference to the Set with all of the fields
		// and methods exposed
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSet(setID: UInt32): &Set{ 
			pre{ 
				KOTD.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			
			// Get a reference to the Set and return it
			// use `&` to indicate the reference to the object and type
			return &KOTD.sets[setID] as &KOTD.Set?
		}
		
		// startNewSeries ends the current series by creating a new Series, 
		// meaning that Collectibles minted after this
		// will belong to the new Series and reference it's metadata.  It also closes 
		// all sets and editions in the current series.
		//
		// Returns: The new series ID
		access(TMP_ENTITLEMENT_OWNER)
		fun startNewSeries(name: String?, identityURL: String?): UInt32{ 
			// End the current series and start a new one
			// by incrementing the KOTD series number
			let setIDs = KOTD.sets.keys
			var i: Int = 0
			while i < setIDs.length{ 
				var currSet = SetData(setID: setIDs[i])
				if currSet.series.seriesID == KOTD.currentSeriesID{ 
					self.borrowSet(setID: setIDs[i]).retireAll()
					self.borrowSet(setID: setIDs[i]).lock()
				}
				i = i + 1
			}
			var newSeries = Series(seriesID: KOTD.currentSeriesID + UInt32(1), name: name, seriesIdentityURL: identityURL)
			KOTD.currentSeriesID = newSeries.seriesID
			
			//put it in storage
			KOTD.seriesDatas[KOTD.currentSeriesID] = newSeries
			emit NewSeriesStarted(newCurrentSeries: KOTD.currentSeriesID)
			return KOTD.currentSeriesID
		}
		
		// createNewAdmin creates a new Admin resource
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// The resource that represents the Collectible NFTs
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique collectibleItem ID
		access(all)
		let id: UInt64
		
		// Struct of Collectible metadata
		access(all)
		let data: CollectibleData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, collectibleItemID: UInt32, setID: UInt32){ 
			// Increment the global Collectible IDs
			KOTD.totalSupply = KOTD.totalSupply + UInt64(1)
			self.id = KOTD.totalSupply
			
			// Set the metadata struct
			self.data = CollectibleData(setID: setID, collectibleItemID: collectibleItemID, serialNumber: serialNumber)
			emit CollectibleMinted(collectibleID: self.id, collectibleItemID: collectibleItemID, setID: self.data.setID, serialNumber: self.data.serialNumber)
		}
	
	// If the Collectible is destroyed, emit an event to indicate 
	// to outside observers that it has been destroyed
	}
	
	// This is the interface that users can cast their Collectible Collection as
	// to allow others to deposit Collectibles into their Collection. It also allows for reading
	// the IDs of Collectibles in the Collection.
	access(all)
	resource interface NiftoryCollectibleCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollectible(id: UInt64): &KOTD.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Collectible reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	access(all)
	resource Collection: NiftoryCollectibleCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Collectible conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Collectible from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Collectible does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn collectibleItems
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a Collectible and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			
			// Cast the deposited token as a KOTD NFT to make sure
			// it is the correct type
			let token <- token as! @KOTD.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a Collectible in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any KOTD specific data. Please use borrowCollectible to 
		// read Collectible data.
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowCollectible returns a borrowed reference to a Collectible
		// so that the caller can read data and call methods from it.
		// They can use this to read its setID, collectibleItemID, serialNumber,
		// or any of the setData or CollectibleItem data associated with it by
		// getting the setID or collectibleItemID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollectible(id: UInt64): &KOTD.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &KOTD.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	}
	
	// -----------------------------------------------------------------------
	// Contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Collectibles in transactions.
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create KOTD.Collection()
	}
	
	// getAllCollectibleItems returns all the collectibleItems in KOTD
	//
	// Returns: An array of all the collectibleItems that have been created
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllCollectibleItems(): [KOTD.CollectibleItem]{ 
		return KOTD.collectibleItemDatas.values
	}
	
	// getCollectibleItemMetaData returns all the metadata associated with a specific CollectibleItem
	// 
	// Parameters: collectibleItemID: The id of the CollectibleItem that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectibleItemMetaData(collectibleItemID: UInt32):{ String: String}?{ 
		return self.collectibleItemDatas[collectibleItemID]?.metadata
	}
	
	// getCollectibleItemMetaData returns all the metadata associated with a specific CollectibleItem
	// 
	// Parameters: collectibleItemID: The id of the CollectibleItem that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectibleItemFeaturedArtists(collectibleItemID: UInt32): [String]?{ 
		return self.collectibleItemDatas[collectibleItemID]?.featuredArtists
	}
	
	// getCollectibleItemMetaDataByField returns the metadata associated with a 
	//						specific field of the metadata
	//						Ex: field: "name" will return something
	//						like "Saynt LA"
	// 
	// Parameters: collectibleItemID: The id of the CollectibleItem that is being searched
	//			 field: The field to search for
	//
	// Returns: The metadata field as a String Optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectibleItemMetaDataByField(collectibleItemID: UInt32, field: String): String?{ 
		// Don't force a revert if the collectibleItemID or field is invalid
		if let collectibleItem = KOTD.collectibleItemDatas[collectibleItemID]{ 
			return collectibleItem.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// getCollectibleItemsInSet returns the list of CollectibleItem IDs that are in the Set
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: An array of CollectibleItem IDs
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectibleItemsInSet(setID: UInt32): [UInt32]?{ 
		// Don't force a revert if the setID is invalid
		return KOTD.sets[setID]?.collectibleItems
	}
	
	// isEditionRetired returns a boolean that indicates if a Set/CollectibleItem combo
	//				  (otherwise known as an edition) is retired.
	//				  If an edition is retired, it still remains in the Set,
	//				  but Collectibles can no longer be minted from it.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//			 collectibleItemID: The id of the CollectibleItem that is being searched
	//
	// Returns: Boolean indicating if the edition is retired or not
	access(TMP_ENTITLEMENT_OWNER)
	fun isEditionRetired(setID: UInt32, collectibleItemID: UInt32): Bool?{ 
		// Don't force a revert if the set or collectibleItem ID is invalid
		// Remove the set from the dictionary to get its field
		if let setToRead <- KOTD.sets.remove(key: setID){ 
			
			// See if the CollectibleItem is retired from this Set
			let retired = setToRead.retired[collectibleItemID]
			
			// Put the Set back in the contract storage
			KOTD.sets[setID] <-! setToRead
			
			// Return the retired status
			return retired
		} else{ 
			
			// If the Set wasn't found, return nil
			return nil
		}
	}
	
	// isSetLocked returns a boolean that indicates if a Set
	//			 is locked. If it's locked, 
	//			 new CollectibleItems can no longer be added to it,
	//			 but Collectibles can still be minted from CollectibleItems the set contains.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: Boolean indicating if the Set is locked or not
	access(TMP_ENTITLEMENT_OWNER)
	fun isSetLocked(setID: UInt32): Bool?{ 
		// Don't force a revert if the setID is invalid
		return KOTD.sets[setID]?.locked
	}
	
	// getNumCollectiblesInEdition return the number of Collectibles that have been 
	//						minted from a certain edition.
	//
	// Parameters: setID: The id of the Set that is being searched
	//			 collectibleItemID: The id of the CollectibleItem that is being searched
	//
	// Returns: The total number of Collectibles 
	//		  that have been minted from an edition
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumCollectiblesInEdition(setID: UInt32, collectibleItemID: UInt32): UInt32?{ 
		// Don't force a revert if the Set or collectibleItem ID is invalid
		// Remove the Set from the dictionary to get its field
		if let setToRead <- KOTD.sets.remove(key: setID){ 
			
			// Read the numMintedPerPlay
			let amount = setToRead.numberMintedPerCollectibleItem[collectibleItemID]
			
			// Put the Set back into the Sets dictionary
			KOTD.sets[setID] <-! setToRead
			return amount
		} else{ 
			// If the set wasn't found return nil
			return nil
		}
	}
	
	// -----------------------------------------------------------------------
	// Contract initialization function
	// -----------------------------------------------------------------------
	init(){ 
		// Initialize contract fields
		self.currentSeriesID = 0
		self.seriesDatas ={} 
		self.seriesDatas[self.currentSeriesID] = Series(seriesID: KOTD.currentSeriesID, name: nil, seriesIdentityURL: nil)
		self.collectibleItemDatas ={} 
		self.sets <-{} 
		self.nextCollectibleItemID = 1
		self.nextSetID = 1
		self.totalSupply = 0
		
		// initialize paths
		// Set our named paths
		self.CollectionStoragePath = /storage/NiftoryCollectibleCollection001
		self.CollectionPublicPath = /public/NiftoryCollectibleCollection001
		self.AdminStoragePath = /storage/KOTDAdmin005
		
		// Put a new Collection in storage 
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{NiftoryCollectibleCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
