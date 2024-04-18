import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FreshmintMetadataViews from "../0x0c82d33d4666f1f7/FreshmintMetadataViews.cdc"

access(all)
contract NBATopShotArena: NonFungibleToken{ 
	access(all)
	let version: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, editionID: UInt64, serialNumber: UInt64)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	event EditionCreated(edition: Edition)
	
	access(all)
	event EditionClosed(id: UInt64, size: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/// The total number of NBATopShotArena NFTs that have been minted.
	///
	access(all)
	var totalSupply: UInt64
	
	/// The total number of NBATopShotArena editions that have been created.
	///
	access(all)
	var totalEditions: UInt64
	
	/// A list of royalty recipients that is attached to all NFTs
	/// minted by this contract.
	///
	access(contract)
	let royalties: [MetadataViews.Royalty]
	
	/// Return the royalty recipients for this contract.
	///
	access(all)
	fun getRoyalties(): [MetadataViews.Royalty]{ 
		return NBATopShotArena.royalties
	}
	
	/// The collection-level metadata for all NFTs minted by this contract.
	///
	access(all)
	let collectionMetadata: MetadataViews.NFTCollectionDisplay
	
	access(all)
	struct Metadata{ 
		
		/// The core metadata fields for a NBATopShotArena NFT edition.
		///
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let asset: String
		
		access(all)
		let assetType: String
		
		access(all)
		let eventName: String
		
		access(all)
		let eventDate: String
		
		access(all)
		let externalURL: String
		
		/// Optional attributes for a NBATopShotArena NFT edition.
		///
		access(all)
		let attributes:{ String: String}
		
		init(name: String, description: String, thumbnail: String, asset: String, assetType: String, eventName: String, eventDate: String, externalURL: String, attributes:{ String: String}){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.asset = asset
			self.assetType = assetType
			self.eventName = eventName
			self.eventDate = eventDate
			self.externalURL = externalURL
			self.attributes = attributes
		}
	}
	
	access(all)
	struct Edition{ 
		access(all)
		let id: UInt64
		
		/// The maximum number of NFTs that can be minted in this edition.
		///
		/// If nil, the edition has no size limit.
		///
		access(all)
		let limit: UInt64?
		
		/// The number of NFTs minted in this edition.
		///
		/// This field is incremented each time a new NFT is minted.
		/// It cannot exceed the limit defined above.
		///
		access(all)
		var size: UInt64
		
		/// The number of NFTs in this edition that have been burned.
		///
		/// This field is incremented each time an NFT is burned.
		///
		access(all)
		var burned: UInt64
		
		/// Return the total supply of NFTs in this edition.
		///
		/// The supply is the number of NFTs minted minus the number burned.
		///
		access(all)
		fun supply(): UInt64{ 
			return self.size - self.burned
		}
		
		/// A flag indicating whether this edition is closed for minting.
		///
		access(all)
		var isClosed: Bool
		
		/// The metadata for this edition.
		///
		access(all)
		let metadata: Metadata
		
		init(id: UInt64, limit: UInt64?, metadata: Metadata){ 
			self.id = id
			self.limit = limit
			self.metadata = metadata
			self.size = 0
			self.burned = 0
			self.isClosed = false
		}
		
		/// Increment the size of this edition.
		///
		access(contract)
		fun incrementSize(){ 
			self.size = self.size + 1 as UInt64
		}
		
		/// Increment the burn count for this edition.
		///
		access(contract)
		fun incrementBurned(){ 
			self.burned = self.burned + 1 as UInt64
		}
		
		/// Close this edition and prevent further minting.
		///
		/// Note: an edition is automatically closed when 
		/// it reaches its size limit, if defined.
		///
		access(contract)
		fun close(){ 
			self.isClosed = true
		}
	}
	
	access(self)
	let editions:{ UInt64: Edition}
	
	access(all)
	fun getEdition(id: UInt64): Edition?{ 
		return NBATopShotArena.editions[id]
	}
	
	/// This dictionary indexes editions by their mint ID.
	///
	/// It is populated at mint time and used to prevent duplicate mints.
	/// The mint ID can be any unique string value,
	/// for example the hash of the edition metadata.
	///
	access(self)
	let editionsByMintID:{ String: UInt64}
	
	access(all)
	fun getEditionByMintID(mintID: String): UInt64?{ 
		return NBATopShotArena.editionsByMintID[mintID]
	}
	
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let editionID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		init(editionID: UInt64, serialNumber: UInt64){ 
			self.id = self.uuid
			self.editionID = editionID
			self.serialNumber = serialNumber
		}
		
		/// Return the edition that this NFT belongs to.
		///
		access(all)
		fun getEdition(): Edition{ 
			return NBATopShotArena.getEdition(id: self.editionID)!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTView>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Edition>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let edition = self.getEdition()
			switch view{ 
				case Type<MetadataViews.Display>():
					return self.resolveDisplay(edition.metadata)
				case Type<MetadataViews.ExternalURL>():
					return self.resolveExternalURL()
				case Type<MetadataViews.NFTView>():
					return self.resolveNFTView(edition.metadata)
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.resolveNFTCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return self.resolveNFTCollectionData()
				case Type<MetadataViews.Royalties>():
					return self.resolveRoyalties()
				case Type<MetadataViews.Edition>():
					return self.resolveEditionView(edition)
				case Type<MetadataViews.Serial>():
					return self.resolveSerialView(self.serialNumber)
			}
			return nil
		}
		
		access(all)
		fun resolveDisplay(_ metadata: Metadata): MetadataViews.Display{ 
			return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: FreshmintMetadataViews.ipfsFile(file: metadata.thumbnail))
		}
		
		access(all)
		fun resolveExternalURL(): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL("https://nbatopshot.com")
		}
		
		access(all)
		fun resolveNFTView(_ metadata: Metadata): MetadataViews.NFTView{ 
			return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.resolveDisplay(metadata), externalURL: self.resolveExternalURL(), collectionData: self.resolveNFTCollectionData(), collectionDisplay: self.resolveNFTCollectionDisplay(), royalties: self.resolveRoyalties(), traits: nil)
		}
		
		access(all)
		fun resolveNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			return NBATopShotArena.collectionMetadata
		}
		
		access(all)
		fun resolveNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: NBATopShotArena.CollectionStoragePath, publicPath: NBATopShotArena.CollectionPublicPath, publicCollection: Type<&NBATopShotArena.Collection>(), publicLinkedType: Type<&NBATopShotArena.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-NBATopShotArena.createEmptyCollection(nftType: Type<@NBATopShotArena.Collection>())
				})
		}
		
		access(all)
		fun resolveRoyalties(): MetadataViews.Royalties{ 
			return MetadataViews.Royalties(NBATopShotArena.getRoyalties())
		}
		
		access(all)
		fun resolveEditionView(_ edition: Edition): MetadataViews.Edition{ 
			return MetadataViews.Edition(name: "Edition", number: self.serialNumber, max: edition.size)
		}
		
		access(all)
		fun resolveSerialView(_ serialNumber: UInt64): MetadataViews.Serial{ 
			return MetadataViews.Serial(serialNumber)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface NBATopShotArenaCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNBATopShotArena(id: UInt64): &NBATopShotArena.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NBATopShotArena reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NBATopShotArenaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		/// A dictionary of all NFTs in this collection indexed by ID.
		///
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Remove an NFT from the collection and move it to the caller.
		///
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Requested NFT to withdraw does not exist in this collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Deposit an NFT into this collection.
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NBATopShotArena.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Return an array of the NFT IDs in this collection.
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Return a reference to an NFT in this collection.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as NBATopShotArena.NFT.
		///
		/// This function returns nil if the NFT does not exist in this collection.
		///
		access(all)
		fun borrowNBATopShotArena(id: UInt64): &NBATopShotArena.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NBATopShotArena.NFT
			}
			return nil
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as MetadataViews.Resolver.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = nft as! &NBATopShotArena.NFT
			return nftRef as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Return a new empty collection.
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// The administrator resource used to mint and reveal NFTs.
	///
	access(all)
	resource Admin{ 
		
		/// Create a new NFT edition.
		///
		/// This function does not mint any NFTs. It only creates the
		/// edition data that will later be associated with minted NFTs.
		///
		access(all)
		fun createEdition(mintID: String, limit: UInt64?, name: String, description: String, thumbnail: String, asset: String, assetType: String, eventName: String, eventDate: String, externalURL: String, attributes:{ String: String}): UInt64{ 
			let metadata = Metadata(name: name, description: description, thumbnail: thumbnail, asset: asset, assetType: assetType, eventName: eventName, eventDate: eventDate, externalURL: externalURL, attributes: attributes)
			
			// Prevent multiple editions from being minted with the same mint ID
			assert(NBATopShotArena.editionsByMintID[mintID] == nil, message: "an edition has already been created with mintID=".concat(mintID))
			let edition = Edition(id: NBATopShotArena.totalEditions, limit: limit, metadata: metadata)
			
			// Save the edition
			NBATopShotArena.editions[edition.id] = edition
			
			// Update the mint ID index
			NBATopShotArena.editionsByMintID[mintID] = edition.id
			emit EditionCreated(edition: edition)
			NBATopShotArena.totalEditions = NBATopShotArena.totalEditions + 1 as UInt64
			return edition.id
		}
		
		/// Close an existing edition.
		///
		/// This prevents new NFTs from being minted into the edition.
		/// An edition cannot be reopened after it is closed.
		///
		access(all)
		fun closeEdition(editionID: UInt64){ 
			let edition = NBATopShotArena.editions[editionID] ?? panic("edition does not exist")
			
			// Prevent the edition from being closed more than once
			assert(edition.isClosed == false, message: "edition is already closed")
			edition.close()
			
			// Save the updated edition
			NBATopShotArena.editions[editionID] = edition
			emit EditionClosed(id: edition.id, size: edition.size)
		}
		
		/// Mint a new NFT.
		///
		/// This function will mint the next NFT in this edition
		/// and automatically assign the serial number.
		///
		/// This function will panic if the edition has already
		/// reached its maximum size.
		///
		access(all)
		fun mintNFT(editionID: UInt64): @NBATopShotArena.NFT{ 
			let edition = NBATopShotArena.editions[editionID] ?? panic("edition does not exist")
			
			// Do not mint into a closed edition
			assert(edition.isClosed == false, message: "edition is closed for minting")
			
			// Increase the edition size by one
			edition.incrementSize()
			
			// The NFT serial number is the new edition size
			let serialNumber = edition.size
			let nft <- create NBATopShotArena.NFT(editionID: editionID, serialNumber: serialNumber)
			emit Minted(id: nft.id, editionID: editionID, serialNumber: serialNumber)
			
			// Close the edition if it reaches its size limit
			if let limit = edition.limit{ 
				if edition.size == limit{ 
					edition.close()
					emit EditionClosed(id: edition.id, size: edition.size)
				}
			}
			
			// Save the updated edition
			NBATopShotArena.editions[editionID] = edition
			NBATopShotArena.totalSupply = NBATopShotArena.totalSupply + 1 as UInt64
			return <-nft
		}
	}
	
	/// Return a public path that is scoped to this contract.
	///
	access(all)
	fun getPublicPath(suffix: String): PublicPath{ 
		return PublicPath(identifier: "NBATopShotArena_".concat(suffix))!
	}
	
	/// Return a private path that is scoped to this contract.
	///
	access(all)
	fun getPrivatePath(suffix: String): PrivatePath{ 
		return PrivatePath(identifier: "NBATopShotArena_".concat(suffix))!
	}
	
	/// Return a storage path that is scoped to this contract.
	///
	access(all)
	fun getStoragePath(suffix: String): StoragePath{ 
		return StoragePath(identifier: "NBATopShotArena_".concat(suffix))!
	}
	
	/// Return a collection name with an optional bucket suffix.
	///
	access(all)
	fun makeCollectionName(bucketName maybeBucketName: String?): String{ 
		if let bucketName = maybeBucketName{ 
			return "Collection_".concat(bucketName)
		}
		return "Collection"
	}
	
	/// Return a queue name with an optional bucket suffix.
	///
	access(all)
	fun makeQueueName(bucketName maybeBucketName: String?): String{ 
		if let bucketName = maybeBucketName{ 
			return "Queue_".concat(bucketName)
		}
		return "Queue"
	}
	
	access(self)
	fun initAdmin(admin: AuthAccount){ 
		// Create an empty collection and save it to storage
		let collection <- NBATopShotArena.createEmptyCollection(nftType: Type<@NBATopShotArena.Collection>())
		admin.save(<-collection, to: NBATopShotArena.CollectionStoragePath)
		admin.link<&NBATopShotArena.Collection>(NBATopShotArena.CollectionPrivatePath, target: NBATopShotArena.CollectionStoragePath)
		admin.link<&NBATopShotArena.Collection>(NBATopShotArena.CollectionPublicPath, target: NBATopShotArena.CollectionStoragePath)
		
		// Create an admin resource and save it to storage
		let adminResource <- create Admin()
		admin.save(<-adminResource, to: self.AdminStoragePath)
	}
	
	init(collectionMetadata: MetadataViews.NFTCollectionDisplay, royalties: [MetadataViews.Royalty]){ 
		self.version = "0.7.0"
		self.CollectionPublicPath = NBATopShotArena.getPublicPath(suffix: "Collection")
		self.CollectionStoragePath = NBATopShotArena.getStoragePath(suffix: "Collection")
		self.CollectionPrivatePath = NBATopShotArena.getPrivatePath(suffix: "Collection")
		self.AdminStoragePath = NBATopShotArena.getStoragePath(suffix: "Admin")
		self.royalties = royalties
		self.collectionMetadata = collectionMetadata
		self.totalSupply = 0
		self.totalEditions = 0
		self.editions ={} 
		self.editionsByMintID ={} 
		self.initAdmin(admin: self.account)
		emit ContractInitialized()
	}
}
