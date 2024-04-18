import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Bakesale_Beer_NFT: NonFungibleToken{ 
	
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
	// The total number of Bakesale_Beer_NFT that have been minted
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
	resource NFT: NonFungibleToken.INFT{ 
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
	resource interface Bakesale_Beer_NFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBakesale_Beer_NFT(id: UInt64): &Bakesale_Beer_NFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Bakesale_Beer_NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: Bakesale_Beer_NFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		
		// dictionary of NFTs
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
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
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Bakesale_Beer_NFT.NFT
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
		
		// borrowBakesale_Beer_NFT
		// Gets a reference to an NFT in the collection as a Bakesale_Beer_NFT.
		//
		access(all)
		fun borrowBakesale_Beer_NFT(id: UInt64): &Bakesale_Beer_NFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Bakesale_Beer_NFT.NFT
			} else{ 
				return nil
			}
		}
		
		// pop
		// Removes and returns the next NFT from the collection.
		//
		access(all)
		fun pop(): @{NonFungibleToken.NFT}{ 
			let nextID = self.ownedNFTs.keys[0]
			return <-self.withdraw(withdrawID: nextID)
		}
		
		// size
		// Returns the current size of the collection.
		access(all)
		fun size(): Int{ 
			return self.ownedNFTs.length
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
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32){ 
			pre{ 
				Bakesale_Beer_NFT.numberEditionsMintedPerSet[setId] != nil:
					"The set does not exist."
				Bakesale_Beer_NFT.numberEditionsMintedPerSet[setId]! < Bakesale_Beer_NFT.getSetMaxEditions(setId: setId)!:
					"This set has minted the maximum number of editions."
				Bakesale_Beer_NFT.getIpfsMetadataHashBySet(setId: setId) != nil:
					"The set doesn't have any metadata."
			}
			
			// Gets the number of editions that have been minted so far in 
			// this set
			let editionNum: UInt32 = Bakesale_Beer_NFT.numberEditionsMintedPerSet[setId]! + 1 as UInt32
			
			//get the metadata ipfs hash
			let metadata: String = Bakesale_Beer_NFT.getIpfsMetadataHashBySet(setId: setId)!
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Bakesale_Beer_NFT.NFT(id: Bakesale_Beer_NFT.totalSupply, metadata: metadata, setId: setId, editionNum: editionNum))
			
			// Update the total count of NFTs
			Bakesale_Beer_NFT.totalSupply = Bakesale_Beer_NFT.totalSupply + 1 as UInt64
			
			// Update the count of Editions minted in the set
			Bakesale_Beer_NFT.numberEditionsMintedPerSet[setId] = editionNum
			emit Minted(id: Bakesale_Beer_NFT.totalSupply)
		}
		
		// batchMintNFT
		// Mints multiple new NFTs given and deposits the NFTs
		// into the recipients collection using their collection reference
		access(all)
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
		access(all)
		fun addNftSet(setId: UInt32, maxEditions: UInt32, ipfsMetadataHash: String, ipfsMediaHash: String){ 
			pre{ 
				Bakesale_Beer_NFT.setIds.contains(setId) == false:
					"The set has already been added."
			}
			
			// Create the new Set struct
			var newNFTSet = NFTSetData(setId: setId, maxEditions: maxEditions, ipfsMetadataHash: ipfsMetadataHash, ipfsMediaHash: ipfsMediaHash)
			
			// Add the NFTSet to the array of Sets
			Bakesale_Beer_NFT.setIds.append(setId)
			
			// Initialize the NFT edition count to zero
			Bakesale_Beer_NFT.numberEditionsMintedPerSet[setId] = 0
			
			// Store it in the sets mapping field
			Bakesale_Beer_NFT.setData[setId] = newNFTSet
			emit SetAdded(setId: setId)
		}
		
		access(all)
		fun removeNftSet(setId: UInt32){ 
			pre{ 
				Bakesale_Beer_NFT.setIds.contains(setId):
					"Could not borrow set: set does not exist."
			}
			var indexOfSetId: Int = 0
			var i = 0
			while i < Bakesale_Beer_NFT.setIds.length{ 
				if Bakesale_Beer_NFT.setIds[i] == setId{ 
					indexOfSetId = i
					break
				}
				i = i + 1
			}
			Bakesale_Beer_NFT.setIds.remove(at: indexOfSetId)
			Bakesale_Beer_NFT.setData.remove(key: setId)
			emit SetRemoved(setId: setId)
		}
	}
	
	// fetch
	// Get a reference to a Bakesale_Beer_NFT from an account's Collection, if available.
	// If an account does not have a Bakesale_Beer_NFT.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Bakesale_Beer_NFT.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&{Bakesale_Beer_NFT.Bakesale_Beer_NFTCollectionPublic}>(Bakesale_Beer_NFT.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		
		// We trust Bakesale_Beer_NFT.Collection.borowBakesale_Beer_NFT to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowBakesale_Beer_NFT(id: itemID)
	}
	
	// listSetData returns the dictionary of set data
	access(all)
	fun listSetData():{ UInt32: NFTSetData}{ 
		return self.setData
	}
	
	// getAllSets returns all the sets
	//
	// Returns: An array of all the sets that have been created
	access(all)
	fun getAllSets(): [Bakesale_Beer_NFT.NFTSetData]{ 
		return Bakesale_Beer_NFT.setData.values
	}
	
	// getSetMaxEditions returns the the maximum number of NFT editions that can
	//		be minted in this Set.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The max number of NFT editions in this Set
	access(all)
	view fun getSetMaxEditions(setId: UInt32): UInt32?{ 
		return Bakesale_Beer_NFT.setData[setId]?.maxEditions
	}
	
	//getNumberEditionsMintedPerSet
	access(all)
	fun getNumberEditionsMintedPerSet(setId: UInt32): UInt32?{ 
		return Bakesale_Beer_NFT.numberEditionsMintedPerSet[setId]
	}
	
	// getIpfsMetadataHashBySet returns the ipfs hash for each nft set.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The ipfs hash of nft for the set
	access(all)
	view fun getIpfsMetadataHashBySet(setId: UInt32): String?{ 
		if let set = Bakesale_Beer_NFT.setData[setId]{ 
			return set.ipfsMetadataHash
		} else{ 
			return nil
		}
	}
	
	// getIpfsMediaHashBySet returns the ipfs hash for each nft set.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The ipfs hash of the media for the nft for the set
	access(all)
	fun getIpfsMediaHashBySet(setId: UInt32): String?{ 
		// Don't force a revert if the setId or field is invalid
		if let set = Bakesale_Beer_NFT.setData[setId]{ 
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
		self.CollectionStoragePath = /storage/Bakesale_Beer_NFTCollection
		self.CollectionPublicPath = /public/Bakesale_Beer_NFTCollection
		self.CollectionPrivatePath = /private/Bakesale_Beer_NFTCollection
		self.AdminStoragePath = /storage/Bakesale_Beer_NFTAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		let collection <- Bakesale_Beer_NFT.createEmptyCollection(nftType: Type<@Bakesale_Beer_NFT.Collection>())
		self.account.storage.save(<-collection, to: Bakesale_Beer_NFT.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Bakesale_Beer_NFT.Collection>(Bakesale_Beer_NFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: Bakesale_Beer_NFT.CollectionPrivatePath)
		var capability_2 = self.account.capabilities.storage.issue<&Bakesale_Beer_NFT.Collection>(Bakesale_Beer_NFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: Bakesale_Beer_NFT.CollectionPublicPath)
		
		// Create an admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
