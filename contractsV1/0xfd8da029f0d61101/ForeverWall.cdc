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
	
	This smart contract contains the core functionality for Mint PFP NFT. 
	
	MINT is a platform where teams can create a fully branded environment to sell NFTs and launch branded marketplaces. 
	This will give fans a fully immersive experience as they interact with drops, buy and sell in the marketplace, and 
	deepen their relationships with the brand.

	[INSERT DESCRIPTION]

	Enjoy!
*/


// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
// import MetadataViews from "../"./MetadataViews.cdc"/MetadataViews.cdc"

// for tests
// import NonFungibleToken from "../"0xNonFungibleToken"/NonFungibleToken.cdc"
// import MetadataViews from "../"0xMetadataViews"/MetadataViews.cdc"
// import FungibleToken from "../"0xFungibleToken"/FungibleToken.cdc"
// import MathUtils from "../"0xMathUtils"/MathUtils.cdc"

// for testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"

// for mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MathUtils from "./MathUtils.cdc"

access(all)
contract ForeverWall: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// MintPFPs contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the MintPFPs contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new item was minted
	access(all)
	event ItemMinted(itemID: UInt64, merchantID: UInt32, name: String)
	
	// Item related events 
	//
	// Emitted when an Item is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an Item is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when an Item is withdrawn from a Collection
	access(all)
	event ItemMutated(id: UInt64, mutation: ItemData)
	
	// Emitted when adding a default royalty recipient
	access(all)
	event DefaultRoyaltyAdded(name: String, rate: UFix64)
	
	// Emitted when removing a default royalty recipient
	access(all)
	event DefaultRoyaltyRemoved(name: String)
	
	// Emitted when an existing Royalty rate is changed
	access(all)
	event DefaultRoyaltyRateChanged(name: String, previousRate: UFix64, rate: UFix64)
	
	// Emitted when adding a royalty for a specific NFT
	access(all)
	event RoyaltyForPFPAdded(tokenID: UInt64, name: String, rate: UFix64)
	
	// Emitted when an existing Royalty rate is changed
	access(all)
	event RoyaltyForPFPChanged(tokenID: UInt64, name: String, previousRate: UFix64, rate: UFix64)
	
	// Emitted when an existing Royalty rate is changed
	access(all)
	event RoyaltyForPFPRemoved(tokenID: UInt64, name: String)
	
	// Emitted when reverting the Royalty rate of a given NFT back to default settings
	access(all)
	event RoyaltyForPFPRevertedToDefault(tokenID: UInt64)
	
	// Emitted when an Item is destroyed
	access(all)
	event ItemDestroyed(id: UInt64)
	
	// graffiti specific events
	access(all)
	event UpdatedPageSize(tokenID: UInt64, pageSize: PageSize)
	
	access(all)
	event UpdatedMaxGraffitiSize(tokenID: UInt64, maxGraffitiSize: UInt32)
	
	access(all)
	event UpdateIsEntriesBlocked(tokenID: UInt64, isEntriesBlocked: Bool)
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MutatorStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// MintPFPs contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The ID that is used to create Admins. 
	// Every Admins should have a unique identifier.
	access(all)
	var nextAdminID: UInt32
	
	// The ID that is used to create Mutators. 
	// Every Mutators should have a unique identifier.
	access(all)
	var nextMutatorID: UInt32
	
	// If ever a mutator goes rouge, we would like to be able to have the option of
	// locking the mutator's ability to mutate NFTs. Additionally, we would like
	// to be able to unlock them too.
	access(all)
	var lockedMutators:{ UInt32: Bool}
	
	// The merchant ID (see MintPFPs)
	access(all)
	var merchantID: UInt32
	
	// The total number of MintPFPs NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as global nft IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// Mutations are upgrades or modifications of the NFTs' metadata.
	// These will be store at the contract level, allowing dapps administrators to 
	// mutate NFTs even after they have been transferred to other wallets.
	// It also ensures that the original metadata of the NFT will never be deleted
	// offering some protection to the holder.
	access(all)
	var mutations:{ UInt64: ItemData}
	
	// the default royalties will be applied to all PFPs unless a specific royalty 
	// is set for a given PFP
	access(all)
	var defaultRoyalties:{ String: MetadataViews.Royalty}
	
	// If a specific NFT requires their own royalties, 
	// the default royalties can be overwritten in this dictionary.
	access(all)
	var royaltiesForSpecificPFP:{ UInt64:{ String: MetadataViews.Royalty}}
	
	access(all)
	var ExternalURL: MetadataViews.ExternalURL
	
	access(all)
	var Socials:{ String: MetadataViews.ExternalURL}
	
	access(all)
	var Description: String
	
	access(all)
	var SquareImage: MetadataViews.Media
	
	access(all)
	var BannerImage: MetadataViews.Media
	
	// -----------------------------------------------------------------------
	// MintPFPs contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// The struct representing an NFT Item data
	access(all)
	struct ItemData{ 
		
		// The ID of the merchant 
		access(all)
		let merchantID: UInt32
		
		// the name
		access(all)
		let name: String
		
		// the description
		access(all)
		let description: String
		
		// The thumbnail
		access(all)
		let thumbnail: String
		
		// the thumbnail cid (if thumbnailHosting is IPFS )
		access(all)
		let thumbnailCID: String
		
		// the thumbnail path (if thumbnailHosting is IPFS )
		access(all)
		let thumbnailPathIPFS: String?
		
		// The mimetype of the thumbnail
		access(all)
		let thumbnailMimeType: String
		
		// The method of hosting the thumbnail (IPFS | HTTPFile)
		access(all)
		let thumbnailHosting: String
		
		// the media file
		access(all)
		let mediaURL: String
		
		// the media cid (if mediaHosting is IPFS )
		access(all)
		let mediaCID: String
		
		// the media path (if mediaHosting is IPFS )
		access(all)
		let mediaPathIPFS: String?
		
		// the mimetype
		access(all)
		let mimetype: String
		
		// the method of hosting the media file (IPFS | HTTPFile)
		access(all)
		let mediaHosting: String
		
		// the attributes
		access(all)
		let attributes:{ String: String}
		
		// rarity
		access(all)
		let rarity: String
		
		init(name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			self.merchantID = ForeverWall.merchantID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.thumbnailMimeType = thumbnailMimeType
			self.thumbnailCID = thumbnailCID
			self.thumbnailPathIPFS = thumbnailPathIPFS
			self.thumbnailHosting = thumbnailHosting
			self.mediaURL = mediaURL
			self.mediaCID = mediaCID
			self.mediaPathIPFS = mediaPathIPFS
			self.mediaHosting = mediaHosting
			self.mimetype = mimetype
			self.attributes = attributes
			self.rarity = rarity
		}
	}
	
	access(all)
	struct Coordinates{ 
		access(all)
		let x: Int32
		
		access(all)
		let y: Int32
		
		access(all)
		let z: Int32
		
		init(x: Int32, y: Int32, z: Int32){ 
			self.x = x
			self.y = y
			self.z = z
		}
	}
	
	access(all)
	struct PageSize{ 
		access(all)
		let xmin: Int32
		
		access(all)
		let xmax: Int32
		
		access(all)
		let ymin: Int32
		
		access(all)
		let ymax: Int32
		
		init(xmin: Int32, xmax: Int32, ymin: Int32, ymax: Int32){ 
			self.xmin = xmin
			self.xmax = xmax
			self.ymin = ymin
			self.ymax = ymax
		}
	}
	
	//  pub struct MaxGraffitiSize{
	//	pub let maxChar: Int
	// 
	//   init(maxChar: Int){
	//	   self.maxChar = maxChar
	//	}
	//   }
	// The resource that represents the Item NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// Global unique item ID
		access(all)
		let id: UInt64
		
		// Struct of MintPFPs metadata
		access(all)
		let data: ItemData
		
		// using Ulam coordinates (maps an infinites 2D space in one dimension)
		access(all)
		var graffitiTiles:{ UInt64: String}
		
		access(all)
		var pageSize: PageSize
		
		access(all)
		var maxGraffitiSize: UInt32
		
		access(all)
		var isEntriesBlocked: Bool
		
		init(name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			ForeverWall					   // Increment the global Item IDs
					   .totalSupply = ForeverWall.totalSupply + 1 as UInt64
			self.id = ForeverWall.totalSupply
			self.graffitiTiles ={} 
			self.pageSize = PageSize(xmin: -10, xmax: 10, ymin: -10, ymax: 10)
			self.maxGraffitiSize = 100
			self.isEntriesBlocked = false
			
			// Set the metadata struct
			self.data = ItemData(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
			emit ItemMinted(itemID: self.id, merchantID: ForeverWall.merchantID, name: name)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun writeGraffitiOnBoard(position: Coordinates, graffiti: String){ 
			// assume we can withdraw the farmTile from toolboxOutputFarmTileCollection in another function
			// convert position.x - position.y to Cantor Number
			// deposit the farmTile nft in farmTiles dictionary at farmTiles[cantor]
			pre{ 
				position.x >= self.pageSize.xmin && position.x <= self.pageSize.xmax && position.y >= self.pageSize.ymin && position.y <= self.pageSize.ymax:
					"The tile is out of bounds"
				UInt32(graffiti.length) <= self.maxGraffitiSize:
					"The string is too long"
				self.isEntriesBlocked == false:
					"Cannot graffiti on the wall"
			}
			let cantor = ForeverWall.convertCoordinatesToCantorNumber(coords: position)
			self.graffitiTiles[cantor] = graffiti
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTileCoordinates(): [Coordinates]{ 
			let coordinates: [Coordinates] = []
			for coor in self.graffitiTiles.keys{ 
				coordinates.append(ForeverWall.convertCantorNumberToCoordinates(num: coor))
			}
			return coordinates
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTilesIDs(): [UInt64]{ 
			return self.graffitiTiles.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun readTile(cantor: UInt64): String?{ 
			return self.graffitiTiles[cantor]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun readTile_xy(x: Int32, y: Int32): String?{ 
			let coor = Coordinates(x: x, y: y, z: 0)
			let cantor = ForeverWall.convertCoordinatesToCantorNumber(coords: coor)
			return self.graffitiTiles[cantor]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPageSize(): PageSize{ 
			return self.pageSize
		}
		
		access(contract)
		fun setPageSize(pageSize: PageSize){ 
			self.pageSize = pageSize
			emit UpdatedPageSize(tokenID: self.id, pageSize: self.pageSize)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMaxGraffitiSize(): UInt32{ 
			return self.maxGraffitiSize
		}
		
		access(contract)
		fun setMaxGraffitiSize(maxGraffitiSize: UInt32){ 
			self.maxGraffitiSize = maxGraffitiSize
			emit UpdatedMaxGraffitiSize(tokenID: self.id, maxGraffitiSize: self.maxGraffitiSize)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getisEntriesBlocked(): Bool{ 
			return self.isEntriesBlocked
		}
		
		access(contract)
		fun setisEntriesBlocked(isEntriesBlocked: Bool){ 
			self.isEntriesBlocked = isEntriesBlocked
			emit UpdateIsEntriesBlocked(tokenID: self.id, isEntriesBlocked: self.isEntriesBlocked)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSerialNumber(): UInt64{ 
			return self.id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOriginalData(): ItemData{ 
			return self.data
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMutation(): ItemData?{ 
			return ForeverWall.mutations[self.id]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getData(): ItemData{ 
			return self.getMutation() ?? self.getOriginalData()
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let data = self.getData()
					var thumbnail:{ MetadataViews.File} = MetadataViews.HTTPFile(url: data.thumbnail)
					if data.thumbnailHosting == "IPFS"{ 
						thumbnail = MetadataViews.IPFSFile(cid: data.thumbnailCID, path: data.thumbnailPathIPFS)
					}
					return MetadataViews.Display(name: data.name, description: data.description, thumbnail: thumbnail)
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.data.name, number: UInt64(1), max: 1)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Royalties>():
					let royaltiesDictionary = ForeverWall.royaltiesForSpecificPFP[self.id] ?? ForeverWall.defaultRoyalties
					var royalties: [MetadataViews.Royalty] = []
					for royaltyName in royaltiesDictionary.keys{ 
						royalties.append(royaltiesDictionary[royaltyName]!)
					}
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					return ForeverWall.ExternalURL
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ForeverWall.CollectionStoragePath, publicPath: ForeverWall.CollectionPublicPath, publicCollection: Type<&ForeverWall.Collection>(), publicLinkedType: Type<&ForeverWall.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ForeverWall.createEmptyCollection(nftType: Type<@ForeverWall.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let data = self.getData()
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: data.thumbnail), mediaType: data.thumbnailMimeType)
					return MetadataViews.NFTCollectionDisplay(name: "ForeverWall", description: ForeverWall.Description, externalURL: ForeverWall.ExternalURL, squareImage: ForeverWall.SquareImage, bannerImage: ForeverWall.BannerImage, socials: ForeverWall.Socials)
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					let excludedTraits = ["name", "description", "thumbnail", "externalUrl"]
					let data = self.getData()
					let dict = data.attributes
					let traitsView = MetadataViews.dictToTraits(dict: dict, excludedNames: excludedTraits)
					return traitsView
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
	
	// Mutator is an authorization resource that allows for the mutations of NFTs 
	access(all)
	resource Mutator{ 
		access(all)
		let id: UInt32
		
		init(id: UInt32){ 
			self.id = id
		}
		
		// Mutator role should only be able to mutate a NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun mutatePFP(tokenID: UInt64, name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			pre{ 
				tokenID <= ForeverWall.totalSupply:
					"the tokenID does not exist"
			}
			if ForeverWall.lockedMutators[self.id] != true{ 
				let mutation = ItemData(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
				ForeverWall.mutations[tokenID] = mutation
				emit ItemMutated(id: tokenID, mutation: mutation)
			} else{ 
				log("Cannot let mutator mutate")
			}
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the Editions and Items
	//
	access(all)
	resource Admin{ 
		access(all)
		let id: UInt32
		
		init(id: UInt32){ 
			self.id = id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setExternalURL(url: String){ 
			ForeverWall.ExternalURL = MetadataViews.ExternalURL(url)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSocial(key: String, url: String):{ String: MetadataViews.ExternalURL}{ 
			ForeverWall.Socials.insert(key: key, MetadataViews.ExternalURL(url))
			return ForeverWall.getSocials()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSocial(key: String):{ String: MetadataViews.ExternalURL}{ 
			ForeverWall.Socials.remove(key: key)
			return ForeverWall.getSocials()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(description: String){ 
			ForeverWall.Description = description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSquareImage(url: String, mediaType: String){ 
			ForeverWall.SquareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: url), mediaType: mediaType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setBannerImage(url: String, mediaType: String){ 
			ForeverWall.BannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: url), mediaType: mediaType)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			let newID = ForeverWall.nextAdminID
			// Increment the ID so that it isn't used again
			ForeverWall.nextAdminID = ForeverWall.nextAdminID + 1 as UInt32
			return <-create Admin(id: newID)
		}
		
		// createNewMutator creates a new Mutator resource
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewMutator(): @Mutator{ 
			let newID = ForeverWall.nextMutatorID
			// Increment the ID so that it isn't used again
			ForeverWall.nextMutatorID = ForeverWall.nextMutatorID + 1 as UInt32
			return <-create Mutator(id: newID)
		}
		
		// Locks a mutator
		access(TMP_ENTITLEMENT_OWNER)
		fun lockMutator(id: UInt32): Int{ 
			ForeverWall.lockedMutators.insert(key: id, true)
			return ForeverWall.lockedMutators.length
		}
		
		// Unlocks a mutator
		access(TMP_ENTITLEMENT_OWNER)
		fun unlockMutator(id: UInt32): Int{ 
			ForeverWall.lockedMutators.remove(key: id)
			return ForeverWall.lockedMutators.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMerchantID(merchantID: UInt32): UInt32{ 
			ForeverWall.merchantID = merchantID
			return ForeverWall.merchantID
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintPFP(name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String): @NFT{ 
			
			// Mint the new item
			let newItem: @NFT <- create NFT(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
			return <-newItem
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintPFP(quantity: UInt32, name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String): @Collection{ 
			var i: UInt32 = 0
			let newCollection <- create Collection()
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintPFP(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity))
				i = i + 1 as UInt32
			}
			return <-newCollection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mutatePFP(tokenID: UInt64, name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			pre{ 
				tokenID <= ForeverWall.totalSupply:
					"the tokenID does not exist"
			}
			let mutation = ItemData(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
			ForeverWall.mutations[tokenID] = mutation
			emit ItemMutated(id: tokenID, mutation: mutation)
		}
		
		// addDefaultRoyalty adds a new default recipient for the cut of the sale
		//
		// Parameters: name: the key to store the new royalty
		//			 recipientAddress: the wallet address of the recipient of the cut of the sale
		//			 rate: the percentage of the sale that goes to that recipient
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun addDefaultRoyalty(name: String, royalty: MetadataViews.Royalty, rate: UFix64){ 
			pre{ 
				ForeverWall.defaultRoyalties[name] == nil:
					"The royalty with that name already exists"
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			ForeverWall.defaultRoyalties[name] = royalty
		
		// emit DefaultRoyaltyAdded(name: name, rate: rate)
		}
		
		// changeDefaultRoyaltyRate updates a recipient's part of the cut of the sale
		//
		// Parameters: name: the key of the recipient to update
		//			 rate: the new percentage of the sale that goes to that recipient
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun changeDefaultRoyaltyRate(name: String, rate: UFix64){ 
			pre{ 
				ForeverWall.defaultRoyalties[name] != nil:
					"The royalty with that name does not exist"
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			let royalty = ForeverWall.defaultRoyalties[name]!
			let previousRate = royalty.cut
			let previousRecipientAddress = royalty.receiver
			ForeverWall.defaultRoyalties[name] = MetadataViews.Royalty(receiver: previousRecipientAddress, cut: UFix64(rate), description: "ForeverWall Royalties")
			emit DefaultRoyaltyRateChanged(name: name, previousRate: previousRate, rate: rate)
		}
		
		// removeDefaultRoyalty removes a default recipient from the cut of the sale
		//
		// Parameters: name: the key to store the royalty to remove
		access(TMP_ENTITLEMENT_OWNER)
		fun removeDefaultRoyalty(name: String){ 
			pre{ 
				ForeverWall.defaultRoyalties[name] != nil:
					"The royalty with that name does not exist"
			}
			ForeverWall.defaultRoyalties.remove(key: name)
			emit DefaultRoyaltyRemoved(name: name)
		}
		
		// addRoyaltyForPFP adds a new recipient for the cut of the sale on a specific PFP
		//
		// Parameters: tokenID: the unique ID of the PFP
		//			 name: the key to store the new royalty
		//			 recipientAddress: the wallet address of the recipient of the cut of the sale
		//			 rate: the percentage of the sale that goes to that recipient
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun addRoyaltyForPFP(tokenID: UInt64, name: String, royalty: MetadataViews.Royalty, rate: UFix64){ 
			pre{ 
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			if ForeverWall.royaltiesForSpecificPFP.containsKey(tokenID) == false{ 
				let newEntry:{ String: MetadataViews.Royalty} ={} 
				newEntry.insert(key: name, royalty)
				(ForeverWall.royaltiesForSpecificPFP!).insert(key: tokenID, newEntry)
				emit RoyaltyForPFPAdded(tokenID: tokenID, name: name, rate: rate)
				return
			}
			
			// the TokenID already has an entry
			if (ForeverWall.royaltiesForSpecificPFP[tokenID]!).containsKey(name){ 
				// the entry already exists
				panic("The royalty with that name already exists")
			}
			(ForeverWall.royaltiesForSpecificPFP[tokenID]!).insert(key: name, royalty)
			emit RoyaltyForPFPAdded(tokenID: tokenID, name: name, rate: rate)
		}
		
		// changeRoyaltyRateForPFP changes the royalty rate for the sale on a specific PFP
		//
		// Parameters: tokenID: the unique ID of the PFP
		//			 name: the key to store the new royalty
		//			 rate: the percentage of the sale that goes to that recipient
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun changeRoyaltyRateForPFP(tokenID: UInt64, name: String, rate: UFix64){ 
			pre{ 
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			let previousRoyalty: MetadataViews.Royalty = (ForeverWall.royaltiesForSpecificPFP[tokenID]!)[name]!
			let newRoyalty = MetadataViews.Royalty(receiver: previousRoyalty.receiver, cut: UFix64(rate), description: "ForeverWall Royalties")
			(ForeverWall.royaltiesForSpecificPFP[tokenID]!).insert(key: name, newRoyalty)
			emit RoyaltyForPFPChanged(tokenID: tokenID, name: name, previousRate: previousRoyalty.cut, rate: rate)
		}
		
		// removeRoyaltyForPFP changes the royalty rate for the sale on a specific PFP
		//
		// Parameters: tokenID: the unique ID of the PFP
		//			 name: the key to store the royalty to remove
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRoyaltyForPFP(tokenID: UInt64, name: String){ 
			(ForeverWall.royaltiesForSpecificPFP[tokenID]!).remove(key: name)
			emit RoyaltyForPFPRemoved(tokenID: tokenID, name: name)
		}
		
		// revertRoyaltyForPFPToDefault removes the royalty setttings for the specific PFP
		// so it uses the default roylaties going forward
		//
		// Parameters: tokenID: the unique ID of the PFP
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun revertRoyaltyForPFPToDefault(tokenID: UInt64){ 
			ForeverWall.royaltiesForSpecificPFP.remove(key: tokenID)
			emit RoyaltyForPFPRevertedToDefault(tokenID: tokenID)
		}
	}
	
	// This is the interface that users can cast their MintPFPs Collection as
	// to allow others to deposit MintPFPs into their Collection. It also allows for reading
	// the IDs of MintPFPs in the Collection.
	access(all)
	resource interface ForeverWallCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowForeverWall(id: UInt64): &ForeverWall.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow PFP reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: ForeverWallCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of MintPFPs conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes a MintPFPs from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: PFP does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn MintPFPs items
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
		
		// deposit takes a MintPFPs and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			
			// Cast the deposited token as a MintPFPs NFT to make sure
			// it is the correct type
			let token <- token as! @ForeverWall.NFT
			
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
		
		// borrowNFT Returns a borrowed reference to a MintPFPs in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any MintPFPs specific data. Please use borrowForeverWalls to 
		// read MintPFPs data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowForeverWall returns a borrowed reference to a MintPFPs
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
		fun borrowForeverWall(id: UInt64): &ForeverWall.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ForeverWall.NFT
			} else{ 
				return nil
			}
		}
		
		// Making the collection conform to MetadataViews.Resolver
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ForeverWallNFT = nft as! &ForeverWall.NFT
			return ForeverWallNFT as &{ViewResolver.Resolver}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPageSize(id: UInt64, pageSize: PageSize){ 
			let itemRef = self.borrowForeverWall(id: id)!
			itemRef.setPageSize(pageSize: pageSize)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMaxGraffitiSize(id: UInt64, maxGraffitiSize: UInt32){ 
			let itemRef = self.borrowForeverWall(id: id)!
			itemRef.setMaxGraffitiSize(maxGraffitiSize: maxGraffitiSize)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setisEntriesBlocked(id: UInt64, isEntriesBlocked: Bool){ 
			let itemRef = self.borrowForeverWall(id: id)!
			itemRef.setisEntriesBlocked(isEntriesBlocked: isEntriesBlocked)
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
	// MintPFPs contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// MintPFPs in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ForeverWall.Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyMintPFPsCollection(): @ForeverWall.Collection{ 
		return <-create ForeverWall.Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getExternalURL(): MetadataViews.ExternalURL{ 
		return ForeverWall.ExternalURL
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSocials():{ String: MetadataViews.ExternalURL}{ 
		return ForeverWall.Socials
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getDescription(): String{ 
		return ForeverWall.Description
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSquareImage(): MetadataViews.Media{ 
		return ForeverWall.SquareImage
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBannerImage(): MetadataViews.Media{ 
		return ForeverWall.BannerImage
	}
	
	// Returns all of the locked mutator IDs
	access(TMP_ENTITLEMENT_OWNER)
	fun getLockedMutators():{ UInt32: Bool}{ 
		return ForeverWall.lockedMutators
	}
	
	// getMerchantID returns the merchant ID
	access(TMP_ENTITLEMENT_OWNER)
	fun getMerchantID(): UInt32{ 
		return self.merchantID
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
	
	// getDefaultRoyaltyRate returns a royalty object
	access(TMP_ENTITLEMENT_OWNER)
	fun getDefaultRoyalty(name: String): MetadataViews.Royalty?{ 
		return self.defaultRoyalties[name]
	}
	
	// returns the default
	access(TMP_ENTITLEMENT_OWNER)
	fun getTotalDefaultRoyaltyRate(): UFix64{ 
		var totalRoyalty = 0.0
		for key in self.defaultRoyalties.keys{ 
			let royal = self.defaultRoyalties[key] ?? panic("Royalty does not exist")
			totalRoyalty = totalRoyalty + royal.cut
		}
		return totalRoyalty
	}
	
	// getRoyaltiesForPFP returns the specific royalties for a PFP or the default royalties
	access(TMP_ENTITLEMENT_OWNER)
	fun getRoyaltiesForPFP(tokenID: UInt64):{ String: MetadataViews.Royalty}{ 
		return self.royaltiesForSpecificPFP[tokenID] ?? self.getDefaultRoyalties()
	}
	
	//  getRoyaltyNamesForPFP returns the  royalty names for a specific PFP or the default royalty names
	access(TMP_ENTITLEMENT_OWNER)
	fun getRoyaltyNamesForPFP(tokenID: UInt64): [String]{ 
		return self.royaltiesForSpecificPFP[tokenID]?.keys ?? self.getDefaultRoyaltyNames()
	}
	
	// getRoyaltyNamesForPFP returns a given royalty for a specific PFP or the default royalty names
	access(TMP_ENTITLEMENT_OWNER)
	fun getRoyaltyForPFP(tokenID: UInt64, name: String): MetadataViews.Royalty?{ 
		if self.royaltiesForSpecificPFP.containsKey(tokenID){ 
			let royaltiesForPFP:{ String: MetadataViews.Royalty} = self.royaltiesForSpecificPFP[tokenID]!
			return royaltiesForPFP[name]!
		}
		
		// if no specific royalty is set
		return self.getDefaultRoyalty(name: name)
	}
	
	// getTotalRoyaltyRateForPFP returns the total royalty rate for a give PFP
	access(TMP_ENTITLEMENT_OWNER)
	fun getTotalRoyaltyRateForPFP(tokenID: UInt64): UFix64{ 
		var totalRoyalty = 0.0
		let royalties = self.getRoyaltiesForPFP(tokenID: tokenID)
		for key in royalties.keys{ 
			let royal = royalties[key] ?? panic("Royalty does not exist")
			totalRoyalty = totalRoyalty + royal.cut
		}
		return totalRoyalty
	}
	
	// https://math.stackexchange.com/a/3003770
	// https://en.wikipedia.org/wiki/Pairing_function
	access(TMP_ENTITLEMENT_OWNER)
	fun convertCoordinatesToCantorNumber(coords: Coordinates): UInt64{ 
		
		// convert x and y into extended non-negative space
		let xExt = coords.x >= 0 ? Int32(2) * coords.x : Int32(-2) * coords.x - 1
		let yExt = coords.y >= 0 ? Int32(2) * coords.y : Int32(-2) * coords.y - 1
		
		// this will cause issue with ints 0.5?
		return UInt64((xExt + yExt) * (xExt + yExt + Int32(1)) / Int32(2) + yExt)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun convertCantorNumberToCoordinates(num: UInt64): Coordinates{ 
		
		// let  w = Math.floor((Math.sqrt(UInt64(8)*num+1)-1) / 2)
		let w: UInt64 = UInt64(MathUtils.sqrt(x: UInt64(8) * num + 1) - 1) / 2
		let t: UInt64 = (w * w + w) / 2
		let yExt: UInt64 = num - t
		let xExt: UInt64 = w - yExt
		var x: Int32 = Int32(xExt / 2)
		if xExt % 2 != 0{ 
			// odd
			x = -1 * Int32(xExt + 1) / 2
		}
		var y: Int32 = Int32(yExt / 2)
		if yExt % 2 != 0{ 
			// odd
			y = -1 * Int32(yExt + 1) / 2
		}
		
		// todo, lookup the z offset at that num. This is not in the helper functionm and will need to happen in the NFT itself
		return Coordinates(x: x, y: y, z: 0)
	}
	
	// -----------------------------------------------------------------------
	// MintPFPs initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.totalSupply = 0
		self.merchantID = 1
		self.mutations ={} 
		self.defaultRoyalties ={} 
		self.royaltiesForSpecificPFP ={} 
		self.lockedMutators ={} 
		self.ExternalURL = MetadataViews.ExternalURL("https://google.ca")
		self.Socials ={ "test": MetadataViews.ExternalURL("https://google.ca")}
		self.Description = "Templated Contract!"
		self.SquareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/60e2d81804d21546b930cf4e/6282368335c3a352cef0677c_mint-white-tm-p-500.png"), mediaType: "image/png")
		self.BannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/60e2d81804d21546b930cf4e/6282368335c3a352cef0677c_mint-white-tm-p-500.png"), mediaType: "image/png")
		self.CollectionStoragePath = /storage/ForeverWallCollection
		self.CollectionPublicPath = /public/ForeverWallCollection
		self.AdminStoragePath = /storage/ForeverWallAdmin
		self.MutatorStoragePath = /storage/ForeverWallMutator
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{ForeverWallCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the admin ressource in storage
		self.account.storage.save<@Admin>(<-create Admin(id: 1), to: self.AdminStoragePath)
		self.nextAdminID = 2
		
		// Put the admin ressource in storage
		self.account.storage.save<@Mutator>(<-create Mutator(id: 1), to: self.MutatorStoragePath)
		self.nextMutatorID = 2
		emit ContractInitialized()
	}
}
