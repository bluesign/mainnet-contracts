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
	Description: Central Smart Contract for DarkCountry NFTs

	authors: Ivan Kravets evan@dapplica.io

	This smart contract contains the core functionality for
	DarkCountry NFTs.

	The contract manages the data associated with all the ItemTemplate structures
	that are used as templates for the DarkCountry NFTs

	When a new NFTs wants to be added to the records and the type of the
	NFT is not registered, a Minter creates
	a new ItemTemplate struct that is stored in the smart contract.

	E.g. Minter creates Item Template for Rare Land Pack, sets data associated with it.
	Then they can mint new multiple NFTs of Common Rare Pack type by specifying
	the appropriate item template ID.

	Item Template is a public struct that
	contains public information about the item template.
	The private NFTMinter resource is used to mint new NFTs.

	The NFT minter resource has the power to do configuration actions
	in the smart contract. When Minter wants to call functions in an ItemTemplate,
	they call their borrowSet function to get a reference
	to an ItemTemplate structure in the contract.
	Then, they can call functions on the ItemTemplate using that reference.

	The contract also defines a Collection resource. This is an object that
	every DarkCountry NFT owner will store in their account
	to manage their NFT collection.

	The main DarkCountry account and / or an account that holds NFT Minter resource,
	will also have theirs own NFTs collections.
	Those can be used to hold its own minted NFTs that have not yet been sent to a user.

	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
	Functions that don't modify state will simply return 0 or nil
	and those cases need to be handled by the caller.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DarkCountryStaking from "./DarkCountryStaking.cdc"

