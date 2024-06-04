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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheFabricantMysteryBox_FF1: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantMysteryBox_FF1 contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the Fabricant contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new FabricantData struct is created
	access(all)
	event FabricantDataCreated(fabricantDataID: UInt32, mainImage: String)
	
	// Emitted when a Fabricant is minted
	access(all)
	event FabricantMinted(fabricantID: UInt64, fabricantDataID: UInt32, serialNumber: UInt32)
	
	// Emitted when the contract's royalty percentage is changed
	access(all)
	event RoyaltyPercentageChanged(newRoyaltyPercentage: UFix64)
	
	access(all)
	event FabricantDataIDRetired(fabricantDataID: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a Fabricant is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a Fabricant is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Fabricant is destroyed
	access(all)
	event FabricantDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// contract-level fields.	  
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Contains standard storage and public paths of resources
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Variable size dictionary of Fabricant structs
	access(self)
	var fabricantDatas:{ UInt32: FabricantData}
	
	// Dictionary with FabricantDataID as key and number of NFTs with FabricantDataID are minted
	access(self)
	var numberMintedPerFabricant:{ UInt32: UInt32}
	
	// Dictionary of fabricantDataID to  whether they are retired
	access(self)
	var isFabricantDataRetired:{ UInt32: Bool}
	
	// Keeps track of how many unique FabricantData's are created
	access(all)
	var nextFabricantDataID: UInt32
	
	access(all)
	var royaltyPercentage: UFix64
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct FabricantData{ 
		
		// The unique ID for the Fabricant Data
		access(all)
		let fabricantDataID: UInt32
		
		//stores link to image
		access(all)
		let mainImage: String
		
		init(mainImage: String){ 
			self.fabricantDataID = TheFabricantMysteryBox_FF1.nextFabricantDataID
			self.mainImage = mainImage
			TheFabricantMysteryBox_FF1.isFabricantDataRetired[self.fabricantDataID] = false
			
			// Increment the ID so that it isn't used again
			TheFabricantMysteryBox_FF1.nextFabricantDataID = TheFabricantMysteryBox_FF1.nextFabricantDataID + 1 as UInt32
			emit FabricantDataCreated(fabricantDataID: self.fabricantDataID, mainImage: self.mainImage)
		}
	}
	
	access(all)
	struct Fabricant{ 
		
		// The ID of the FabricantData that the Fabricant references
		access(all)
		let fabricantDataID: UInt32
		
		// The N'th NFT with 'FabricantDataID' minted
		access(all)
		let serialNumber: UInt32
		
		init(fabricantDataID: UInt32){ 
			self.fabricantDataID = fabricantDataID
			
			// Increment the ID so that it isn't used again
			TheFabricantMysteryBox_FF1.numberMintedPerFabricant[fabricantDataID] = TheFabricantMysteryBox_FF1.numberMintedPerFabricant[fabricantDataID]! + 1 as UInt32
			self.serialNumber = TheFabricantMysteryBox_FF1.numberMintedPerFabricant[fabricantDataID]!
		}
	}
	
	// The resource that represents the Fabricant NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Fabricant ID
		access(all)
		let id: UInt64
		
		// struct of Fabricant
		access(all)
		let fabricant: Fabricant
		
		// Royalty capability which NFT will use
		access(all)
		let royaltyVault: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, fabricantDataID: UInt32, royaltyVault: Capability<&{FungibleToken.Receiver}>){ 
			TheFabricantMysteryBox_FF1.totalSupply = TheFabricantMysteryBox_FF1.totalSupply + 1 as UInt64
			self.id = TheFabricantMysteryBox_FF1.totalSupply
			self.fabricant = Fabricant(fabricantDataID: fabricantDataID)
			self.royaltyVault = royaltyVault
			
			// Emitted when a Fabricant is minted
			emit FabricantMinted(fabricantID: self.id, fabricantDataID: fabricantDataID, serialNumber: serialNumber)
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the 
	// various aspects of the Fabricant and NFTs
	//
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createFabricantData(mainImage: String): UInt32{ 
			// Create the new FabricantData
			var newFabricant = FabricantData(mainImage: mainImage)
			let newID = newFabricant.fabricantDataID
			
			// Store it in the contract storage
			TheFabricantMysteryBox_FF1.fabricantDatas[newID] = newFabricant
			TheFabricantMysteryBox_FF1.numberMintedPerFabricant[newID] = 0 as UInt32
			return newID
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Mint the new Fabricant
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(fabricantDataID: UInt32, royaltyVault: Capability<&{FungibleToken.Receiver}>): @NFT{ 
			pre{ 
				royaltyVault.check():
					"Royalty capability is invalid!"
			}
			if TheFabricantMysteryBox_FF1.isFabricantDataRetired[fabricantDataID]! == nil{ 
				panic("Cannot mint Fabricant. fabricantData not found")
			}
			if TheFabricantMysteryBox_FF1.isFabricantDataRetired[fabricantDataID]!{ 
				panic("Cannot mint fabricant. fabricantDataID retired")
			}
			let numInFabricant = TheFabricantMysteryBox_FF1.numberMintedPerFabricant[fabricantDataID] ?? panic("Cannot mint Fabricant. fabricantData not found")
			let newFabricant: @NFT <- create NFT(serialNumber: numInFabricant + 1, fabricantDataID: fabricantDataID, royaltyVault: royaltyVault)
			return <-newFabricant
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintNFT(fabricantDataID: UInt32, royaltyVault: Capability<&{FungibleToken.Receiver}>, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(fabricantDataID: fabricantDataID, royaltyVault: royaltyVault))
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
		
		// Change the royalty percentage of the contract
		access(TMP_ENTITLEMENT_OWNER)
		fun changeRoyaltyPercentage(newRoyaltyPercentage: UFix64){ 
			TheFabricantMysteryBox_FF1.royaltyPercentage = newRoyaltyPercentage
			emit RoyaltyPercentageChanged(newRoyaltyPercentage: newRoyaltyPercentage)
		}
		
		// Retire fabricantData so that it cannot be used to mint anymore
		access(TMP_ENTITLEMENT_OWNER)
		fun retireFabricantData(fabricantDataID: UInt32){ 
			pre{ 
				TheFabricantMysteryBox_FF1.isFabricantDataRetired[fabricantDataID] != nil:
					"Cannot retire Fabricant: Fabricant doesn't exist!"
			}
			if !TheFabricantMysteryBox_FF1.isFabricantDataRetired[fabricantDataID]!{ 
				TheFabricantMysteryBox_FF1.isFabricantDataRetired[fabricantDataID] = true
				emit FabricantDataIDRetired(fabricantDataID: fabricantDataID)
			}
		}
	}
	
	// This is the interface users can cast their Fabricant Collection as
	// to allow others to deposit into their Collection. It also allows for reading
	// the IDs of Fabricant in the Collection.
	access(all)
	resource interface FabricantCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowFabricant(id: UInt64): &TheFabricantMysteryBox_FF1.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Fabricant reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: FabricantCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Fabricant conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Fabricant from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Fabricant does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn Fabricant
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
		
		// deposit takes a Fabricant and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			// Cast the deposited token as NFT to make sure
			// it is the correct type
			let token <- token as! @TheFabricantMysteryBox_FF1.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token tFabricant was "removed"
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
		
		// borrowNFT Returns a borrowed reference to a Fabricant in the Collection
		// so tFabricant the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not an specific data. Please use borrowFabricant to 
		// read Fabricant data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowFabricant(id: UInt64): &TheFabricantMysteryBox_FF1.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TheFabricantMysteryBox_FF1.NFT
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
	// Fabricant contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Fabricant in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create TheFabricantMysteryBox_FF1.Collection()
	}
	
	// get dictionary of numberMintedPerFabricant
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumberMintedPerFabricant():{ UInt32: UInt32}{ 
		return TheFabricantMysteryBox_FF1.numberMintedPerFabricant
	}
	
	// get how many Fabricants with fabricantDataID are minted 
	access(TMP_ENTITLEMENT_OWNER)
	fun getFabricantNumberMinted(id: UInt32): UInt32{ 
		let numberMinted = TheFabricantMysteryBox_FF1.numberMintedPerFabricant[id] ?? panic("fabricantDataID not found")
		return numberMinted
	}
	
	// get the fabricantData of a specific id
	access(TMP_ENTITLEMENT_OWNER)
	fun getFabricantData(id: UInt32): FabricantData{ 
		let fabricantData = TheFabricantMysteryBox_FF1.fabricantDatas[id] ?? panic("fabricantDataID not found")
		return fabricantData
	}
	
	// get all fabricantDatas created
	access(TMP_ENTITLEMENT_OWNER)
	fun getFabricantDatas():{ UInt32: FabricantData}{ 
		return TheFabricantMysteryBox_FF1.fabricantDatas
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFabricantDatasRetired():{ UInt32: Bool}{ 
		return TheFabricantMysteryBox_FF1.isFabricantDataRetired
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFabricantDataRetired(fabricantDataID: UInt32): Bool{ 
		let isFabricantDataRetired = TheFabricantMysteryBox_FF1.isFabricantDataRetired[fabricantDataID] ?? panic("fabricantDataID not found")
		return isFabricantDataRetired
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.fabricantDatas ={} 
		self.numberMintedPerFabricant ={} 
		self.nextFabricantDataID = 1
		self.royaltyPercentage = 0.10
		self.isFabricantDataRetired ={} 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/FabricantCollection004
		self.CollectionStoragePath = /storage/FabricantCollection004
		self.AdminStoragePath = /storage/FabricantAdmin004
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{FabricantCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
