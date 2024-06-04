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
	Description: Central Smart Contract for ethosHhofGreatnessCalling
	
	This smart contract contains the core functionality for 
	ethosHhofGreatnessCalling, created by ethos Multiverse Inc.
	
	The contract manages the data associated with each NFT and 
	the distribution of each NFT to recipients.
	
	Admins throught their admin resource object have the power 
	to do all of the important actions in the smart contract such 
	as minting and batch minting.
	
	When NFTs are minted, they are initialized with a metadata object and then
	stored in the admins Collection.
	
	The contract also defines a Collection resource. This is an object that 
	every ethosHhofGreatnessCalling NFT owner will store in their account
	to manage their NFT collection.
	
	The main ethosHhofGreatnessCalling account operated by ethos Multiverse Inc. 
	will also have its own ethosHhofGreatnessCalling collection it can use to hold its 
	own NFT's that have not yet been sent to users.
	
	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
	Functions that don't modify state will simply return 0 or nil 
	and those cases need to be handled by the caller.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract ethosHhofGreatnessCalling: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// ethosHhofGreatnessCalling contract Events
	// -----------------------------------------------------------------------
	
	// Emited when the ethosHhofGreatnessCalling contract is created
	access(all)
	event ContractInitialized()
	
	// Emmited when a user transfers a ethosHhofGreatnessCalling NFT out of their collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emmited when a user recieves a ethosHhofGreatnessCalling NFT into their collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emmited when a ethosHhofGreatnessCalling NFT is minted
	access(all)
	event Minted(id: UInt64)
	
	// Emmited when a batch of ethosHhofGreatnessCalling NFTs are minted
	access(all)
	event BatchMint(metadatas: [{String: String}])
	
	// -----------------------------------------------------------------------
	// ethosHhofGreatnessCalling Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// ethosHhofGreatnessCalling contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Collection Information
	access(self)
	let collectionInfo:{ String: AnyStruct}
	
	// Array of all existing ethosHhofGreatnessCalling NFTs
	access(self)
	var metadatas: [{String: String}]
	
	// The total number of ethosHhofGreatnessCalling NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as NFT IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// ethosHhofGreatnessCalling contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// The resource that represents the ethosHhofGreatnessCalling NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		init(_metadata:{ String: String}){ 
			self.id = ethosHhofGreatnessCalling.totalSupply
			self.metadata = _metadata
			
			// Total Supply
			ethosHhofGreatnessCalling.totalSupply = ethosHhofGreatnessCalling.totalSupply + 1
			
			// Add the metadata to the metadatas array
			ethosHhofGreatnessCalling.metadatas.append(_metadata)
			
			// Emit Minted Event
			emit Minted(id: self.id)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"]!, description: self.metadata["description"]!, thumbnail: MetadataViews.HTTPFile(url: self.metadata["external_url"]!))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://jade.ethosnft.com/collections/".concat((self.owner!).address.toString()).concat("/ethosHhofGreatnessCalling"))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ethosHhofGreatnessCalling.CollectionStoragePath, publicPath: ethosHhofGreatnessCalling.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ethosHhofGreatnessCalling.createEmptyCollection(nftType: Type<@ethosHhofGreatnessCalling.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia: MetadataViews.Media = MetadataViews.Media(file: ethosHhofGreatnessCalling.getCollectionAttribute(key: "image") as! MetadataViews.HTTPFile, mediaType: "image")
					
					// Check if banner image exists
					var bannerMedia: MetadataViews.Media? = nil
					if let bannerImage: MetadataViews.IPFSFile = ethosHhofGreatnessCalling.getCollectionAttribute(key: "bannerImage") as! MetadataViews.IPFSFile?{ 
						bannerMedia = MetadataViews.Media(file: bannerImage, mediaType: "image")
					}
					return MetadataViews.NFTCollectionDisplay(name: ethosHhofGreatnessCalling.getCollectionAttribute(key: "name") as! String, description: ethosHhofGreatnessCalling.getCollectionAttribute(key: "description") as! String, externalURL: MetadataViews.ExternalURL("https://jade.ethosnft.com/collections/".concat((self.owner!).address.toString()).concat("/ethosHhofGreatnessCalling")), squareImage: squareMedia, bannerImage: bannerMedia ?? squareMedia, socials: ethosHhofGreatnessCalling.getCollectionAttribute(key: "socials") as!{ String: MetadataViews.ExternalURL})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([													// For ethos Multiverse Inc. in favor of producing Jade, a tool for deploying NFT contracts and minting/managing collections.
													MetadataViews.Royalty(receiver: getAccount(0xeaf1bb3f70a73336).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.025, // 2.5% on secondary sales																																															  
																																															  description: "ethos Multiverse Inc. receives a 2.5% royalty from secondary sales because this collection was created using Jade (https://jade.ethosnft.com), a tool for deploying NFT contracts and minting/managing collections, created by ethos Multiverse Inc.")])
				case Type<MetadataViews.NFTView>():
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?, externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?, collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?, collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?, royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?, traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// The interface that users can cast their ethosHhofGreatnessCalling Collection as
	// to allow others to deposit ethosHhofGreatnessCalling into thier Collection. It also
	// allows for the reading of the details of ethosHhofGreatnessCalling
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEntireNFT(id: UInt64): &ethosHhofGreatnessCalling.NFT?
	}
	
	// Collection is a resource that every user who owns NFTs
	// will store in their account to manage their NFTs
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Token not found")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let myToken <- token as! @ethosHhofGreatnessCalling.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a ethosHhofGreatnessCalling NFT in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowEntireNFT returns a borrowed reference to a ethosHhofGreatnessCalling 
		// NFT so that the caller can read its data.
		// They can use this to read its id, description, and edition.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEntireNFT(id: UInt64): &ethosHhofGreatnessCalling.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let reference = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return reference as! &ethosHhofGreatnessCalling.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let token = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = token as! &NFT
			return nft as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important NFT
	// functions
	access(all)
	resource Admin{ 
		// mint
		// Mints an new NFT
		// and deposits it in the Admins collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			// create a new NFT 
			var newNFT <- create NFT(_metadata: metadata)
			
			// Deposit it in Admins account using their reference
			recipient.deposit(token: <-newNFT)
		}
		
		// batchMint
		// Batch mints ethosHhofGreatnessCalling NFTs
		// and deposits in the Admins collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMint(recipient: &{NonFungibleToken.CollectionPublic}, metadataArray: [{String: String}]){ 
			var i: Int = 0
			while i < metadataArray.length{ 
				self.mint(recipient: recipient, metadata: metadataArray[i])
				i = i + 1
			}
			emit BatchMint(metadatas: metadataArray)
		}
		
		// updateCollectionInfo
		// change piece of collection info
		access(TMP_ENTITLEMENT_OWNER)
		fun updateCollectionInfo(key: String, value: AnyStruct){ 
			ethosHhofGreatnessCalling.collectionInfo[key] = value
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// The interface that Admins can use to give adminRights to other users
	access(all)
	resource interface AdminProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun giveAdminRights(cap: Capability<&ethosHhofGreatnessCalling.Admin>): Void
	}
	
	// AdminProxy is a special procxy resource that
	// allows the owner to give adminRights to other users
	// to perform important NFT functions
	access(all)
	resource AdminProxy: AdminProxyPublic{ 
		access(self)
		var cap: Capability<&Admin>
		
		init(){ 
			self.cap = nil!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun giveAdminRights(cap: Capability<&Admin>){ 
			pre{ 
				self.cap == nil:
					"Capability is already set."
			}
			self.cap = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun checkAdminRights(): Bool{ 
			return self.cap.check()
		}
		
		access(self)
		fun borrow(): &Admin{ 
			pre{ 
				self.cap != nil:
					"Capability is not set."
				self.checkAdminRights():
					"Admin unliked capability."
			}
			return self.cap.borrow()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			let admin = self.borrow()
			admin.mint(recipient: recipient, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMint(recipient: &{NonFungibleToken.CollectionPublic}, metadataArray: [{String: String}]){ 
			let admin = self.borrow()
			admin.batchMint(recipient: recipient, metadataArray: metadataArray)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateCollectionInfo(key: String, value: AnyStruct){ 
			let admin = self.borrow()
			admin.updateCollectionInfo(key: key, value: value)
		}
	}
	
	// -----------------------------------------------------------------------
	// ethosHhofGreatnessCalling contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// getNFTMetadata
	// public function that anyone can call to get information about a NFT
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTMetadata(_ metadataId: UInt64):{ String: String}{ 
		return self.metadatas[metadataId]
	}
	
	// getNFTMetadatas
	// public function that anyone can call to get all NFT metadata
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTMetadatas(): [{String: String}]{ 
		return self.metadatas
	}
	
	// getCollectionInfo
	// public function that anyone can call to get information about the collection
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionInfo():{ String: AnyStruct}{ 
		let collectionInfo = self.collectionInfo
		collectionInfo["metadatas"] = self.metadatas
		collectionInfo["totalSupply"] = self.totalSupply
		collectionInfo["version"] = 1
		return collectionInfo
	}
	
	// getCollectionAttribute
	// public function that anyone can call to get a specific piece of collection info
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionAttribute(key: String): AnyStruct{ 
		return self.collectionInfo[key] ?? panic(key.concat(" is not an attribute in this collection."))
	}
	
	// getOptionalCollectionAttribute
	// public function that anyone can call to get an optional piece of collection info
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getOptionalCollectionAttribute(key: String): AnyStruct?{ 
		return self.collectionInfo[key]
	}
	
	// canMint
	// public function that anyone can call to check if the contract can mint more NFTs
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun canMint(): Bool{ 
		return self.getCollectionAttribute(key: "minting") as! Bool
	}
	
	// -----------------------------------------------------------------------
	// ethosHhofGreatnessCalling initialization function
	// -----------------------------------------------------------------------
	// initializer
	//
	init(){ 
		// Set contract level fields
		self.collectionInfo ={} 
		self.collectionInfo["name"] = "ethosHhofGreatnessCalling"
		self.collectionInfo["description"] = "Collection of ethos HHOF Greatness Calling NFTs"
		self.collectionInfo["image"] = MetadataViews.IPFSFile(cid: "", path: "")
		self.collectionInfo["ipfsCID"] = ""
		self.collectionInfo["minting"] = true
		self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
		self.totalSupply = 1
		self.metadatas = []
		
		// Set named paths
		self.CollectionStoragePath = /storage/ethosHhofGreatnessCallingCollection
		self.CollectionPublicPath = /public/ethosHhofGreatnessCallingCollection
		self.CollectionPrivatePath = /private/ethosHhofGreatnessCallingCollection
		self.AdminStoragePath = /storage/ethosHhofGreatnessCallingAdmin
		self.AdminPrivatePath = /private/ethosHhofGreatnessCallingAdminUpgrade
		
		// Create admin resource and save it to storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&ethosHhofGreatnessCalling.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a private capability for the admin resource
		var capability_2 = self.account.capabilities.storage.issue<&ethosHhofGreatnessCalling.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_2, at: self.AdminPrivatePath) ?? panic("Could not get Admin capability")
		emit ContractInitialized()
	}
}
