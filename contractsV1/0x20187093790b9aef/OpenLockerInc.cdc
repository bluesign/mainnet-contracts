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
	Description: 

	authors: Joseph Djenandji, Matthew Balazsi, Jennifer McIntyre
	
*/


// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
// import FungibleToken from "../"./FungibleToken.cdc"/FungibleToken.cdc"
// import MetadataViews from "../"./MetadataViews.cdc"/MetadataViews.cdc"

// for emulator
// import NonFungibleToken from "../"0xNonFungibleToken"/NonFungibleToken.cdc"
// import FungibleToken from "../"0xFungibleToken"/FungibleToken.cdc"
// import MetadataViews from "../"0xMetadataViews"/MetadataViews.cdc"

// for tests
// import NonFungibleToken from "../NonFungibleToken/NonFungibleToken.cdc"
// import MetadataViews from "../MetadataViews/MetadataViews.cdc"

// for testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"

// for mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract OpenLockerInc: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Edition struct is created
	access(all)
	event EditionCreated(id: UInt32, name: String, printingLimit: UInt32?)
	
	// Emitted when Edition Metadata is updated
	access(all)
	event EditionMetadaUpdated(editionID: UInt32)
	
	// default royalties
	access(all)
	event DefaultRoyaltiesUpdated(name: String, cut: UFix64)
	
	// remove default royalty
	access(all)
	event DefaultRoyaltyRemoved(name: String)
	
	// royalties for edition
	access(all)
	event RoyaltiesForEditionUpdated(editionID: UInt32, name: String, cut: UFix64)
	
	// remove royalty for edition
	access(all)
	event RoyaltiesForEditionRemoved(editionID: UInt32, name: String)
	
	// RevertRoyaltiesForEditionToDefault when the admin clears the specific royalties for that edition, to revert back to default royalties
	access(all)
	event RevertRoyaltiesForEditionToDefault(editionID: UInt32)
	
	// Emitted when a new item was minted
	access(all)
	event ItemMinted(itemID: UInt64, merchantID: UInt32, editionID: UInt32, editionNumber: UInt32)
	
	// Item related events 
	//
	// Emitted when an Item is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an Item is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when an Item is destroyed
	access(all)
	event ItemDestroyed(id: UInt64)
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// OpenLockerInc contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Variable size dictionary of Editions resources
	access(self)
	var editions: @{UInt32: Edition}
	
	// the default royalties
	access(self)
	var defaultRoyalties:{ String: MetadataViews.Royalty}
	
	// If a specific NFT requires their own royalties, 
	// the default royalties can be overwritten in this dictionary.
	access(all)
	var royaltiesForSpecificEdition:{ UInt32:{ String: MetadataViews.Royalty}}
	
	// The ID that is used to create Admins. 
	// Every Admins should have a unique identifier.
	access(all)
	var nextAdminID: UInt32
	
	// The ID that is used to create Editions. 
	// Every time an Edition is created, nextEditionID is assigned 
	// to the edition and then is incremented by 1.
	access(all)
	var nextEditionID: UInt32
	
	// The total number of NFTs that have been created for this smart contract
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as global nft IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// OpenLockerInc contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// EditionData is a struct definition to have all of the same fields as the Edition resource.
	// it can be used to publicly read Edition data
	access(all)
	struct EditionData{ 
		access(all)
		let editionID: UInt32
		
		access(all)
		let merchantID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		var items: [UInt64]
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var numberOfItemsMinted: UInt32
		
		access(all)
		var printingLimit: UInt32?
		
		init(editionID: UInt32){ 
			if OpenLockerInc.editions[editionID] == nil{ 
				panic("the editionID was not found")
			}
			let editionToRead = (&OpenLockerInc.editions[editionID] as &Edition?)!
			self.editionID = editionID
			self.metadata = *editionToRead.metadata
			self.merchantID = editionToRead.merchantID
			self.name = editionToRead.name
			self.printingLimit = editionToRead.printingLimit
			self.numberOfItemsMinted = editionToRead.numberOfItemsMinted
			self.items = *editionToRead.items
		}
	}
	
	// Edition is a Ressource that holds metadata associated 
	// with a specific NFT
	//
	// NFTs will all reference an Edition as the owner of
	// its metadata. The Editions are publicly accessible, so anyone can
	// read the metadata associated with a specific EditionID
	//
	access(all)
	resource Edition{ 
		
		// The unique ID for the Edition
		access(all)
		let editionID: UInt32
		
		// The ID of the merchant that owns the edition
		access(all)
		let merchantID: UInt32
		
		// Stores all the metadata about the edition as a string mapping
		// This is not the long term way NFT metadata will be stored. It's a temporary
		// construct while we figure out a better way to do metadata.
		//
		access(all)
		let metadata:{ String: String}
		
		// Array of items that are a part of this collection.
		// When an item is added to the collection, its ID gets appended here.
		access(contract)
		var items: [UInt64]
		
		// The number of items minted in this collection.
		// When an item is added to the collection, the numberOfItems is incremented by 1
		// It will be used to identify the editionNumber of an item
		// if the edition is open (printingLimit=nil), we can keep minting new items
		// if the edition is limited (printingLimit!=nil), we can keep minting items until we reach printingLimit
		access(all)
		var numberOfItemsMinted: UInt32
		
		// the limit of items that can be minted. For open editions, this value should be set to nil.
		access(all)
		var printingLimit: UInt32?
		
		// the name of the edition
		access(all)
		var name: String
		
		init(merchantID: UInt32, metadata:{ String: String}, name: String, printingLimit: UInt32?){ 
			pre{ 
				metadata.length != 0:
					"Metadata cannot be empty"
				name != nil:
					"Name is undefined"
			}
			self.editionID = OpenLockerInc.nextEditionID
			self.merchantID = merchantID
			self.metadata = metadata
			self.name = name
			self.printingLimit = printingLimit
			self.numberOfItemsMinted = 0
			self.items = []
			
			// Increment the ID so that it isn't used again
			OpenLockerInc.nextEditionID = OpenLockerInc.nextEditionID + 1 as UInt32
			emit EditionCreated(id: self.editionID, name: self.name, printingLimit: self.printingLimit)
		}
		
		// mintItem mints a new Item and returns the newly minted Item
		// 
		// Pre-Conditions:
		// If the edition is limited the number of items minted in the edition must be strictly less than the printing limit
		//
		// Returns: The NFT that was minted
		// 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintItem(): @NFT{ 
			pre{ 
				self.numberOfItemsMinted < self.printingLimit ?? 4294967295 as UInt32:
					"We have reached the printing limit for this edition"
			}
			
			// Gets the number of Itms that have been minted for this Edition
			// to use as this Item's edition number
			let numMinted = self.numberOfItemsMinted + 1 as UInt32
			
			// Mint the new item
			let newItem: @NFT <- create NFT(merchantID: self.merchantID, editionID: self.editionID, editionNumber: numMinted)
			
			// Add the Item to the array of items
			self.items.append(newItem.id)
			
			// Increment the count of Items
			self.numberOfItemsMinted = numMinted
			return <-newItem
		}
		
		// batchMintItems mints an arbitrary quantity of Items 
		// and returns them as a Collection
		// Be sure there are enough 
		//
		// Parameters: quantity: The quantity of Items to be minted
		//
		// Returns: Collection object that contains all the Items that were minted
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintItems(quantity: UInt32): @Collection{ 
			pre{ 
				self.numberOfItemsMinted + quantity <= self.printingLimit ?? 4294967295 as UInt32:
					"We have reached the printing limit for this edition"
			}
			let newCollection <- create Collection()
			var i: UInt32 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintItem())
				i = i + 1 as UInt32
			}
			return <-newCollection
		}
		
		// updateMetadata updates the metadata
		//
		// Parameters: 
		//
		// updates: a dictionary of key - values that is requested to be appended
		//
		// suffix: If the metadata already contains an attribute with a given key, this value should still be kept 
		// for posteriority. Therefore, the old value to be replaced will be stored in a metadata entry with key = key+suffix. 
		// This can offer some reassurance to the NFT owner that the metadata will never disappear.
		// 
		// Returns: the EditionID
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMetadata(updates:{ String: String}, suffix: String): UInt32{ 
			
			// prevalidation 
			// if metadata[key] exists and metadata[key+suffix] exists, we have a clash.
			for key in updates.keys{ 
				let newKey = key.concat(suffix)
				if self.metadata[key] != nil && self.metadata[newKey] != nil{ 
					var errorMsg = "attributes "
					errorMsg = errorMsg.concat(key).concat(" and ").concat(newKey).concat(" are already defined")
					panic(errorMsg)
				}
			}
			
			// execution
			for key in updates.keys{ 
				let newKey = key.concat(suffix)
				if self.metadata[key] != nil{ 
					self.metadata[newKey] = self.metadata[key]
				}
				self.metadata[key] = updates[key]
			}
			emit EditionMetadaUpdated(editionID: self.editionID)
			
			// Return the EditionID and return it
			return self.editionID
		}
	}
	
	// The struct representing an NFT Item data
	access(all)
	struct ItemData{ 
		
		// The ID of the merchant 
		access(all)
		let merchantID: UInt32
		
		// The ID of the edition that the NFT comes from
		access(all)
		let editionID: UInt32
		
		// The number of the NFT within the edition
		access(all)
		let editionNumber: UInt32
		
		init(merchantID: UInt32, editionID: UInt32, editionNumber: UInt32){ 
			self.merchantID = merchantID
			self.editionID = editionID
			self.editionNumber = editionNumber
		}
	}
	
	// The resource that represents the Item NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// Global unique item ID
		access(all)
		let id: UInt64
		
		// Struct of the metadata
		access(all)
		let data: ItemData
		
		init(merchantID: UInt32, editionID: UInt32, editionNumber: UInt32){ 
			pre{ 
				editionID > 0 as UInt32:
					"editionID cannot be 0"
				editionNumber > 0 as UInt32:
					"editionNumber cannot be 0"
			}
			// Increment the global Item IDs
			OpenLockerInc.totalSupply = OpenLockerInc.totalSupply + 1 as UInt64
			self.id = OpenLockerInc.totalSupply
			
			// Set the metadata struct
			self.data = ItemData(merchantID: merchantID, editionID: editionID, editionNumber: editionNumber)
			emit ItemMinted(itemID: self.id, merchantID: merchantID, editionID: editionID, editionNumber: editionNumber)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let edition = EditionData(editionID: self.data.editionID)
					return MetadataViews.Display(name: edition.name, description: edition.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: edition.metadata["thumbnail"] ?? ""))
				case Type<MetadataViews.Editions>():
					let edition = EditionData(editionID: self.data.editionID)
					let maxNumber = edition.printingLimit ?? nil
					var max: UInt64? = nil
					if maxNumber != nil{ 
						max = UInt64(maxNumber!)
					}
					let editionInfo = MetadataViews.Edition(name: edition.name, number: UInt64(self.data.editionNumber), max: max)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.ExternalURL>():
					let edition = EditionData(editionID: self.data.editionID)
					let url = edition.metadata["externalUrl"] ?? ""
					return MetadataViews.ExternalURL(url)
				case Type<MetadataViews.Royalties>():
					let royaltiesDictionary = OpenLockerInc.royaltiesForSpecificEdition[self.data.editionID] ?? OpenLockerInc.defaultRoyalties
					var royalties: [MetadataViews.Royalty] = []
					for royaltyName in royaltiesDictionary.keys{ 
						royalties.append(royaltiesDictionary[royaltyName]!)
					}
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let edition = EditionData(editionID: self.data.editionID)
					let squareImage = edition.metadata["squareImage"] ?? ""
					let squareImageType = edition.metadata["squareImageType"] ?? ""
					let bannerImage = edition.metadata["bannerImage"] ?? ""
					let bannerImageType = edition.metadata["bannerImageType"] ?? ""
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: squareImage), mediaType: squareImageType)
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: bannerImage), mediaType: bannerImageType)
					let url = edition.metadata["externalUrl"] ?? ""
					let description = edition.metadata["description"] ?? ""
					return MetadataViews.NFTCollectionDisplay(name: "OpenLockerInc", description: description, externalURL: MetadataViews.ExternalURL(url), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{} )
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: OpenLockerInc.CollectionStoragePath, publicPath: OpenLockerInc.CollectionPublicPath, publicCollection: Type<&OpenLockerInc.Collection>(), publicLinkedType: Type<&OpenLockerInc.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-OpenLockerInc.createEmptyCollection(nftType: Type<@OpenLockerInc.Collection>())
						})
				case Type<MetadataViews.Traits>():
					// exclude essential metadata to keep unique traits
					let excludedTraits = ["name", "description", "externalUrl", "squareImage", "squareImageType", "bannerImage", "bannerImageType", "thumbnail", "thumbnailType"]
					let edition = EditionData(editionID: self.data.editionID)
					let traitsView = MetadataViews.dictToTraits(dict: edition.metadata, excludedNames: excludedTraits)
					return traitsView
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(UInt64(self.data.editionNumber))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	
	// If the Item is destroyed, emit an event to indicate 
	// to outside ovbservers that it has been destroyed
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the Editions and Items
	//
	access(all)
	resource Admin{ 
		access(all)
		let id: UInt32
		
		// createEdition creates a new Edition struct 
		// and stores it in the Editions dictionary in the contract
		//
		init(id: UInt32){ 
			self.id = id
		}
		
		// createEdition creates a new Edition resource and stores it
		// in the editions mapping in the contract
		//
		// Parameters: 
		//  merchantID: The ID of the merchant
		//  metadata: the associated data
		//  name: The name of the Edition
		//  printingLimit: We can only mint this quantity of NFTs. If printingLimit is nil there is no limit (theoretically UInt32.max)
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createEdition(merchantID: UInt32, metadata:{ String: String}, name: String, printingLimit: UInt32?){ 
			// Create the new Edition
			var newEdition <- create Edition(merchantID: merchantID, metadata: metadata, name: name, printingLimit: printingLimit)
			let newID = newEdition.editionID
			
			// Store it in the contract storage
			OpenLockerInc.editions[newID] <-! newEdition
		}
		
		// borrowEdition returns a reference to an edition in the OpenLockerInc
		// contract so that the admin can call methods on it
		//
		// Parameters: editionID: The ID of the Edition that you want to
		// get a reference to
		//
		// Returns: A reference to the Edition with all of the fields
		// and methods exposed
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEdition(editionID: UInt32): &Edition{ 
			pre{ 
				OpenLockerInc.editions[editionID] != nil:
					"Cannot borrow Edition: it does not exist"
			}
			
			// Get a reference to the Edition and return it
			return (&OpenLockerInc.editions[editionID] as &Edition?)!
		}
		
		// updateEditionMetadata returns a reference to an edition in the OpenLockerInc
		// contract so that the admin can call methods on it
		//
		// Parameters: 
		// editionID: The ID of the Edition that you want to update
		//
		// updates: a dictionary of key - values that is requested to be appended
		//
		// suffix: If the metadata already contains an attribute with a given key, this value should still be kept 
		// for posteriority. Therefore, the old value to be replaced will be stored in a metadata entry with key = key+suffix. 
		// This can offer some reassurance to the NFT owner that the metadata will never disappear.
		// 
		// Returns: the EditionID
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun updateEditionMetadata(editionID: UInt32, updates:{ String: String}, suffix: String): UInt32{ 
			pre{ 
				OpenLockerInc.editions[editionID] != nil:
					"Cannot borrow Edition: it does not exist"
			}
			let editionRef = &OpenLockerInc.editions[editionID] as &Edition?
			(editionRef!).updateMetadata(updates: updates, suffix: suffix)
			
			// Return the EditionID and return it
			return editionID
		}
		
		// set default royalties
		access(TMP_ENTITLEMENT_OWNER)
		fun setDefaultRoyaltyByName(name: String, royalty: MetadataViews.Royalty){ 
			OpenLockerInc.defaultRoyalties[name] = royalty
			// verify total
			let totalCut = OpenLockerInc.getDefaultRoyaltyTotalRate()
			assert(totalCut <= 1.0, message: "Sum of cutInfos multipliers should not be greater than 1.0")
			emit DefaultRoyaltiesUpdated(name: name, cut: royalty.cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeDefaultRoyaltyByName(name: String){ 
			if !OpenLockerInc.defaultRoyalties.containsKey(name){ 
				var errorMsg = "Default Royalty with name ["
				errorMsg = errorMsg.concat(name).concat("] does not exist")
				panic(errorMsg)
			}
			OpenLockerInc.defaultRoyalties.remove(key: name)
			emit DefaultRoyaltyRemoved(name: name)
		}
		
		// set royalties for edition
		access(TMP_ENTITLEMENT_OWNER)
		fun setEditionRoyaltyByName(editionID: UInt32, name: String, royalty: MetadataViews.Royalty){ 
			if !OpenLockerInc.royaltiesForSpecificEdition.containsKey(editionID){ 
				OpenLockerInc.royaltiesForSpecificEdition.insert(key: editionID,{} )
			}
			(			 //let royaltiesForSpecificEdition = OpenLockerInc.royaltiesForSpecificEdition[editionID]!
			 //royaltiesForSpecificEdition.insert(key: name, royalty);
			 OpenLockerInc.royaltiesForSpecificEdition[editionID]!).insert(key: name, royalty)
			let totalCut = OpenLockerInc.getEditionRoyaltyTotalRate(editionID: editionID)
			assert(totalCut <= 1.0, message: "Sum of cutInfos multipliers should not be greater than 1.0")
			emit RoyaltiesForEditionUpdated(editionID: editionID, name: name, cut: royalty.cut)
		}
		
		// remove royalty for edition
		access(TMP_ENTITLEMENT_OWNER)
		fun removeEditionRoyaltyByName(editionID: UInt32, name: String){ 
			if !OpenLockerInc.royaltiesForSpecificEdition.containsKey(editionID){ 
				var errorMsg = "Royalty specific to editionID"
				errorMsg = errorMsg.concat(editionID.toString()).concat(" does not exist")
				panic(errorMsg)
			}
			let royaltiesForSpecificEdition = OpenLockerInc.royaltiesForSpecificEdition[editionID]!
			if !royaltiesForSpecificEdition.containsKey(name){ 
				var errorMsg = "Royalty specific to editionID"
				errorMsg = errorMsg.concat(editionID.toString()).concat(" with the name[").concat(name).concat("] does not exist")
				panic(errorMsg)
			}
			(OpenLockerInc.royaltiesForSpecificEdition[editionID]!).remove(key: name)
			emit RoyaltiesForEditionRemoved(editionID: editionID, name: name)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun revertRoyaltiesForEditionToDefault(editionID: UInt32){ 
			if !OpenLockerInc.royaltiesForSpecificEdition.containsKey(editionID){ 
				var errorMsg = "Royalty for editionID "
				errorMsg = errorMsg.concat(editionID.toString()).concat("  does not exist")
				panic(errorMsg)
			}
			OpenLockerInc.royaltiesForSpecificEdition.remove(key: editionID)
			emit RevertRoyaltiesForEditionToDefault(editionID: editionID)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			let newID = OpenLockerInc.nextAdminID
			// Increment the ID so that it isn't used again
			OpenLockerInc.nextAdminID = OpenLockerInc.nextAdminID + 1 as UInt32
			return <-create Admin(id: newID)
		}
	}
	
	// This is the interface that users can cast their OpenLockerInc Collection as
	// to allow others to deposit OpenLockerIncs into their Collection. It also allows for reading
	// the IDs of OpenLockerIncs in the Collection.
	access(all)
	resource interface OpenLockerIncCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOpenLockerInc(id: UInt64): &OpenLockerInc.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow OpenLockerInc reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: OpenLockerIncCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of OpenLockerInc conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// pub var ownedNFTs: @{UInt64: OpenLockerInc.NFT}
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes a OpenLockerInc from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: OpenLockerInc does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn OpenLockerInc items
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				let token <- self.withdraw(withdrawID: id)
				batchCollection.deposit(token: <-token)
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a OpenLockerInc and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			
			// Cast the deposited token as a OpenLockerInc NFT to make sure
			// it is the correct type
			let token <- token as! @OpenLockerInc.NFT
			
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
		
		// borrowNFT Returns a borrowed reference to a OpenLockerInc in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any OpenLockerInc specific data. Please use borrowOpenLockerInc to 
		// read OpenLockerInc data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowOpenLockerInc returns a borrowed reference to a OpenLockerInc
		// so that the caller can read data and call methods from it.
		// They can use this to read its editionID, editionNumber,
		// or any edition data associated with it by
		// getting the editionID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOpenLockerInc(id: UInt64): &OpenLockerInc.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &OpenLockerInc.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let OpenLockerIncNFT = nft as! &OpenLockerInc.NFT
			return OpenLockerIncNFT as &{ViewResolver.Resolver}
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
	// All the NFTs contained within are also destroyed
	//
	}
	
	// -----------------------------------------------------------------------
	// OpenLockerInc contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// OpenLockerIncs in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create OpenLockerInc.Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyOpenLockerIncCollection(): @OpenLockerInc.Collection{ 
		return <-create OpenLockerInc.Collection()
	}
	
	// getDefaultRoyalties returns the default royalties
	access(TMP_ENTITLEMENT_OWNER)
	fun getDefaultRoyalties():{ String: MetadataViews.Royalty}{ 
		return self.defaultRoyalties
	}
	
	// getDefaultRoyalties returns the default royalties
	access(TMP_ENTITLEMENT_OWNER)
	fun getDefaultRoyaltyNames(): [String]{ 
		return self.defaultRoyalties.keys
	}
	
	// getDefaultRoyalties returns the default royalties
	access(TMP_ENTITLEMENT_OWNER)
	fun getDefaultRoyaltyByName(name: String): MetadataViews.Royalty?{ 
		return self.defaultRoyalties[name]
	}
	
	// getDefaultRoyalties returns the default royalties total rate
	access(TMP_ENTITLEMENT_OWNER)
	fun getDefaultRoyaltyTotalRate(): UFix64{ 
		var cut = 0.0
		for name in self.defaultRoyalties.keys{ 
			cut = cut + (self.defaultRoyalties[name]!).cut
		}
		return cut
	}
	
	// getRoyaltiesForEdition returns the royalties set for a specific edition, that overrides the default
	access(TMP_ENTITLEMENT_OWNER)
	fun getEditionRoyalties(editionID: UInt32):{ String: MetadataViews.Royalty}{ 
		return self.royaltiesForSpecificEdition[editionID] ?? self.defaultRoyalties
	}
	
	// getRoyaltiesForEdition returns the royalties set for a specific edition, that overrides the default
	access(TMP_ENTITLEMENT_OWNER)
	fun getEditionRoyaltyNames(editionID: UInt32): [String]{ 
		let royalties = OpenLockerInc.getEditionRoyalties(editionID: editionID)
		return royalties.keys
	}
	
	// getRoyaltiesForEdition returns the royalties set for a specific edition, that overrides the default
	access(TMP_ENTITLEMENT_OWNER)
	fun getEditionRoyaltyByName(editionID: UInt32, name: String): MetadataViews.Royalty{ 
		let royaltiesForSpecificEdition = OpenLockerInc.getEditionRoyalties(editionID: editionID)
		return royaltiesForSpecificEdition[name]!
	}
	
	// getDefaultRoyalties returns the default royalties total rate
	access(TMP_ENTITLEMENT_OWNER)
	fun getEditionRoyaltyTotalRate(editionID: UInt32): UFix64{ 
		let royalties = OpenLockerInc.getEditionRoyalties(editionID: editionID)
		var cut = 0.0
		for name in royalties.keys{ 
			cut = cut + (royalties[name]!).cut
		}
		return cut
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.editions <-{} 
		self.nextEditionID = 1
		self.totalSupply = 0
		self.defaultRoyalties ={} 
		self.royaltiesForSpecificEdition ={} 
		self.CollectionStoragePath = /storage/OpenLockerIncCollection
		self.CollectionPublicPath = /public/OpenLockerIncCollection
		self.AdminStoragePath = /storage/OpenLockerIncItemAdmin
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{OpenLockerIncCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the admin ressource in storage
		self.account.storage.save<@Admin>(<-create Admin(id: 1), to: self.AdminStoragePath)
		self.nextAdminID = 2
		emit ContractInitialized()
	}
}
