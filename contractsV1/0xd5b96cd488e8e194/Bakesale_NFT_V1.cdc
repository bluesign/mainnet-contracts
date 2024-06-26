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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Bakesale_NFT_V1: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Claimed(id: UInt64, to: Address?)
	
	access(all)
	event SetCreated(setId: UInt32)
	
	access(all)
	event SetAdded(setId: UInt32)
	
	access(all)
	event SetRemoved(setId: UInt32)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of Bakesale_NFT_V1 that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Array of NFTSets that belong to this contract
	access(self)
	var setIds: [UInt32]
	
	// Variable size dictionary of SetData structs
	access(self)
	var setData:{ UInt32: NFTSetData}
	
	// Current number of editions minted per Set
	access(self)
	var numberEditionsMintedPerSet:{ UInt32: UInt32}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		// The IPFS CID of the metadata file.
		access(all)
		let metadata: String
		
		// The Set id references this NFT belongs to
		access(all)
		let setId: UInt32
		
		// The specific edition number for this NFT
		access(all)
		let editionNum: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, metadata: String, setId: UInt32, editionNum: UInt32){ 
			self.id = id
			self.metadata = metadata
			self.setId = setId
			self.editionNum = editionNum
		}
	}
	
	access(all)
	struct NFTSetData{ 
		
		// Unique ID for the Set
		access(all)
		let setId: UInt32
		
		// Max number of editions that can be minted in this set
		access(all)
		let maxEditions: UInt32
		
		// The JSON metadata for each NFT edition can be stored off-chain on IPFS.
		// This is an optional dictionary of IPFS hashes, which will allow marketplaces
		// to pull the metadata for each NFT edition
		access(all)
		var ipfsMetadataHash: String
		
		// The ipfs hash for the media
		access(all)
		var ipfsMediaHash: String
		
		init(setId: UInt32, maxEditions: UInt32, ipfsMetadataHash: String, ipfsMediaHash: String){ 
			self.setId = setId
			self.maxEditions = maxEditions
			self.ipfsMetadataHash = ipfsMetadataHash
			self.ipfsMediaHash = ipfsMediaHash
		}
	}
	
	access(all)
	resource interface Bakesale_NFT_V1CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBakesale_NFT_V1(id: UInt64): &Bakesale_NFT_V1.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Bakesale_NFT_V1 reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: Bakesale_NFT_V1CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		
		// dictionary of NFTs
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
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
			let token <- token as! @Bakesale_NFT_V1.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowBakesale_NFT_V1
		// Gets a reference to an NFT in the collection as a Bakesale_NFT_V1.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBakesale_NFT_V1(id: UInt64): &Bakesale_NFT_V1.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Bakesale_NFT_V1.NFT
			} else{ 
				return nil
			}
		}
		
		// pop
		// Removes and returns the next NFT from the collection.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun pop(): @{NonFungibleToken.NFT}{ 
			let nextID = self.ownedNFTs.keys[0]
			return <-self.withdraw(withdrawID: nextID)
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
	
	// Admin
	// Resource that an admin can use to add sets and mint NFTs.
	//
	access(all)
	resource Admin{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32){ 
			pre{ 
				Bakesale_NFT_V1.numberEditionsMintedPerSet[setId] != nil:
					"The set does not exist."
				Bakesale_NFT_V1.numberEditionsMintedPerSet[setId]! < Bakesale_NFT_V1.getSetMaxEditions(setId: setId)!:
					"This set has minted the maximum number of editions."
				Bakesale_NFT_V1.getIpfsMetadataHashBySet(setId: setId) != nil:
					"The set doesn't have any metadata."
			}
			
			// Gets the number of editions that have been minted so far in 
			// this set
			let editionNum: UInt32 = Bakesale_NFT_V1.numberEditionsMintedPerSet[setId]! + 1 as UInt32
			
			//get the metadata ipfs hash
			let metadata: String = Bakesale_NFT_V1.getIpfsMetadataHashBySet(setId: setId)!
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Bakesale_NFT_V1.NFT(id: Bakesale_NFT_V1.totalSupply, metadata: metadata, setId: setId, editionNum: editionNum))
			
			// Emit a Minted event with the overall NFT id
			emit Minted(id: Bakesale_NFT_V1.totalSupply)
			
			// Update the total count of NFTs
			Bakesale_NFT_V1.totalSupply = Bakesale_NFT_V1.totalSupply + 1 as UInt64
			
			// Update the count of Editions minted in the set
			Bakesale_NFT_V1.numberEditionsMintedPerSet[setId] = editionNum
		}
		
		// batchMintNFT
		// Mints multiple new NFTs given and deposits the NFTs
		// into the recipients collection using their collection reference
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32, quantity: UInt64){ 
			pre{ 
				quantity > 0:
					"Quantity must be > 0"
			}
			var i: UInt64 = 0
			while i < quantity{ 
				self.mintNFT(recipient: recipient, setId: setId)
				i = i + UInt64(1)
			}
		}
		
		// adds an NFT Set to this contract
		access(TMP_ENTITLEMENT_OWNER)
		fun addNftSet(setId: UInt32, maxEditions: UInt32, ipfsMetadataHash: String, ipfsMediaHash: String){ 
			pre{ 
				Bakesale_NFT_V1.setIds.contains(setId) == false:
					"The set has already been added."
			}
			
			// Create the new Set struct
			var newNFTSet = NFTSetData(setId: setId, maxEditions: maxEditions, ipfsMetadataHash: ipfsMetadataHash, ipfsMediaHash: ipfsMediaHash)
			
			// Add the NFTSet to the array of Sets
			Bakesale_NFT_V1.setIds.append(setId)
			
			// Initialize the NFT edition count to zero if it the setId doesn't already exist as a key in the dictionary
			if !Bakesale_NFT_V1.numberEditionsMintedPerSet.containsKey(setId){ 
				Bakesale_NFT_V1.numberEditionsMintedPerSet[setId] = 0
			}
			
			// Store it in the sets mapping field
			Bakesale_NFT_V1.setData[setId] = newNFTSet
			emit SetAdded(setId: setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeNftSet(setId: UInt32){ 
			pre{ 
				Bakesale_NFT_V1.setIds.contains(setId):
					"Could not borrow set: set does not exist."
			}
			var indexOfSetId: Int = 0
			var i = 0
			while i < Bakesale_NFT_V1.setIds.length{ 
				if Bakesale_NFT_V1.setIds[i] == setId{ 
					indexOfSetId = i
					break
				}
				i = i + 1
			}
			Bakesale_NFT_V1.setIds.remove(at: indexOfSetId)
			Bakesale_NFT_V1.setData.remove(key: setId)
			emit SetRemoved(setId: setId)
		}
	}
	
	// fetch
	// Get a reference to a Bakesale_NFT_V1 from an account's Collection, if available.
	// If an account does not have a Bakesale_NFT_V1.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun fetch(_ from: Address, itemID: UInt64): &Bakesale_NFT_V1.NFT?{ 
		let collection = getAccount(from).capabilities.get<&{Bakesale_NFT_V1.Bakesale_NFT_V1CollectionPublic}>(Bakesale_NFT_V1.CollectionPublicPath).borrow<&{Bakesale_NFT_V1.Bakesale_NFT_V1CollectionPublic}>() ?? panic("Couldn't get collection")
		
		// We trust Bakesale_NFT_V1.Collection.borowBakesale_NFT_V1 to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowBakesale_NFT_V1(id: itemID)
	}
	
	// listSetData returns the dictionary of set data
	access(TMP_ENTITLEMENT_OWNER)
	fun listSetData():{ UInt32: NFTSetData}{ 
		return self.setData
	}
	
	// getAllSets returns all the sets
	//
	// Returns: An array of all the sets that have been created
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllSets(): [Bakesale_NFT_V1.NFTSetData]{ 
		return Bakesale_NFT_V1.setData.values
	}
	
	// getSetData returns the NFTSetData for a set.
	// 
	// Parameters: setId: The id of the Set that is being queried
	//
	// Returns: The NFTSetData for this Set
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetData(setId: UInt32): Bakesale_NFT_V1.NFTSetData?{ 
		return Bakesale_NFT_V1.setData[setId]
	}
	
	// getSetMaxEditions returns the maximum number of NFT editions that can
	//		be minted in this Set.
	// 
	// Parameters: setId: The id of the Set that is being queried
	//
	// Returns: The max number of NFT editions in this Set
	access(TMP_ENTITLEMENT_OWNER)
	view fun getSetMaxEditions(setId: UInt32): UInt32?{ 
		return Bakesale_NFT_V1.setData[setId]?.maxEditions
	}
	
	// getNumberEditionsMintedPerSet fetches the number of editions 
	//		minted for a set.
	//
	// Parameters: setId: The id of the Set that is being queried
	//
	// Returns: The number of NFT editions minted in this Set
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumberEditionsMintedPerSet(setId: UInt32): UInt32?{ 
		return Bakesale_NFT_V1.numberEditionsMintedPerSet[setId]
	}
	
	// getIpfsMetadataHashBySet returns the ipfs hash for each nft set.
	// 
	// Parameters: setId: The id of the Set that is being queried
	//
	// Returns: The ipfs hash of nft for the set
	access(TMP_ENTITLEMENT_OWNER)
	view fun getIpfsMetadataHashBySet(setId: UInt32): String?{ 
		if let set = Bakesale_NFT_V1.setData[setId]{ 
			return set.ipfsMetadataHash
		} else{ 
			return nil
		}
	}
	
	// getIpfsMediaHashBySet returns the ipfs hash for each nft set.
	// 
	// Parameters: setId: The id of the Set that is being queried
	//
	// Returns: The ipfs hash of the media for the nft for the set
	access(TMP_ENTITLEMENT_OWNER)
	fun getIpfsMediaHashBySet(setId: UInt32): String?{ 
		// Don't force a revert if the setId or field is invalid
		if let set = Bakesale_NFT_V1.setData[setId]{ 
			return set.ipfsMediaHash
		} else{ 
			return nil
		}
	}
	
	// initializer
	//
	init(){ 
		self.setIds = []
		self.setData ={} 
		self.numberEditionsMintedPerSet ={} 
		
		// Set our named paths
		self.CollectionStoragePath = /storage/Bakesale_NFT_V1Collection
		self.CollectionPublicPath = /public/Bakesale_NFT_V1Collection
		self.CollectionPrivatePath = /private/Bakesale_NFT_V1Collection
		self.AdminStoragePath = /storage/Bakesale_NFT_V1Admin
		
		// Initialize the total supply
		self.totalSupply = 0
		let collection <- Bakesale_NFT_V1.createEmptyCollection(nftType: Type<@Bakesale_NFT_V1.Collection>())
		self.account.storage.save(<-collection, to: Bakesale_NFT_V1.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Bakesale_NFT_V1.Collection>(Bakesale_NFT_V1.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: Bakesale_NFT_V1.CollectionPrivatePath)
		var capability_2 = self.account.capabilities.storage.issue<&Bakesale_NFT_V1.Collection>(Bakesale_NFT_V1.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: Bakesale_NFT_V1.CollectionPublicPath)
		
		// Create an admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
