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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import CollecticoRoyalties from "../0xffe32280cd5b72a3/CollecticoRoyalties.cdc"

import CollecticoStandardNFT from "../0x11cbef9729b236f3/CollecticoStandardNFT.cdc"

import CollecticoStandardViews from "../0x11cbef9729b236f3/CollecticoStandardViews.cdc"

import CollectionResolver from "../0x11cbef9729b236f3/CollectionResolver.cdc"

/*
	General Purpose Collection
	(c) CollecticoLabs.com
 */

access(all)
contract OGs: NonFungibleToken, CollecticoStandardNFT, CollectionResolver{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, itemId: UInt64, serialNumber: UInt64)
	
	access(all)
	event Claimed(id: UInt64, itemId: UInt64, claimId: String)
	
	access(all)
	event Destroyed(id: UInt64, itemId: UInt64, serialNumber: UInt64)
	
	access(all)
	event ItemCreated(id: UInt64, name: String)
	
	access(all)
	event ItemDeleted(id: UInt64)
	
	access(all)
	event CollectionMetadataUpdated(keys: [String])
	
	access(all)
	event NewAdminCreated(receiver: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionProviderPath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let contractName: String
	
	access(self)
	var items: @{UInt64: Item}
	
	access(self)
	var nextItemId: UInt64
	
	access(self)
	var metadata:{ String: AnyStruct}
	
	access(self)
	var claims:{ String: Bool}
	
	access(self)
	var defaultRoyalties: [MetadataViews.Royalty]
	
	// for the future use
	access(self)
	var nftViewResolvers: @{String:{ CollecticoStandardViews.NFTViewResolver}}
	
	access(self)
	var itemViewResolvers: @{String:{ CollecticoStandardViews.ItemViewResolver}}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.License>(), Type<CollecticoStandardViews.ContractInfo>()]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(name: self.metadata["name"]! as! String, description: self.metadata["description"]! as! String, thumbnail: (self.metadata["squareImage"]! as! MetadataViews.Media).file)
			case Type<MetadataViews.ExternalURL>():
				return self.getExternalURL()
			case Type<MetadataViews.NFTCollectionDisplay>():
				return self.getCollectionDisplay()
			case Type<MetadataViews.NFTCollectionData>():
				return self.getCollectionData()
			case Type<MetadataViews.Royalties>():
				return MetadataViews.Royalties(self.defaultRoyalties.concat(CollecticoRoyalties.getIssuerRoyalties()))
			case Type<MetadataViews.License>():
				let licenseId: String? = self.metadata["_licenseId"] as! String?
				return licenseId != nil ? MetadataViews.License(licenseId!) : nil
			case Type<CollecticoStandardViews.ContractInfo>():
				return self.getContractInfo()
		}
		return nil
	}
	
	access(all)
	resource Item: CollecticoStandardNFT.IItem, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		access(all)
		let maxSupply: UInt64?
		
		access(all)
		let royalties: MetadataViews.Royalties?
		
		access(all)
		var numMinted: UInt64
		
		access(all)
		var numDestroyed: UInt64
		
		access(all)
		var isLocked: Bool
		
		access(all)
		let isTransferable: Bool
		
		init(id: UInt64, name: String, description: String, thumbnail:{ MetadataViews.File}, metadata:{ String: AnyStruct}?, maxSupply: UInt64?, isTransferable: Bool, royalties: [MetadataViews.Royalty]?){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
			self.maxSupply = maxSupply
			self.isTransferable = isTransferable
			if royalties != nil && (royalties!).length > 0{ 
				self.royalties = MetadataViews.Royalties((royalties!).concat(CollecticoRoyalties.getIssuerRoyalties()))
			} else{ 
				let defaultRoyalties = OGs.defaultRoyalties.concat(CollecticoRoyalties.getIssuerRoyalties())
				if defaultRoyalties.length > 0{ 
					self.royalties = MetadataViews.Royalties(defaultRoyalties)
				} else{ 
					self.royalties = nil
				}
			}
			self.numMinted = 0
			self.numDestroyed = 0
			self.isLocked = false
		}
		
		access(contract)
		fun incrementNumMinted(){ 
			self.numMinted = self.numMinted + 1
		}
		
		access(contract)
		fun incrementNumDestroyed(){ 
			self.numDestroyed = self.numDestroyed + 1
		}
		
		access(contract)
		fun lock(){ 
			self.isLocked = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getTotalSupply(): UInt64{ 
			return self.numMinted - self.numDestroyed
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<CollecticoStandardViews.ItemView>(), Type<CollecticoStandardViews.ContractInfo>(), Type<MetadataViews.Display>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Medias>(), Type<MetadataViews.License>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<CollecticoStandardViews.ItemView>():
					return CollecticoStandardViews.ItemView(id: self.id, name: self.name, description: self.description, thumbnail: self.thumbnail, metadata: self.metadata, totalSupply: self.getTotalSupply(), maxSupply: self.maxSupply, isLocked: self.isLocked, isTransferable: self.isTransferable, contractInfo: OGs.getContractInfo(), collectionDisplay: OGs.getCollectionDisplay(), royalties: MetadataViews.getRoyalties(&self as &OGs.Item), display: MetadataViews.getDisplay(&self as &OGs.Item), traits: MetadataViews.getTraits(&self as &OGs.Item), medias: MetadataViews.getMedias(&self as &OGs.Item), license: MetadataViews.getLicense(&self as &OGs.Item))
				case Type<CollecticoStandardViews.ContractInfo>():
					return OGs.getContractInfo()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: self.thumbnail)
				case Type<MetadataViews.Traits>():
					return OGs.dictToTraits(dict: self.metadata, excludedNames: nil)
				case Type<MetadataViews.Royalties>():
					return self.royalties
				case Type<MetadataViews.Medias>():
					return OGs.dictToMedias(dict: self.metadata, excludedNames: nil)
				case Type<MetadataViews.License>():
					var licenseId: String? = OGs.getDictValue(dict: self.metadata, key: "_licenseId", type: Type<String>()) as! String?
					if licenseId == nil{ 
						licenseId = OGs.getDictValue(dict: OGs.metadata, key: "_licenseId", type: Type<String>()) as! String?
					}
					return licenseId != nil ? MetadataViews.License(licenseId!) : nil
				case Type<MetadataViews.ExternalURL>():
					return OGs.getExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return OGs.getCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return OGs.getCollectionData()
			}
			return nil
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemId: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		access(all)
		let royalties: MetadataViews.Royalties? // reserved for the fututure use
		
		
		access(all)
		var isTransferable: Bool
		
		init(id: UInt64, itemId: UInt64, serialNumber: UInt64, isTransferable: Bool, metadata:{ String: AnyStruct}?, royalties: [MetadataViews.Royalty]?){ 
			self.id = id
			self.itemId = itemId
			self.serialNumber = serialNumber
			self.isTransferable = isTransferable
			self.metadata = metadata
			if royalties != nil && (royalties!).length > 0{ 
				self.royalties = MetadataViews.Royalties((royalties!).concat(CollecticoRoyalties.getIssuerRoyalties()))
			} else{ 
				self.royalties = nil // it will fallback to the item's royalties
			
			}
			emit Minted(id: id, itemId: itemId, serialNumber: serialNumber)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<CollecticoStandardViews.NFTView>(), Type<CollecticoStandardViews.ContractInfo>(), Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Medias>(), Type<MetadataViews.License>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let item = OGs.getItemRef(itemId: self.itemId)
			switch view{ 
				case Type<CollecticoStandardViews.NFTView>():
					return CollecticoStandardViews.NFTView(id: self.id, itemId: self.itemId, itemName: item.name.concat(" #").concat(self.serialNumber.toString()), itemDescription: item.description, itemThumbnail: *item.thumbnail, itemMetadata: *item.metadata, serialNumber: self.serialNumber, metadata: self.metadata, itemTotalSupply: item.getTotalSupply(), itemMaxSupply: item.maxSupply, isTransferable: self.isTransferable, contractInfo: OGs.getContractInfo(), collectionDisplay: OGs.getCollectionDisplay(), royalties: MetadataViews.getRoyalties(&self as &OGs.NFT), display: MetadataViews.getDisplay(&self as &OGs.NFT), traits: MetadataViews.getTraits(&self as &OGs.NFT), editions: MetadataViews.getEditions(&self as &OGs.NFT), medias: MetadataViews.getMedias(&self as &OGs.NFT), license: MetadataViews.getLicense(&self as &OGs.NFT))
				case Type<CollecticoStandardViews.ContractInfo>():
					return OGs.getContractInfo()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: item.name.concat(" #").concat(self.serialNumber.toString()), description: item.description, thumbnail: *item.thumbnail)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: item.name, number: self.serialNumber, max: item.maxSupply)
					return MetadataViews.Editions([editionInfo])
				case Type<MetadataViews.Traits>():
					let mergedMetadata = OGs.mergeDicts(*item.metadata, self.metadata)
					return OGs.dictToTraits(dict: mergedMetadata, excludedNames: nil)
				case Type<MetadataViews.Royalties>():
					return self.royalties != nil ? self.royalties : item.royalties
				case Type<MetadataViews.Medias>():
					return OGs.dictToMedias(dict: *item.metadata, excludedNames: nil)
				case Type<MetadataViews.License>():
					return MetadataViews.getLicense(item as &{ViewResolver.Resolver})
				case Type<MetadataViews.ExternalURL>():
					return OGs.getExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return OGs.getCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return OGs.getCollectionData()
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollecticoNFT(id: UInt64): &OGs.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CollecticoNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Borrow nft and check if locked
			let nft = self.borrowCollecticoNFT(id: withdrawID) ?? panic("Requested NFT does not exist in the collection")
			if !nft.isTransferable{ 
				panic("Cannot withdraw: NFT is not transferable (Soulbound)")
			}
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Requested NFT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
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
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @OGs.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
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
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollecticoNFT(id: UInt64): &OGs.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &OGs.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let collecticoNFT = nft as! &OGs.NFT
			return collecticoNFT
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
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllItemsRef(): [&Item]{ 
		let resultItems: [&Item] = []
		for key in self.items.keys{ 
			let item = self.getItemRef(itemId: key)
			resultItems.append(item)
		}
		return resultItems
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllItems(view: Type): [AnyStruct]{ 
		let resultItems: [AnyStruct] = []
		for key in self.items.keys{ 
			let item = self.getItemRef(itemId: key)
			let itemView = item.resolveView(view)
			if itemView == nil{ 
				return [] // Unsupported view
			
			}
			resultItems.append(itemView!)
		}
		return resultItems
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getItemRef(itemId: UInt64): &Item{ 
		pre{ 
			self.items[itemId] != nil:
				"Item doesn't exist"
		}
		let item = &self.items[itemId] as &Item?
		return item!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getItem(itemId: UInt64, view: Type): AnyStruct?{ 
		pre{ 
			self.items[itemId] != nil:
				"Item doesn't exist"
		}
		let item: &Item = self.getItemRef(itemId: itemId)
		return item.resolveView(view)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isClaimed(claimId: String): Bool{ 
		return self.claims.containsKey(claimId)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun areClaimed(claimIds: [String]):{ String: Bool}{ 
		let res:{ String: Bool} ={} 
		for claimId in claimIds{ 
			res.insert(key: claimId, self.isClaimed(claimId: claimId))
		}
		return res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun countNFTsMintedPerItem(itemId: UInt64): UInt64{ 
		let item = self.getItemRef(itemId: itemId)
		return item.numMinted
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun countNFTsDestroyedPerItem(itemId: UInt64): UInt64{ 
		let item = self.getItemRef(itemId: itemId)
		return item.numDestroyed
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun isItemSupplyValid(itemId: UInt64): Bool{ 
		let item = self.getItemRef(itemId: itemId)
		return item.maxSupply == nil || item.getTotalSupply() <= item.maxSupply!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun isItemLocked(itemId: UInt64): Bool{ 
		let item = self.getItemRef(itemId: itemId)
		return item.isLocked
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun assertCollectionMetadataIsValid(){ 
		// assert display data:
		self.assertDictEntry(self.metadata, "name", Type<String>(), true)
		self.assertDictEntry(self.metadata, "description", Type<String>(), true)
		self.assertDictEntry(self.metadata, "externalURL", Type<MetadataViews.ExternalURL>(), true)
		self.assertDictEntry(self.metadata, "squareImage", Type<MetadataViews.Media>(), true)
		self.assertDictEntry(self.metadata, "bannerImage", Type<MetadataViews.Media>(), true)
		self.assertDictEntry(self.metadata, "socials", Type<{String: MetadataViews.ExternalURL}>(), true)
		self.assertDictEntry(self.metadata, "_licenseId", Type<String>(), false)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getExternalURL(): MetadataViews.ExternalURL{ 
		return self.metadata["externalURL"]! as! MetadataViews.ExternalURL
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getContractInfo(): CollecticoStandardViews.ContractInfo{ 
		return CollecticoStandardViews.ContractInfo(name: self.contractName, address: self.account.address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
		return MetadataViews.NFTCollectionDisplay(name: self.metadata["name"]! as! String, description: self.metadata["description"]! as! String, externalURL: self.metadata["externalURL"]! as! MetadataViews.ExternalURL, squareImage: self.metadata["squareImage"]! as! MetadataViews.Media, bannerImage: self.metadata["bannerImage"]! as! MetadataViews.Media, socials: self.metadata["socials"]! as!{ String: MetadataViews.ExternalURL})
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionData(): MetadataViews.NFTCollectionData{ 
		return MetadataViews.NFTCollectionData(storagePath: self.CollectionStoragePath, publicPath: self.CollectionPublicPath, publicCollection: Type<&OGs.Collection>(), publicLinkedType: Type<&OGs.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
				return <-OGs.createEmptyCollection(nftType: Type<@OGs.Collection>())
			})
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun assertItemMetadataIsValid(itemId: UInt64){ 
		let item = self.getItemRef(itemId: itemId)
		self.assertDictEntry(*item.metadata, "_licenseId", Type<String>(), false)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun assertDictEntry(_ dict:{ String: AnyStruct}?, _ key: String, _ type: Type, _ required: Bool){ 
		if dict != nil{ 
			self.assertValueAndType(name: key, value: (dict!)[key], type: type, required: required)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun assertValueAndType(name: String, value: AnyStruct?, type: Type, required: Bool){ 
		if required{ 
			assert(value != nil, message: "Missing required value for '".concat(name).concat("'"))
		}
		if value != nil{ 
			assert((value!).isInstance(type), message: "Incorrect type for '".concat(name).concat("' - expected ").concat(type.identifier).concat(", got ").concat((value!).getType().identifier))
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getDictValue(dict:{ String: AnyStruct}?, key: String, type: Type): AnyStruct?{ 
		if dict == nil || (dict!)[key] == nil || !((dict!)[key]!).isInstance(type){ 
			return nil
		}
		return (dict!)[key]!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun dictToTraits(dict:{ String: AnyStruct}?, excludedNames: [String]?): MetadataViews.Traits?{ 
		let traits = self.dictToTraitArray(dict: dict, excludedNames: excludedNames)
		return traits.length != 0 ? MetadataViews.Traits(traits) : nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun dictToTraitArray(dict:{ String: AnyStruct}?, excludedNames: [String]?): [MetadataViews.Trait]{ 
		if dict == nil{ 
			return []
		}
		let dictionary = dict!
		if excludedNames != nil{ 
			for k in excludedNames!{ 
				dictionary.remove(key: k)
			}
		}
		let traits: [MetadataViews.Trait] = []
		for k in dictionary.keys{ 
			if dictionary[k] == nil || k.length < 1 || k[0] == "_"{ // key starts with '_' character or value is nil 
				
				continue
			}
			if (dictionary[k]!).isInstance(Type<MetadataViews.Trait>()){ 
				traits.append(dictionary[k]! as! MetadataViews.Trait)
			} else if (dictionary[k]!).isInstance(Type<String>()){ 
				traits.append(MetadataViews.Trait(name: k, value: dictionary[k]!, displayType: nil, rarity: nil))
			} else if (dictionary[k]!).isInstance(Type<{String: AnyStruct?}>()){ 
				// {String: AnyStruct?} just in case and for explicity, it's not needed as of now, {String: AnyStruct} works as well
				let trait:{ String: AnyStruct?} = dictionary[k]! as!{ String: AnyStruct?}
				var displayType: String? = nil
				var rarity: MetadataViews.Rarity? = nil
				// Purposefully checking and casting to String? instead of String due to rare cases
				// when displayType != nil AND all the other fields == nil 
				// then the type of such dictionary is {String: String?} instead of {String: String}
				if trait["displayType"] != nil && (trait["displayType"]!).isInstance(Type<String?>()){ 
					displayType = trait["displayType"]! as! String?
				}
				// Purposefully checking and casting to MetadataViews.Rarity? instead of MetadataViews.Rarity- see reasoning above
				if trait["rarity"] != nil && (trait["rarity"]!).isInstance(Type<MetadataViews.Rarity?>()){ 
					rarity = trait["rarity"]! as! MetadataViews.Rarity?
				}
				traits.append(MetadataViews.Trait(name: k, value: trait["value"], displayType: displayType, rarity: rarity))
			}
		}
		return traits
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun dictToMedias(dict:{ String: AnyStruct}?, excludedNames: [String]?): MetadataViews.Medias?{ 
		let medias = self.dictToMediaArray(dict: dict, excludedNames: excludedNames)
		return medias.length != 0 ? MetadataViews.Medias(medias) : nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun dictToMediaArray(dict:{ String: AnyStruct}?, excludedNames: [String]?): [MetadataViews.Media]{ 
		if dict == nil{ 
			return []
		}
		let dictionary = dict!
		if excludedNames != nil{ 
			for k in excludedNames!{ 
				dictionary.remove(key: k)
			}
		}
		let medias: [MetadataViews.Media] = []
		for k in dictionary.keys{ 
			if dictionary[k] == nil || k.length < 6 || k.slice(from: 0, upTo: 6) != "_media"{ 
				continue
			}
			if (dictionary[k]!).isInstance(Type<MetadataViews.Media>()){ 
				medias.append(dictionary[k]! as! MetadataViews.Media)
			} else if (dictionary[k]!).isInstance(Type<{String: AnyStruct?}>()){ 
				let media:{ String: AnyStruct} = dictionary[k]! as!{ String: AnyStruct}
				var file:{ MetadataViews.File}? = nil
				var mediaType: String? = nil
				if media["mediaType"] != nil && (media["mediaType"]!).isInstance(Type<String>()){ 
					mediaType = media["mediaType"]! as! String
				}
				if media["file"] != nil && (media["file"]!).isInstance(Type<{MetadataViews.File}>()){ 
					file = media["file"]! as!{ MetadataViews.File}
				}
				if file != nil && mediaType != nil{ 
					medias.append(MetadataViews.Media(file: file!, mediaType: mediaType!))
				}
			}
		}
		return medias
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mergeDicts(_ dict1:{ String: AnyStruct}?, _ dict2:{ String: AnyStruct}?):{ String: AnyStruct}?{ 
		if dict1 == nil{ 
			return dict2
		} else if dict2 == nil{ 
			return dict1
		}
		for k in (dict2!).keys{ 
			if (dict2!)[k]! != nil{ 
				(dict1!).insert(key: k, (dict2!)[k]!)
			}
		}
		return dict1
	}
	
	access(all)
	resource Admin{ 
		
		// for the future use
		access(all)
		let data:{ String: AnyStruct}
		
		init(){ 
			self.data ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createItem(name: String, description: String, thumbnail: MetadataViews.Media, metadata:{ String: AnyStruct}?, maxSupply: UInt64?, isTransferable: Bool?, royalties: [MetadataViews.Royalty]?): UInt64{ 
			let newItemId = OGs.nextItemId
			OGs.items[newItemId] <-! create Item(id: newItemId, name: name, description: description, thumbnail: thumbnail.file, metadata: metadata != nil ? metadata! :{} , maxSupply: maxSupply, isTransferable: isTransferable != nil ? isTransferable! : true, royalties: royalties)
			OGs.assertItemMetadataIsValid(itemId: newItemId)
			OGs.nextItemId = newItemId + 1
			emit ItemCreated(id: newItemId, name: name)
			return newItemId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteItem(itemId: UInt64){ 
			pre{ 
				OGs.items[itemId] != nil:
					"Item doesn't exist"
				OGs.countNFTsMintedPerItem(itemId: itemId) == OGs.countNFTsDestroyedPerItem(itemId: itemId):
					"Cannot delete item that has existing NFTs"
			}
			let item <- OGs.items.remove(key: itemId)
			emit ItemDeleted(id: itemId)
			destroy item
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockItem(itemId: UInt64){ 
			pre{ 
				OGs.items[itemId] != nil:
					"Item doesn't exist"
			}
			let item = OGs.getItemRef(itemId: itemId)
			item.lock()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(itemId: UInt64, isTransferable: Bool?, metadata:{ String: AnyStruct}?): @NFT{ 
			pre{ 
				OGs.items[itemId] != nil:
					"Item doesn't exist"
				!OGs.isItemLocked(itemId: itemId):
					"Item is locked and cannot be minted anymore"
			}
			post{ 
				OGs.isItemSupplyValid(itemId: itemId):
					"Max supply reached- cannot mint more NFTs of this type"
			}
			let item = OGs.getItemRef(itemId: itemId)
			let newNFTid = OGs.totalSupply + 1
			let newSerialNumber = item.numMinted + 1
			let newNFT: @NFT <- create NFT(id: newNFTid, itemId: itemId, serialNumber: newSerialNumber, isTransferable: isTransferable != nil ? isTransferable! : item.isTransferable, metadata: metadata, royalties: nil)
			item.incrementNumMinted()
			OGs.totalSupply = OGs.totalSupply + 1
			return <-newNFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintAndClaim(itemId: UInt64, claimId: String, isTransferable: Bool?, metadata:{ String: AnyStruct}?): @NFT{ 
			pre{ 
				!OGs.claims.containsKey(claimId):
					"Item already claimed"
			}
			post{ 
				OGs.claims.containsKey(claimId):
					"Claim failed"
			}
			let newNFT: @NFT <- self.mintNFT(itemId: itemId, isTransferable: isTransferable, metadata: metadata)
			OGs.claims.insert(key: claimId, true)
			emit Claimed(id: newNFT.id, itemId: newNFT.itemId, claimId: claimId)
			return <-newNFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(receiver: Address?): @Admin{ 
			emit NewAdminCreated(receiver: receiver)
			return <-create Admin()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateCollectionMetadata(data:{ String: AnyStruct}){ 
			for key in data.keys{ 
				OGs.metadata.insert(key: key, data[key]!)
			}
			OGs.assertCollectionMetadataIsValid()
			emit CollectionMetadataUpdated(keys: data.keys)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateDefaultRoyalties(royalties: [MetadataViews.Royalty]){ 
			OGs.defaultRoyalties = royalties
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.nextItemId = 1
		self.items <-{} 
		self.claims ={} 
		self.defaultRoyalties = []
		self.nftViewResolvers <-{} 
		self.itemViewResolvers <-{} 
		self.contractName = "OGs"
		self.metadata ={ "name": "Collectico OGs", "description": "This is Collectico's first collection", "externalURL": MetadataViews.ExternalURL("https://collecticolabs.com"), "squareImage": MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafybeiafjzcjwws7m4snfunpgnvxlufr7tbclzxtorlgepek2je3pbuboe", path: "square.png"), mediaType: "image/png"), "bannerImage": MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafybeiafjzcjwws7m4snfunpgnvxlufr7tbclzxtorlgepek2je3pbuboe", path: "banner.jpg"), mediaType: "image/jpeg"), "socials":{ "twitter": MetadataViews.ExternalURL("https://twitter.com/CollecticoLabs")}}
		
		// Set the named paths
		self.CollectionStoragePath = /storage/collecticoOGsCollection
		self.CollectionPublicPath = /public/collecticoOGsCollection
		self.CollectionProviderPath = /private/collecticoOGsCollection
		self.AdminStoragePath = /storage/collecticoOGsAdmin
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&OGs.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
