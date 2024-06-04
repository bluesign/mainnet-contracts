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

	/* */
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TiblesApp from "../0x5cdeb067561defcb/TiblesApp.cdc"

import TiblesNFT from "../0x5cdeb067561defcb/TiblesNFT.cdc"

import TiblesProducer from "../0x5cdeb067561defcb/TiblesProducer.cdc"

access(all)
contract Aggretsuko: NonFungibleToken, TiblesApp, TiblesNFT, TiblesProducer{ 
	access(all)
	let appId: String
	
	access(all)
	let title: String
	
	access(all)
	let description: String
	
	access(all)
	let ProducerStoragePath: StoragePath
	
	access(all)
	let ProducerPath: PrivatePath
	
	access(all)
	let ContentPath: PublicPath
	
	access(all)
	let contentCapability: Capability
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let PublicCollectionPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event MinterCreated(minterId: String)
	
	access(all)
	event TibleMinted(minterId: String, mintNumber: UInt32, id: UInt64)
	
	access(all)
	event TibleDestroyed(id: UInt64)
	
	access(all)
	event PackMinterCreated(minterId: String)
	
	access(all)
	event PackMinted(id: UInt64, printedPackId: String)
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT, TiblesNFT.INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mintNumber: UInt32
		
		access(self)
		let contentCapability: Capability
		
		access(self)
		let contentId: String
		
		init(id: UInt64, mintNumber: UInt32, contentCapability: Capability, contentId: String){ 
			self.id = id
			self.mintNumber = mintNumber
			self.contentId = contentId
			self.contentCapability = contentCapability
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata():{ String: AnyStruct}?{ 
			let content = self.contentCapability.borrow<&{TiblesProducer.IContent}>() ?? panic("Failed to borrow content provider")
			return content.getMetadata(contentId: self.contentId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun displayData():{ String: String}{ 
			let metadata = self.metadata() ?? panic("Missing NFT metadata")
			if metadata.containsKey("pack"){ 
				return{ "name": "Aggretsuko pack", "description": "A Aggretsuko pack", "imageUrl": "https://i.tibles.com/m/aggretsuko-flow-icon.png"}
			}
			let set = metadata["set"]! as! &Aggretsuko.Set
			let item = metadata["item"]! as! &Aggretsuko.Item
			let variant = metadata["variant"]! as! &Aggretsuko.Variant
			var edition: String = ""
			var serialInfo: String = ""
			if let maxCount = variant.maxCount(){ 
				edition = "Limited Edition"
				serialInfo = "LE | ".concat(variant.title()).concat(" #").concat(self.mintNumber.toString()).concat("/").concat(maxCount.toString())
			} else if let batchSize = variant.batchSize(){ 
				edition = "Standard Edition"
				let mintSeries = (self.mintNumber - 1) / batchSize + 1
				serialInfo = "S".concat(mintSeries.toString()).concat(" | ").concat(variant.title()).concat(" #").concat(self.mintNumber.toString())
			} else{ 
				panic("Missing batch size and max count")
			}
			let description = serialInfo.concat("\n").concat(edition).concat("\n").concat(set.title())
			let imageUrl = item.imageUrl(variantId: variant.id)
			return{ "name": item.title(), "description": description, "imageUrl": imageUrl, "edition": edition, "serialInfo": serialInfo}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun display(): MetadataViews.Display{ 
			let nftData = self.displayData()
			return MetadataViews.Display(name: nftData["name"] ?? "", description: nftData["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: nftData["imageUrl"] ?? ""))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun editions(): MetadataViews.Editions{ 
			let nftData = self.displayData()
			let metadata = self.metadata() ?? panic("Missing NFT metadata")
			if metadata.containsKey("pack"){ 
				return MetadataViews.Editions([MetadataViews.Edition(name: "Aggretsuko pack", number: UInt64(self.mintNumber), max: nil)])
			}
			let variant = metadata["variant"]! as! &Aggretsuko.Variant
			var maxCount: UInt64? = nil
			if let count = variant.maxCount(){ 
				maxCount = UInt64(count)
			}
			let editionInfo = MetadataViews.Edition(name: nftData["edition"] ?? "", number: UInt64(self.mintNumber), max: maxCount)
			let editionList: [MetadataViews.Edition] = [editionInfo]
			return MetadataViews.Editions(editionList)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun serial(): MetadataViews.Serial{ 
			return MetadataViews.Serial(UInt64(self.mintNumber))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun royalties(): MetadataViews.Royalties{ 
			let royalties: [MetadataViews.Royalty] = []
			return MetadataViews.Royalties(royalties)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun externalURL(): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL("https://app.aggretsuko.tibles.com/collection/".concat(self.id.toString()))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun nftCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: Aggretsuko.CollectionStoragePath, publicPath: Aggretsuko.PublicCollectionPath, publicCollection: Type<&Aggretsuko.Collection>(), publicLinkedType: Type<&Aggretsuko.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-Aggretsuko.createEmptyCollection(nftType: Type<@Aggretsuko.Collection>())
				})
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun nftCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.tibles.com/m/aggretsuko-flow-icon.png"), mediaType: "image/svg+xml")
			let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.tibles.com/m/aggretsuko-flow-collection-banner.png"), mediaType: "image/png")
			let socialsData:{ String: String} ={ "twitter": "https://twitter.com/aggretsukotible"}
			let socials:{ String: MetadataViews.ExternalURL} ={} 
			for key in socialsData.keys{ 
				socials[key] = MetadataViews.ExternalURL(socialsData[key]!)
			}
			return MetadataViews.NFTCollectionDisplay(name: "Aggretsuko Collection by Tibles", description: "Aggretsuko Tibles is a digital trading card collecting experience by Tibles, made just for Aggretsuko fans, backed by the FLOW blockchain.", externalURL: MetadataViews.ExternalURL("https://aggretsuko.tibles.com"), squareImage: squareMedia, bannerImage: bannerMedia, socials: socials)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun traits(): MetadataViews.Traits{ 
			let traits: [MetadataViews.Trait] = []
			return MetadataViews.Traits(traits)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return self.display()
				case Type<MetadataViews.Editions>():
					return self.editions()
				case Type<MetadataViews.Serial>():
					return self.serial()
				case Type<MetadataViews.Royalties>():
					return self.royalties()
				case Type<MetadataViews.ExternalURL>():
					return self.externalURL()
				case Type<MetadataViews.NFTCollectionData>():
					return self.nftCollectionData()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.nftCollectionDisplay()
				case Type<MetadataViews.Traits>():
					return self.traits()
				default:
					return nil
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, TiblesNFT.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let tible <- token as! @Aggretsuko.NFT
			self.depositTible(tible: <-tible)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositTible(tible: @{TiblesNFT.INFT}){ 
			pre{ 
				self.ownedNFTs[tible.id] == nil:
					"tible with this id already exists"
			}
			let token <- tible as! @Aggretsuko.NFT
			let id = token.id
			self.ownedNFTs[id] <-! token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft
			}
			panic("Failed to borrow NFT with ID: ".concat(id.toString()))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowTible(id: UInt64): &{TiblesNFT.INFT}{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &Aggretsuko.NFT
			}
			panic("Failed to borrow NFT with ID: ".concat(id.toString()))
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: tible does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawTible(id: UInt64): @{TiblesNFT.INFT}{ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("Cannot withdraw: tible does not exist in the collection")
			let tible <- token as! @Aggretsuko.NFT
			emit Withdraw(id: tible.id, from: self.owner?.address)
			return <-tible
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &Aggretsuko.NFT
			}
			panic("Failed to borrow NFT with ID: ".concat(id.toString()))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun tibleDescriptions():{ UInt64:{ String: AnyStruct}}{ 
			var descriptions:{ UInt64:{ String: AnyStruct}} ={} 
			for id in self.ownedNFTs.keys{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				let nft = ref as! &NFT
				var description:{ String: AnyStruct} ={} 
				description["mintNumber"] = nft.mintNumber
				description["metadata"] = nft.metadata()
				descriptions[id] = description
			}
			return descriptions
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun destroyTible(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("NFT not found")
			destroy token
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	struct ContentLocation{ 
		access(all)
		let setId: String
		
		access(all)
		let itemId: String
		
		access(all)
		let variantId: String
		
		init(setId: String, itemId: String, variantId: String){ 
			self.setId = setId
			self.itemId = itemId
			self.variantId = variantId
		}
	}
	
	access(all)
	struct interface IContentLocation{} 
	
	access(all)
	resource Producer: TiblesProducer.IProducer, TiblesProducer.IContent{ 
		access(contract)
		let minters: @{String:{ TiblesProducer.Minter}}
		
		access(contract)
		let contentIdsToPaths:{ String:{ TiblesProducer.ContentLocation}}
		
		access(contract)
		let sets:{ String: Set}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun minter(id: String): &Minter?{ 
			let ref = &self.minters[id] as &{TiblesProducer.IMinter}?
			return ref as! &Minter?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun set(id: String): &Set?{ 
			return &self.sets[id] as &Set?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSet(_ set: Set, contentCapability: Capability){ 
			pre{ 
				self.sets[set.id] == nil:
					"Set with id: ".concat(set.id).concat(" already exists")
			}
			self.sets[set.id] = set
			for item in set.items.values{ 
				for variant in set.variants.values{ 
					let limit: UInt32? = variant.maxCount()
					let minterId: String = set.id.concat(":").concat(item.id).concat(":").concat(variant.id)
					let minter <- create Minter(id: minterId, limit: limit, contentCapability: contentCapability)
					if self.minters.keys.contains(minterId){ 
						panic("Minter ID ".concat(minterId).concat(" already exists."))
					}
					self.minters[minterId] <-! minter
					let path = ContentLocation(setId: set.id, itemId: item.id, variantId: variant.id)
					self.contentIdsToPaths[minterId] = path
					emit MinterCreated(minterId: minterId)
				}
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(contentId: String):{ String: AnyStruct}?{ 
			let path = self.contentIdsToPaths[contentId] ?? panic("Failed to get content path")
			let location = path as! ContentLocation
			let set = self.set(id: location.setId) ?? panic("The set does not exist!")
			let item = set.item(location.itemId) ?? panic("Item metadata is nil")
			let variant = set.variant(location.variantId) ?? panic("Variant metadata is nil")
			var metadata:{ String: AnyStruct} ={} 
			metadata["set"] = set
			metadata["item"] = item
			metadata["variant"] = variant
			return metadata
		}
		
		init(){ 
			self.sets ={} 
			self.contentIdsToPaths ={} 
			self.minters <-{} 
		}
	}
	
	access(all)
	struct Set{ 
		access(all)
		let id: String
		
		access(contract)
		let items:{ String: Item}
		
		access(contract)
		let variants:{ String: Variant}
		
		access(contract)
		var metadata:{ String: AnyStruct}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun title(): String{ 
			return (self.metadata!)["title"]! as! String
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun item(_ id: String): &Item?{ 
			return &self.items[id] as &Item?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun variant(_ id: String): &Variant?{ 
			return &self.variants[id] as &Variant?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun update(title: String){ 
			self.metadata ={ "title": title}
		}
		
		init(id: String, title: String, items:{ String: Item}, variants:{ String: Variant}){ 
			self.id = id
			self.items = items
			self.variants = variants
			self.metadata = nil
			self.update(title: title)
		}
	}
	
	access(all)
	struct Item{ 
		access(all)
		let id: String
		
		access(contract)
		var metadata:{ String: AnyStruct}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun title(): String{ 
			return (self.metadata!)["title"]! as! String
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun imageUrl(variantId: String): String{ 
			let imageUrls = (self.metadata!)["imageUrls"]! as!{ String: String}
			return imageUrls[variantId]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun update(title: String, imageUrls:{ String: String}){ 
			self.metadata ={ "title": title, "imageUrls": imageUrls}
		}
		
		init(id: String, title: String, imageUrls:{ String: String}){ 
			self.id = id
			self.metadata = nil
			self.update(title: title, imageUrls: imageUrls)
		}
	}
	
	access(all)
	struct Variant{ 
		access(all)
		let id: String
		
		access(contract)
		var metadata:{ String: AnyStruct}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun title(): String{ 
			return (self.metadata!)["title"]! as! String
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchSize(): UInt32?{ 
			return (self.metadata!)["batchSize"] as! UInt32?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun maxCount(): UInt32?{ 
			return (self.metadata!)["maxCount"] as! UInt32?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun update(title: String, batchSize: UInt32?, maxCount: UInt32?){ 
			assert(batchSize == nil != (maxCount == nil), message: "batch size or max count can be used, not both")
			let metadata:{ String: AnyStruct} ={ "title": title}
			let previousBatchSize = (self.metadata ??{} )["batchSize"] as! UInt32?
			let previousMaxCount = (self.metadata ??{} )["maxCount"] as! UInt32?
			if let batchSize = batchSize{ 
				assert(previousMaxCount == nil, message: "Cannot change from max count to batch size")
				assert(previousBatchSize == nil || previousBatchSize == batchSize, message: "batch size cannot be changed once set")
				metadata["batchSize"] = batchSize
			}
			if let maxCount = maxCount{ 
				assert(previousBatchSize == nil, message: "Cannot change from batch size to max count")
				assert(previousMaxCount == nil || previousMaxCount == maxCount, message: "max count cannot be changed once set")
				metadata["maxCount"] = maxCount
			}
			self.metadata = metadata
		}
		
		init(id: String, title: String, batchSize: UInt32?, maxCount: UInt32?){ 
			self.id = id
			self.metadata = nil
			self.update(title: title, batchSize: batchSize, maxCount: maxCount)
		}
	}
	
	access(all)
	resource Minter: TiblesProducer.IMinter{ 
		access(all)
		let id: String
		
		access(all)
		var lastMintNumber: UInt32
		
		access(contract)
		let tibles: @{UInt32:{ TiblesNFT.INFT}}
		
		access(all)
		let limit: UInt32?
		
		access(all)
		let contentCapability: Capability
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(mintNumber: UInt32): @{TiblesNFT.INFT}{ 
			pre{ 
				self.tibles[mintNumber] != nil:
					"The tible does not exist in this minter."
			}
			return <-self.tibles.remove(key: mintNumber)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNext(){ 
			if let limit = self.limit{ 
				if self.lastMintNumber >= limit{ 
					panic("You've hit the limit for number of tokens in this minter!")
				}
			}
			let id = Aggretsuko.totalSupply + 1
			let mintNumber = self.lastMintNumber + 1
			let tible <- create NFT(id: id, mintNumber: mintNumber, contentCapability: self.contentCapability, contentId: self.id)
			self.tibles[mintNumber] <-! tible
			self.lastMintNumber = mintNumber
			Aggretsuko.totalSupply = id
			emit TibleMinted(minterId: self.id, mintNumber: mintNumber, id: id)
		}
		
		init(id: String, limit: UInt32?, contentCapability: Capability){ 
			self.id = id
			self.lastMintNumber = 0
			self.tibles <-{} 
			self.limit = limit
			self.contentCapability = contentCapability
		}
	}
	
	access(all)
	resource PackMinter: TiblesProducer.IContent{ 
		access(all)
		let id: String
		
		access(all)
		var lastMintNumber: UInt32
		
		access(contract)
		let packs: @{UInt64:{ TiblesNFT.INFT}}
		
		access(contract)
		let contentIdsToPaths:{ String:{ TiblesProducer.ContentLocation}}
		
		access(all)
		let contentCapability: Capability
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(contentId: String):{ String: AnyStruct}?{ 
			return{ "pack": "Aggretsuko"}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(id: UInt64): @{TiblesNFT.INFT}{ 
			pre{ 
				self.packs[id] != nil:
					"The pack does not exist in this minter."
			}
			return <-self.packs.remove(key: id)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNext(printedPackId: String){ 
			let id = Aggretsuko.totalSupply + 1
			let mintNumber = self.lastMintNumber + 1
			let pack <- create NFT(id: id, mintNumber: mintNumber, contentCapability: self.contentCapability, contentId: self.id)
			self.packs[id] <-! pack
			self.lastMintNumber = mintNumber
			Aggretsuko.totalSupply = id
			emit PackMinted(id: id, printedPackId: printedPackId)
		}
		
		init(id: String, contentCapability: Capability){ 
			self.id = id
			self.lastMintNumber = 0
			self.packs <-{} 
			self.contentCapability = contentCapability
			self.contentIdsToPaths ={} 
			emit PackMinterCreated(minterId: self.id)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createNewPackMinter(id: String, contentCapability: Capability): @PackMinter{ 
		assert(self.account.address == 0x481914259cb9174e, message: "wrong address")
		return <-create PackMinter(id: id, contentCapability: contentCapability)
	}
	
	init(){ 
		self.totalSupply = 0
		self.appId = "com.tibles.aggretsuko"
		self.title = "Aggretsuko Tibles"
		self.description = "Aggretsuko officially licensed digital collectibles"
		self.ProducerStoragePath = /storage/TiblesAggretsukoProducer
		self.ProducerPath = /private/TiblesAggretsukoProducer
		self.ContentPath = /public/TiblesAggretsukoContent
		self.CollectionStoragePath = /storage/TiblesAggretsukoCollection
		self.PublicCollectionPath = /public/TiblesAggretsukoCollection
		let producer <- create Producer()
		self.account.storage.save<@Producer>(<-producer, to: self.ProducerStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Producer>(self.ProducerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ProducerPath)
		var capability_2 = self.account.capabilities.storage.issue<&{TiblesProducer.IContent}>(self.ProducerStoragePath)
		self.account.capabilities.publish(capability_2, at: self.ContentPath)
		self.contentCapability = self.account.capabilities.get_<YOUR_TYPE>(self.ContentPath)
		emit ContractInitialized()
	}
}