access(all)
contract DarkCountry: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Events
	// -----------------------------------------------------------------------
	
	// Emitted when the DarkCountry contract is created
	access(all)
	event ContractInitialized()
	
	// Events for Collection-related actions
	//
	// Emitted when a NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a NFT is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a NFT is minted
	access(all)
	event Minted(id: UInt64, typeID: UInt64, serialNumber: UInt64)
	
	// Emitted when a new ItemTemplate struct is created
	access(all)
	event ItemTemplateCreated(id: UInt64, metadata:{ String: String})
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// The total number of DarkCountry NFTs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// The ID that is used to create ItemTemplate structs.
	// Every time an ItemTemplate is created, nextItemTemplateID is assigned
	// to the new ItemTemplate's ID and then is incremented by 1
	access(all)
	var nextItemTemplateID: UInt64
	
	// Variable size dictionary of number of minted items per
	// a certain item template
	//
	// In other words it can be considered as totalSupply of
	// NFTs of a certain type
	access(account)
	var numberMintedPerItemTemplate:{ UInt64: UInt64}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumberMintedPerItemTemplate(paramItemTemplateID: UInt64): UInt64?{ 
		return self.numberMintedPerItemTemplate[paramItemTemplateID]
	}
	
	// Variable size dictionary of ItemTemplate structs
	access(self)
	var itemTemplates:{ UInt64: ItemTemplate}
	
	// ItemTemplate is a Struct that holds metadata associated
	// with a specific NFT type, like Common Land Packs all share
	// the same data associated with them, e.g. name, series, description, rarity.
	//
	// DarkCountry NFTs will all reference a single ItemTemplate as the holder of
	// its metadata. The ItemTemplate structs are publicly accessible, so anyone can
	// read the metadata associated with a specific NFT's TypeID
	//
	access(all)
	struct ItemTemplate{ 
		
		// The unique ID for the ItemTemplate
		access(all)
		let itemTemplateID: UInt64
		
		// Stores all the metadata about a specific NFT type, e.g. "name": "Common Land Pack"
		// as a string mappings
		//
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New ItemTemplate metadata cannot be empty"
			}
			self.itemTemplateID = DarkCountry.nextItemTemplateID
			self.metadata = metadata
			
			// Increment the item template ID so that it isn't used again
			DarkCountry.nextItemTemplateID = DarkCountry.nextItemTemplateID + 1 as UInt64
			
			// Explicitly set the counter of minted items for newly created item template to 0
			DarkCountry.numberMintedPerItemTemplate[self.itemTemplateID] = 0 as UInt64
			emit ItemTemplateCreated(id: self.itemTemplateID, metadata: metadata)
		}
	}
	
	// getAllItemTemplates returns all the created item templates
	//
	// Returns: An array of all the item templates that have been created
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllItemTemplates(): [DarkCountry.ItemTemplate]{ 
		return DarkCountry.itemTemplates.values
	}
	
	// getItemTemplateMetaData returns all the metadata associated with a specific ItemTemplate
	//
	// Parameters: itemTemplateID: The id of the ItemTemplate that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getItemTemplateMetaData(itemTemplateID: UInt64):{ String: String}?{ 
		return self.itemTemplates[itemTemplateID]?.metadata
	}
	
	// getItemTemplateMetaDataByField returns the metadata associated with a
	// specific field of the metadata
	// Ex: field: "Rarity" will return something like "Super Rare"
	//
	// Parameters: itemTemplateID: The id of the ItemTemplate that is being searched
	//			 field: The field to search for
	//
	// Returns: The metadata field as a String Optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getItemTemplateMetaDataByField(itemTemplateID: UInt64, field: String): String?{ 
		if let itemTemplate = DarkCountry.itemTemplates[itemTemplateID]{ 
			return itemTemplate.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// NFT
	// A DarkCountry item as a NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		// Increments once once any new NFT is minted
		access(all)
		let id: UInt64
		
		// The token's item template, e.g. 1 for "Common Land Pack"
		access(all)
		let itemTemplateID: UInt64
		
		// The token's serial number
		// Specific for an ItemTemplate
		access(all)
		let serialNumber: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initItemTemplateID: UInt64, initSerialNumber: UInt64){ 
			self.id = initID
			self.itemTemplateID = initItemTemplateID
			self.serialNumber = initSerialNumber
		}
	}
	
	// This is the interface that users can cast their DarkCountry Collection as
	// to allow others to deposit DarkCountry into their Collection. It also allows for reading
	// the details of DarkCountry in the Collection.
	//
	access(all)
	resource interface DarkCountryCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDarkCountryNFT(id: UInt64): &DarkCountry.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DarkCountry reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of DarkCountry NFTs owned by an account
	//
	access(all)
	resource Collection: DarkCountryCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// make sure the NFT is not staked
			if DarkCountryStaking.stakedItems.containsKey(self.owner?.address!) && (DarkCountryStaking.stakedItems[self.owner?.address!]!).contains(withdrawID){ 
				panic("Cannot withdraw: the NFT is staked.")
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @DarkCountry.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowDarkCountry
		// Gets a reference to an NFT in the collection as a DarkCountry NFT,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the DarkCountry.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDarkCountryNFT(id: UInt64): &DarkCountry.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DarkCountry.NFT
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
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFT Minter
	// Resource that admin would own to be
	// able to:
	//  1. Add new ItemTemplates that would define a new NFT type and its metadata
	//  2. Mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemTemplateID: UInt64){ 
			// make sure the aseetTypeID is a valid one
			pre{ 
				DarkCountry.itemTemplates[itemTemplateID] != nil:
					"Cannot mintNFT: itemTemplate doesn't exist."
			}
			
			// Gets the number of NFTs of the item template that have been minted
			// to use as this NFT's serial number
			let numOfItemTemplateNFTs = DarkCountry.numberMintedPerItemTemplate[itemTemplateID]!
			emit Minted(id: DarkCountry.totalSupply, typeID: itemTemplateID, serialNumber: numOfItemTemplateNFTs)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create DarkCountry.NFT(initID: DarkCountry.totalSupply, initItemTemplateID: itemTemplateID, initSerialNumber: numOfItemTemplateNFTs))
			DarkCountry.totalSupply = DarkCountry.totalSupply + 1 as UInt64
			DarkCountry.numberMintedPerItemTemplate[itemTemplateID] = numOfItemTemplateNFTs + 1 as UInt64
		}
		
		// createItemTemplate creates a new ItemTemplate struct
		// and stores it in the itemTemplates dictionary in the DarkCountry smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//					   example: {"name": "Land Pack", "Rarity": "Super Rare"}
		//
		// Returns: the ID of the new itemTemplate object
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createItemTemplate(metadata:{ String: String}): UInt64{ 
			// Create the new ItemTemplate
			var newItemTemplate = ItemTemplate(metadata: metadata)
			let newID = newItemTemplate.itemTemplateID
			
			// Store it in the contract storage
			DarkCountry.itemTemplates[newID] = newItemTemplate
			return newID
		}
		
		// createNewNFTMinter creates a new NFTMinter resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
	}
	
	// fetch
	// Get a reference to a DarkCountry NFT from an account's Collection, if available.
	// If an account does not have a DarkCountry.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun fetch(_ from: Address, itemID: UInt64): &DarkCountry.NFT?{ 
		let collection = getAccount(from).capabilities.get<&DarkCountry.Collection>(DarkCountry.CollectionPublicPath).borrow<&DarkCountry.Collection>() ?? panic("Couldn't get collection")
		// We trust DarkCountry.Collection.borowDarkCountryNFT to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowDarkCountryNFT(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/DarkCountryCollection
		self.CollectionPublicPath = /public/DarkCountryCollection
		self.MinterStoragePath = /storage/DarkCountryMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		self.nextItemTemplateID = 1
		self.numberMintedPerItemTemplate ={} 
		self.itemTemplates ={} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
