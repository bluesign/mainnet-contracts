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
	Description: Central Smart Contract for ABD

	This smart contract contains the core functionality for 
	ABD, created by Digihey.com

	The contract manages the data associated with all the plays and sets
	that are used as templates for the Moment NFTs

	When a new Play wants to be added to the records, an Admin creates
	a new Play struct that is stored in the smart contract.

	Then an Admin can create new Sets. Sets consist of a public struct that 
	contains public information about a set, and a private resource used
	to mint new moments based off of plays that have been linked to the Set.

	The admin resource has the power to do all of the important actions
	in the smart contract. When admins want to call functions in a set,
	they call their borrowSet function to get a reference 
	to a set in the contract. Then, they can call functions on the set using that reference.

	In this way, the smart contract and its defined resources interact 
	with great teamwork
	
	When moments are minted, they are initialized with a MomentData struct and
	are returned by the minter.

	The contract also defines a Collection resource. This is an object that 
	every ABD NFT owner will store in their account
	to manage their NFT collection.

	The main ABD account will also have its own Moment collections
	it can use to hold its own moments that have not yet been sent to a user.

	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
	Functions that don't modify state will simply return 0 or nil 
	and those cases need to be handled by the caller.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract ABD: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// ABD contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the ABD contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Play struct is created
	access(all)
	event PlayCreated(id: UInt32, metadata:{ String: String})
	
	// Emitted when a new series has been triggered by an admin
	access(all)
	event NewSeriesStarted(newCurrentSeries: UInt32)
	
	// Events for Set-Related actions
	//
	// Emitted when a new Set is created
	access(all)
	event SetCreated(setID: UInt32, series: UInt32)
	
	// Emitted when a new Play is added to a Set
	access(all)
	event PlayAddedToSet(setID: UInt32, playID: UInt32)
	
	// Emitted when a Play is retired from a Set and cannot be used to mint
	access(all)
	event PlayRetiredFromSet(setID: UInt32, playID: UInt32, numMoments: UInt32)
	
	// Emitted when a Set is locked, meaning Plays cannot be added
	access(all)
	event SetLocked(setID: UInt32)
	
	// Emitted when a Moment is minted from a Set
	access(all)
	event MomentMinted(momentID: UInt64, playID: UInt32, setID: UInt32, serialNumber: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a moment is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a moment is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Moment is destroyed
	access(all)
	event MomentDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// ABD contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Series that this Set belongs to.
	// Series is a concept that indicates a group of Sets through time.
	// Many Sets can exist at a time, but only one series.
	access(all)
	var currentSeries: UInt32
	
	// Variable size dictionary of Play structs
	access(self)
	var playDatas:{ UInt32: Play}
	
	// Variable size dictionary of SetData structs
	access(self)
	var setDatas:{ UInt32: SetData}
	
	// Variable size dictionary of Set resources
	access(self)
	var sets: @{UInt32: Set}
	
	// The ID that is used to create Plays. 
	// Every time a Play is created, playID is assigned 
	// to the new Play's ID and then is incremented by 1.
	access(all)
	var nextPlayID: UInt32
	
	// The ID that is used to create Sets. Every time a Set is created
	// setID is assigned to the new set's ID and then is incremented by 1.
	access(all)
	var nextSetID: UInt32
	
	// The total number of ABD Moment NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as global moment IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// ABD contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// Play is a Struct that holds metadata associated 
	// with a specific ABD play
	//
	// Moment NFTs will all reference a single play as the owner of
	// its metadata. The plays are publicly accessible, so anyone can
	// read the metadata associated with a specific play ID
	//
	access(all)
	struct Play{ 
		
		// The unique ID for the Play
		access(all)
		let playID: UInt32
		
		// Stores all the metadata about the play as a string mapping
		// This is not the long term way NFT metadata will be stored. It's a temporary
		// construct while we figure out a better way to do metadata.
		//
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Play metadata cannot be empty"
			}
			self.playID = ABD.nextPlayID
			self.metadata = metadata
			
			// Increment the ID so that it isn't used again
			ABD.nextPlayID = ABD.nextPlayID + UInt32(1)
			emit PlayCreated(id: self.playID, metadata: metadata)
		}
	}
	
	// A Set is a grouping of Plays that have occured in the real world
	// that make up a related group of collectibles. A Play can exist in multiple different sets.
	// 
	// SetData is a struct that is stored in a field of the contract.
	// Anyone can query the constant information
	// about a set by calling various getters located 
	// at the end of the contract. Only the admin has the ability 
	// to modify any data in the private Set resource.
	//
	access(all)
	struct SetData{ 
		
		// Unique ID for the Set
		access(all)
		let setID: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Series that this Set belongs to.
		// Series is a concept that indicates a group of Sets through time.
		// Many Sets can exist at a time, but only one series.
		access(all)
		let series: UInt32
		
		init(name: String){ 
			pre{ 
				name.length > 0:
					"New Set name cannot be empty"
			}
			self.setID = ABD.nextSetID
			self.name = name
			self.series = ABD.currentSeries
			
			// Increment the setID so that it isn't used again
			ABD.nextSetID = ABD.nextSetID + UInt32(1)
			emit SetCreated(setID: self.setID, series: self.series)
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// Plays from a set and mint Moments.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods.
	//
	// The admin can add Plays to a Set so that the set can mint Moments
	// that reference that playdata.
	// The Moments that are minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the Play it references.
	// 
	// Admin can also retire Plays from the Set, meaning that the retired
	// Play can no longer have Moments minted from it.
	//
	// If the admin locks the Set, no more Plays can be added to it, but 
	// Moments can still be minted.
	//
	// If retireAll() and lock() are called back-to-back, 
	// the Set is closed off forever and nothing more can be done with it.
	access(all)
	resource Set{ 
		
		// Unique ID for the set
		access(all)
		let setID: UInt32
		
		// Array of plays that are a part of this set.
		// When a play is added to the set, its ID gets appended here.
		// The ID does not get removed from this array when a Play is retired.
		access(all)
		var plays: [UInt32]
		
		// Map of Play IDs that Indicates if a Play in this Set can be minted.
		// When a Play is added to a Set, it is mapped to false (not retired).
		// When a Play is retired, this is set to true and cannot be changed.
		access(all)
		var retired:{ UInt32: Bool}
		
		// Indicates if the Set is currently locked.
		// When a Set is created, it is unlocked 
		// and Plays are allowed to be added to it.
		// When a set is locked, Plays cannot be added.
		// A Set can never be changed from locked to unlocked,
		// the decision to lock a Set it is final.
		// If a Set is locked, Plays cannot be added, but
		// Moments can still be minted from Plays
		// that exist in the Set.
		access(all)
		var locked: Bool
		
		// Mapping of Play IDs that indicates the number of Moments 
		// that have been minted for specific Plays in this Set.
		// When a Moment is minted, this value is stored in the Moment to
		// show its place in the Set, eg. 13 of 60.
		access(all)
		var numberMintedPerPlay:{ UInt32: UInt32}
		
		init(name: String){ 
			self.setID = ABD.nextSetID
			self.plays = []
			self.retired ={} 
			self.locked = false
			self.numberMintedPerPlay ={} 
			
			// Create a new SetData for this Set and store it in contract storage
			ABD.setDatas[self.setID] = SetData(name: name)
		}
		
		// addPlay adds a play to the set
		//
		// Parameters: playID: The ID of the Play that is being added
		//
		// Pre-Conditions:
		// The Play needs to be an existing play
		// The Set needs to be not locked
		// The Play can't have already been added to the Set
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun addPlay(playID: UInt32){ 
			pre{ 
				ABD.playDatas[playID] != nil:
					"Cannot add the Play to Set: Play doesn't exist."
				!self.locked:
					"Cannot add the play to the Set after the set has been locked."
				self.numberMintedPerPlay[playID] == nil:
					"The play has already beed added to the set."
			}
			
			// Add the Play to the array of Plays
			self.plays.append(playID)
			
			// Open the Play up for minting
			self.retired[playID] = false
			
			// Initialize the Moment count to zero
			self.numberMintedPerPlay[playID] = 0
			emit PlayAddedToSet(setID: self.setID, playID: playID)
		}
		
		// addPlays adds multiple Plays to the Set
		//
		// Parameters: playIDs: The IDs of the Plays that are being added
		//					  as an array
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun addPlays(playIDs: [UInt32]){ 
			for play in playIDs{ 
				self.addPlay(playID: play)
			}
		}
		
		// retirePlay retires a Play from the Set so that it can't mint new Moments
		//
		// Parameters: playID: The ID of the Play that is being retired
		//
		// Pre-Conditions:
		// The Play is part of the Set and not retired (available for minting).
		// 
		access(TMP_ENTITLEMENT_OWNER)
		fun retirePlay(playID: UInt32){ 
			pre{ 
				self.retired[playID] != nil:
					"Cannot retire the Play: Play doesn't exist in this set!"
			}
			if !self.retired[playID]!{ 
				self.retired[playID] = true
				emit PlayRetiredFromSet(setID: self.setID, playID: playID, numMoments: self.numberMintedPerPlay[playID]!)
			}
		}
		
		// retireAll retires all the plays in the Set
		// Afterwards, none of the retired Plays will be able to mint new Moments
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun retireAll(){ 
			for play in self.plays{ 
				self.retirePlay(playID: play)
			}
		}
		
		// lock() locks the Set so that no more Plays can be added to it
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
		
		// mintMoment mints a new Moment and returns the newly minted Moment
		// 
		// Parameters: playID: The ID of the Play that the Moment references
		//
		// Pre-Conditions:
		// The Play must exist in the Set and be allowed to mint new Moments
		//
		// Returns: The NFT that was minted
		// 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintMoment(playID: UInt32): @NFT{ 
			pre{ 
				self.retired[playID] != nil:
					"Cannot mint the moment: This play doesn't exist."
				!self.retired[playID]!:
					"Cannot mint the moment from this play: This play has been retired."
			}
			
			// Gets the number of Moments that have been minted for this Play
			// to use as this Moment's serial number
			let numInPlay = self.numberMintedPerPlay[playID]!
			
			// Mint the new moment
			let newMoment: @NFT <- create NFT(serialNumber: numInPlay + UInt32(1), playID: playID, setID: self.setID)
			
			// Increment the count of Moments minted for this Play
			self.numberMintedPerPlay[playID] = numInPlay + UInt32(1)
			return <-newMoment
		}
		
		// batchMintMoment mints an arbitrary quantity of Moments 
		// and returns them as a Collection
		//
		// Parameters: playID: the ID of the Play that the Moments are minted for
		//			 quantity: The quantity of Moments to be minted
		//
		// Returns: Collection object that contains all the Moments that were minted
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintMoment(playID: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintMoment(playID: playID))
				i = i + UInt64(1)
			}
			return <-newCollection
		}
	}
	
	access(all)
	struct MomentData{ 
		
		// The ID of the Set that the Moment comes from
		access(all)
		let setID: UInt32
		
		// The ID of the Play that the Moment references
		access(all)
		let playID: UInt32
		
		// The place in the edition that this Moment was minted
		// Otherwise know as the serial number
		access(all)
		let serialNumber: UInt32
		
		init(setID: UInt32, playID: UInt32, serialNumber: UInt32){ 
			self.setID = setID
			self.playID = playID
			self.serialNumber = serialNumber
		}
	}
	
	// The resource that represents the Moment NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique moment ID
		access(all)
		let id: UInt64
		
		// Struct of Moment metadata
		access(all)
		let data: MomentData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, playID: UInt32, setID: UInt32){ 
			// Increment the global Moment IDs
			ABD.totalSupply = ABD.totalSupply + UInt64(1)
			self.id = ABD.totalSupply
			
			// Set the metadata struct
			self.data = MomentData(setID: setID, playID: playID, serialNumber: serialNumber)
			emit MomentMinted(momentID: self.id, playID: playID, setID: self.data.setID, serialNumber: self.data.serialNumber)
		}
	
	// If the Moment is destroyed, emit an event to indicate 
	// to outside ovbservers that it has been destroyed
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the Plays, Sets, and Moments
	//
	access(all)
	resource Admin{ 
		
		// createPlay creates a new Play struct 
		// and stores it in the Plays dictionary in the ABD smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//					   example: {"Player Name": "Mike Mo Capaldi", "Height": "6 feet"}
		//
		// Returns: the ID of the new Play object
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createPlay(metadata:{ String: String}): UInt32{ 
			// Create the new Play
			var newPlay = Play(metadata: metadata)
			let newID = newPlay.playID
			
			// Store it in the contract storage
			ABD.playDatas[newID] = newPlay
			return newID
		}
		
		// createSet creates a new Set resource and stores it
		// in the sets mapping in the ABD contract
		//
		// Parameters: name: The name of the Set
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createSet(name: String){ 
			// Create the new Set
			var newSet <- create Set(name: name)
			
			// Store it in the sets mapping field
			ABD.sets[newSet.setID] <-! newSet
		}
		
		// borrowSet returns a reference to a set in the ABD
		// contract so that the admin can call methods on it
		//
		// Parameters: setID: The ID of the Set that you want to
		// get a reference to
		//
		// Returns: A reference to the Set with all of the fields
		// and methods exposed
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSet(setID: UInt32): &ABD.Set?{ 
			pre{ 
				ABD.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			let set = &ABD.sets[setID] as &ABD.Set?
			return set
		
		// Get a reference to the Set and return it
		// use `&` to indicate the reference to the object and type
		// return &ABD.sets[setID] as &Set
		// HERE:::
		// |			 return &ABD.sets[setID] as &Set
		// |					 ^^^^^^^^^^^^^^^ expected `ABD.Set`, got `ABD.Set?`
		}
		
		// startNewSeries ends the current series by incrementing
		// the series number, meaning that Moments minted after this
		// will use the new series number
		//
		// Returns: The new series number
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun startNewSeries(): UInt32{ 
			// End the current series and start a new one
			// by incrementing the ABD series number
			ABD.currentSeries = ABD.currentSeries + UInt32(1)
			emit NewSeriesStarted(newCurrentSeries: ABD.currentSeries)
			return ABD.currentSeries
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This is the interface that users can cast their Moment Collection as
	// to allow others to deposit Moments into their Collection. It also allows for reading
	// the IDs of Moments in the Collection.
	access(all)
	resource interface MomentCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMoment(id: UInt64): &ABD.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: MomentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Moment conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Moment from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Moment does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn moments
		//
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
		
		// deposit takes a Moment and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			
			// Cast the deposited token as a ABD NFT to make sure
			// it is the correct type
			let token <- token as! @ABD.NFT
			
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
		
		// borrowNFT Returns a borrowed reference to a Moment in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any ABD specific data. Please use borrowMoment to 
		// read Moment data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			if nft == nil{ 
				panic("")
			}
			return nft! as &{NonFungibleToken.NFT}
		// return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		// HERE::: 
		//   642 |			 return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		//	   |					 ^^^^^^^^^^^^^^^^^^ expected `NonFungibleToken.NFT`, got `NonFungibleToken.NFT?`
		}
		
		// borrowMoment returns a borrowed reference to a Moment
		// so that the caller can read data and call methods from it.
		// They can use this to read its setID, playID, serialNumber,
		// or any of the setData or Play data associated with it by
		// getting the setID or playID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMoment(id: UInt64): &ABD.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &ABD.NFT
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
	//
	}
	
	// -----------------------------------------------------------------------
	// ABD contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Moments in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ABD.Collection()
	}
	
	// getAllPlays returns all the plays in ABD
	//
	// Returns: An array of all the plays that have been created
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllPlays(): [ABD.Play]{ 
		return ABD.playDatas.values
	}
	
	// getPlayMetaData returns all the metadata associated with a specific Play
	// 
	// Parameters: playID: The id of the Play that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlayMetaData(playID: UInt32):{ String: String}?{ 
		return self.playDatas[playID]?.metadata
	}
	
	// getPlayMetaDataByField returns the metadata associated with a 
	//						specific field of the metadata
	// 
	// Parameters: playID: The id of the Play that is being searched
	//			 field: The field to search for
	//
	// Returns: The metadata field as a String Optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlayMetaDataByField(playID: UInt32, field: String): String?{ 
		// Don't force a revert if the playID or field is invalid
		if let play = ABD.playDatas[playID]{ 
			return play.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// getSetName returns the name that the specified Set
	//			is associated with.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: The name of the Set
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetName(setID: UInt32): String?{ 
		// Don't force a revert if the setID is invalid
		return ABD.setDatas[setID]?.name
	}
	
	// getSetSeries returns the series that the specified Set
	//			  is associated with.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: The series that the Set belongs to
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetSeries(setID: UInt32): UInt32?{ 
		// Don't force a revert if the setID is invalid
		return ABD.setDatas[setID]?.series
	}
	
	// getSetIDsByName returns the IDs that the specified Set name
	//				 is associated with.
	// 
	// Parameters: setName: The name of the Set that is being searched
	//
	// Returns: An array of the IDs of the Set if it exists, or nil if doesn't
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetIDsByName(setName: String): [UInt32]?{ 
		var setIDs: [UInt32] = []
		
		// Iterate through all the setDatas and search for the name
		for setData in ABD.setDatas.values{ 
			if setName == setData.name{ 
				// If the name is found, return the ID
				setIDs.append(setData.setID)
			}
		}
		
		// If the name isn't found, return nil
		// Don't force a revert if the setName is invalid
		if setIDs.length == 0{ 
			return nil
		} else{ 
			return setIDs
		}
	}
	
	// getPlaysInSet returns the list of Play IDs that are in the Set
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: An array of Play IDs
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlaysInSet(setID: UInt32): [UInt32]?{ 
		// Don't force a revert if the setID is invalid
		return ABD.sets[setID]?.plays
	}
	
	// isEditionRetired returns a boolean that indicates if a Set/Play combo
	//				  (otherwise known as an edition) is retired.
	//				  If an edition is retired, it still remains in the Set,
	//				  but Moments can no longer be minted from it.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//			 playID: The id of the Play that is being searched
	//
	// Returns: Boolean indicating if the edition is retired or not
	access(TMP_ENTITLEMENT_OWNER)
	fun isEditionRetired(setID: UInt32, playID: UInt32): Bool?{ 
		// Don't force a revert if the set or play ID is invalid
		// Remove the set from the dictionary to get its field
		if let setToRead <- ABD.sets.remove(key: setID){ 
			
			// See if the Play is retired from this Set
			let retired = setToRead.retired[playID]
			
			// Put the Set back in the contract storage
			ABD.sets[setID] <-! setToRead
			
			// Return the retired status
			return retired
		} else{ 
			
			// If the Set wasn't found, return nil
			return nil
		}
	}
	
	// isSetLocked returns a boolean that indicates if a Set
	//			 is locked. If it's locked, 
	//			 new Plays can no longer be added to it,
	//			 but Moments can still be minted from Plays the set contains.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: Boolean indicating if the Set is locked or not
	access(TMP_ENTITLEMENT_OWNER)
	fun isSetLocked(setID: UInt32): Bool?{ 
		// Don't force a revert if the setID is invalid
		return ABD.sets[setID]?.locked
	}
	
	// getNumMomentsInEdition return the number of Moments that have been 
	//						minted from a certain edition.
	//
	// Parameters: setID: The id of the Set that is being searched
	//			 playID: The id of the Play that is being searched
	//
	// Returns: The total number of Moments 
	//		  that have been minted from an edition
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumMomentsInEdition(setID: UInt32, playID: UInt32): UInt32?{ 
		// Don't force a revert if the Set or play ID is invalid
		// Remove the Set from the dictionary to get its field
		if let setToRead <- ABD.sets.remove(key: setID){ 
			
			// Read the numMintedPerPlay
			let amount = setToRead.numberMintedPerPlay[playID]
			
			// Put the Set back into the Sets dictionary
			ABD.sets[setID] <-! setToRead
			return amount
		} else{ 
			// If the set wasn't found return nil
			return nil
		}
	}
	
	// -----------------------------------------------------------------------
	// ABD initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.currentSeries = 0
		self.playDatas ={} 
		self.setDatas ={} 
		self.sets <-{} 
		self.nextPlayID = 1
		self.nextSetID = 1
		self.totalSupply = 0
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: /storage/ABDMomentCollection)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{MomentCollectionPublic}>(/storage/ABDMomentCollection)
		self.account.capabilities.publish(capability_1, at: /public/ABDMomentCollection)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/ABDAdmin)
		emit ContractInitialized()
	}
}
