//  SPDX-License-Identifier: UNLICENSED
//
//  Description: Attack On Titan Legacy
//  This is NonFungibleToken and Anique NFT.
//
//  authors: Atsushi Otani atsushi.ootani@anique.jp
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Anique from "../0xe2e1689b53e92a82/Anique.cdc"

access(all)
contract ContractAniq0926: NonFungibleToken, Anique{ 
	// -----------------------------------------------------------------------
	// ContractAniq0926 contract Events
	// -----------------------------------------------------------------------
	
	// Events for Contract-Related actions
	//
	// Emitted when the ContractAniq0926 contract is created
	access(all)
	event ContractInitialized()
	
	// Events for Item-Related actions
	//
	// Emitted when a new Item struct is created
	access(all)
	event ItemCreated(id: UInt32, metadata:{ String: String})
	
	// Events for Collectible-Related actions
	//
	// Emitted when an CollectibleData NFT is minted
	access(all)
	event CollectibleMinted(collectibleID: UInt64, itemID: UInt32, serialNumber: UInt32)
	
	// Emitted when an CollectibleData NFT is destroyed
	access(all)
	event CollectibleDestroyed(collectibleID: UInt64)
	
	// events for Collection-related actions
	//
	// Emitted when an CollectibleData is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an CollectibleData is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// paths
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	let collectionPrivatePath: PrivatePath
	
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	let saleCollectionStoragePath: StoragePath
	
	access(all)
	let saleCollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// ContractAniq0926 contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// fields for Item-related
	//
	// variable size dictionary of Item resources
	access(self)
	var items: @{UInt32: Item}
	
	// The ID that is used to create Items.
	access(all)
	var nextItemID: UInt32
	
	// fields for Collectible-related
	//
	// Total number of CollectibleData NFTs that have been minted ever.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// ContractAniq0926 contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// The structure that represents Item
	// each digital content which ContractAniq0926 deal with on Flow
	//
	access(all)
	struct ItemData{ 
		access(all)
		let itemID: UInt32
		
		access(all)
		let metadata:{ String: String}
		
		init(itemID: UInt32){ 
			let item = (&ContractAniq0926.items[itemID] as &Item?)!
			self.itemID = item.itemID
			self.metadata = *item.metadata
		}
	}
	
	// Item is a resource type that contains the functions to mint Collectibles.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods and that there can be
	// public getters for some of its fields
	//
	// The admin can mint Collectibles that refer from Item.
	access(all)
	resource Item{ 
		
		// unique ID for the Item
		access(all)
		let itemID: UInt32
		
		// Stores all the metadata about the item as a string mapping
		// This is not the long term way NFT metadata will be stored. It's a temporary
		// construct while we figure out a better way to do metadata.
		//
		access(all)
		let metadata:{ String: String}
		
		// The number of Collectibles that have been minted per Item.
		access(contract)
		var numberMintedPerItem: UInt32
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Item metadata cannot be empty"
			}
			self.itemID = ContractAniq0926.nextItemID
			self.metadata = metadata
			self.numberMintedPerItem = 0
			
			// increment the nextItemID so that it isn't used again
			ContractAniq0926.nextItemID = ContractAniq0926.nextItemID + 1
			emit ItemCreated(id: self.itemID, metadata: metadata)
		}
		
		// mintCollectible mints a new Collectible and returns the newly minted Collectible
		//
		// Returns: The NFT that was minted
		//
		access(all)
		fun mintCollectible(): @NFT{ 
			// get the number of Collectibles that have been minted for this Item
			// to use as this Collectible's serial number
			let numInItem = self.numberMintedPerItem
			
			// mint the new Collectible
			let newCollectible: @NFT <- create NFT(serialNumber: numInItem + 1, itemID: self.itemID)
			
			// Increment the count of Collectibles minted for this Item
			self.numberMintedPerItem = numInItem + 1
			return <-newCollectible
		}
		
		// batchMintCollectible mints an arbitrary quantity of Collectibles
		// and returns them as a Collection
		//
		// Parameters: itemID: the ID of the Item that the Collectibles are minted for
		//			 quantity: The quantity of Collectibles to be minted
		//
		// Returns: Collection object that contains all the Collectibles that were minted
		//
		access(all)
		fun batchMintCollectible(quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintCollectible())
				i = i + 1
			}
			return <-newCollection
		}
		
		// Returns: the number of Collectibles
		access(all)
		fun getNumberMinted(): UInt32{ 
			return self.numberMintedPerItem
		}
	}
	
	// The structure holds metadata of an Collectible
	access(all)
	struct CollectibleData{ 
		// The ID of the Item that the Collectible references
		access(all)
		let itemID: UInt32
		
		// The place in the Item that this Collectible was minted
		access(all)
		let serialNumber: UInt32
		
		init(itemID: UInt32, serialNumber: UInt32){ 
			self.itemID = itemID
			self.serialNumber = serialNumber
		}
	}
	
	// The resource that represents the CollectibleData NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.INFT, Anique.INFT{ 
		
		// Global unique collectibleData ID
		access(all)
		let id: UInt64
		
		// Struct of Collectible metadata
		access(all)
		let data: CollectibleData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, itemID: UInt32){ 
			// Increment the global Collectible IDs
			ContractAniq0926.totalSupply = ContractAniq0926.totalSupply + 1
			
			// set id
			self.id = ContractAniq0926.totalSupply
			
			// Set the metadata struct
			self.data = CollectibleData(itemID: itemID, serialNumber: serialNumber)
			emit CollectibleMinted(collectibleID: self.id, itemID: itemID, serialNumber: self.data.serialNumber)
		}
	}
	
	// interface that represents ContractAniq0926 collections to public
	// extends of NonFungibleToken.CollectionPublic
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		// deposit multi tokens
		access(all)
		fun batchDeposit(tokens: @{Anique.Collection})
		
		// contains NFT
		access(all)
		fun contains(id: UInt64): Bool
		
		// borrow NFT as ContractAniq0926 token
		access(all)
		fun borrowContractAniq0926Collectible(id: UInt64): &NFT
	}
	
	// Collection is a resource that every user who owns NFTs
	// will store in their account to manage their NFTs
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of CollectibleData conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes a Collectible from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Collectible does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: collectibleIds: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn collectibles
		//
		access(all)
		fun batchWithdraw(collectibleIds: [UInt64]): @{Anique.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the collectibleIds and withdraw them from the Collection
			for collectibleID in collectibleIds{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: collectibleID))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a Collectible and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited token as an ContractAniq0926 NFT to make sure
			// it is the correct type
			let token <- token as! @ContractAniq0926.NFT
			
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
		access(all)
		fun batchDeposit(tokens: @{Anique.Collection}){ 
			
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
		
		// contains returns whether ID is in the Collection
		access(all)
		fun contains(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// borrowNFT Returns a borrowed reference to a Collectible in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any ContractAniq0926 specific data. Please use borrowCollectible to
		// read Collectible data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowAniqueNFT(id: UInt64): &{Anique.NFT}{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &{Anique.NFT}
		}
		
		// borrowContractAniq0926Collectible returns a borrowed reference
		// to an ContractAniq0926 Collectible
		access(all)
		fun borrowContractAniq0926Collectible(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection!"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &NFT
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	//
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the
	// various aspects of the Items, CollectibleDatas, etc.
	//
	access(all)
	resource Admin{ 
		
		// createItem creates a new Item struct
		// and stores it in the Items dictionary field in the ContractAniq0926 smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//					   example: {"Title": "Excellent Anime", "Author": "John Smith"}
		//
		// Returns: the ID of the new Item object
		//
		access(all)
		fun createItem(metadata:{ String: String}): UInt32{ 
			// Create the new Item
			var newItem <- create Item(metadata: metadata)
			let itemId = newItem.itemID
			
			// Store it in the contract storage
			ContractAniq0926.items[newItem.itemID] <-! newItem
			return itemId
		}
		
		// borrowItem returns a reference to a Item in the ContractAniq0926
		// contract so that the admin can call methods on it
		//
		// Parameters: itemID: The ID of the Item that you want to
		// get a reference to
		//
		// Returns: A reference to the Item with all of the fields
		// and methods exposed
		//
		access(all)
		fun borrowItem(itemID: UInt32): &Item{ 
			pre{ 
				ContractAniq0926.items[itemID] != nil:
					"Cannot borrow Item: The Item doesn't exist"
			}
			return (&ContractAniq0926.items[itemID] as &Item?)!
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// -----------------------------------------------------------------------
	// ContractAniq0926 contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Collectibles in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ContractAniq0926.Collection()
	}
	
	// getNumCollectiblesInItem return the number of Collectibles that have been
	//						minted from a certain Item.
	//
	// Parameters: itemID: The id of the Item that is being searched
	//
	// Returns: The total number of Collectibles
	//		  that have been minted from a Item
	access(all)
	fun getNumCollectiblesInItem(itemID: UInt32): UInt32{ 
		let item = (&ContractAniq0926.items[itemID] as &Item?)!
		return item.numberMintedPerItem
	}
	
	// -----------------------------------------------------------------------
	// ContractAniq0926 initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.items <-{} 
		self.nextItemID = 1
		self.totalSupply = 0
		self.collectionStoragePath = /storage/ContractAniq0926Collection
		self.collectionPublicPath = /public/ContractAniq0926Collection
		self.collectionPrivatePath = /private/ContractAniq0926Collection
		self.adminStoragePath = /storage/ContractAniq0926Admin
		self.saleCollectionStoragePath = /storage/ContractAniq0926SaleCollection
		self.saleCollectionPublicPath = /public/ContractAniq0926SaleCollection
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.collectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{CollectionPublic}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		
		// Put the Admin in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.adminStoragePath)
		emit ContractInitialized()
	}
}
