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

import OverluError from "./OverluError.cdc"

import OverluConfig from "./OverluConfig.cdc"

import OverluDNA from "./OverluDNA.cdc"

access(all)
contract OverluModel: NonFungibleToken{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, to: Address?)
	
	access(all)
	event ModelUpgraded(modelId: UInt64, dnaId: UInt64, dnaType: UInt64, level: Int)
	
	access(all)
	event ModelExpanded(modelId: UInt64, dnaId: UInt64, dnaType: UInt64, slotNum: UInt64)
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var levelLimit: UInt64
	
	// metadata 
	access(contract)
	var predefinedMetadata:{ UInt64:{ String: AnyStruct}}
	
	// model owner mapping
	access(account)
	let ownerMapping:{ UInt64: Address}
	
	/// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		var slotNum: UInt64
		
		// access(self) let dnas: @{UInt64: [OverluDNA.NFT]}
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, slotNum: UInt64, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
			self.slotNum = slotNum
		// self.dnas <- {}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun upgradeModel(dna: @OverluDNA.NFT){ 
			pre{ 
				self.slotNum > UInt64(OverluConfig.getUpgradeRecords(self.id)?.length ?? 0):
					OverluError.errorEncode(msg: "Upgrade: slot number not enough", err: OverluError.ErrorCode.EXCEEDED_AMOUNT_LIMIT)
				// OverluDNA.exemptionTypeIds.contains(dna.typeId) : OverluError.errorEncode(msg: "Upgrade: dna type not allowed", err: OverluError.ErrorCode.MISMATCH_RESOURCE_TYPE)
				OverluModel.levelLimit > UInt64(OverluConfig.getUpgradeRecords(self.id)?.length ?? 0):
					OverluError.errorEncode(msg: "Upgrade: level limit exceeded", err: OverluError.ErrorCode.EXCEEDED_AMOUNT_LIMIT)
				dna.calculateEnergy() >= 100.0:
					OverluError.errorEncode(msg: "Upgrade: DNA engrgy not enough", err: OverluError.ErrorCode.INSUFFICIENT_ENERGY)
			}
			
			// let metadata = OverluDNA.getMetadata(dna.typeId)!
			let metadata = dna.getMetadata()
			let upgradeable = (metadata["upgradeable"] as? Bool?)! ?? false
			let energy = dna.calculateEnergy()
			assert(upgradeable == true, message: OverluError.errorEncode(msg: "Upgrade: dna type not upgradeable".concat(dna.typeId.toString()), err: OverluError.ErrorCode.MISMATCH_RESOURCE_TYPE))
			assert(energy == 100.0, message: OverluError.errorEncode(msg: "Upgrade: dna not enough energy ", err: OverluError.ErrorCode.INSUFFICIENT_ENERGY))
			metadata["id"] = dna.id
			OverluConfig.setUpgradeRecords(self.id, metadata: metadata)
			OverluConfig.setDNANestRecords(self.id, dnaId: dna.id)
			emit ModelUpgraded(modelId: self.id, dnaId: dna.id, dnaType: dna.typeId, level: (OverluConfig.getUpgradeRecords(self.id)!).length)
			destroy dna
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun expandModel(dna: @OverluDNA.NFT){ 
			pre{ 
				// self.slotNum < OverluModel.levelLimit: OverluError.errorEncode(msg: "Upgrade: level limit exceeded", err: OverluError.ErrorCode.EXCEEDED_AMOUNT_LIMIT)
				dna.calculateEnergy() >= 100.0:
					OverluError.errorEncode(msg: "Upgrade: DNA engrgy not enough", err: OverluError.ErrorCode.INSUFFICIENT_ENERGY)
			}
			let metadata = OverluDNA.getMetadata(dna.typeId)!
			let expandable = (metadata["expandable"] as? Bool?)! ?? false
			let energy = dna.calculateEnergy()
			assert(expandable == true, message: OverluError.errorEncode(msg: "Expand: dna type not expandable", err: OverluError.ErrorCode.MISMATCH_RESOURCE_TYPE))
			assert(energy == 100.0, message: OverluError.errorEncode(msg: "Upgrade: dna not enough energy ", err: OverluError.ErrorCode.INSUFFICIENT_ENERGY))
			let slotNum = self.slotNum + 1
			self.slotNum = slotNum
			metadata["id"] = dna.id
			OverluConfig.setExpandRecords(self.id, metadata: metadata)
			OverluConfig.setDNANestRecords(self.id, dnaId: dna.id)
			emit ModelExpanded(modelId: self.id, dnaId: dna.id, dnaType: dna.typeId, slotNum: slotNum)
			destroy dna
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: AnyStruct}{ 
			let metadata = OverluModel.predefinedMetadata[self.id] ??{} 
			metadata["id"] = self.id
			metadata["name"] = self.name
			metadata["desc"] = self.description
			metadata["thumbnail"] = self.thumbnail
			metadata["metadata"] = self.metadata
			metadata["slotNum"] = self.slotNum
			metadata["dnas"] = OverluConfig.getDNANestRecords(self.id)
			metadata["expands"] = OverluConfig.getExpandRecords(self.id)
			metadata["nested"] = OverluConfig.getDNANestRecords(self.id)
			return metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = OverluModel.predefinedMetadata[self.id] ??{} 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Overlu model NFT", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>(): // todo
					
					return MetadataViews.ExternalURL(self.thumbnail)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: OverluModel.CollectionStoragePath, publicPath: OverluModel.CollectionPublicPath, publicCollection: Type<&OverluModel.Collection>(), publicLinkedType: Type<&OverluModel.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-OverluModel.createEmptyCollection(nftType: Type<@OverluModel.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62f22a8782c301212eb2bee8/attachments/62f22aae83b02f8c02303b4c/previews/62f22aaf83b02f8c02303b9d/download/image.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Overlu Avatar NFT", description: "It integrates all adaptation components of LU. Different avatars will have different abilities to combine with LUs, which depend on their basic attributes. Each avatar is given 1 to 3 LUs to be integrated with. Only if the LU that injected into the avatar can produce real utility (upgrade the appearance components and obtain the corresponding rights).", externalURL: MetadataViews.ExternalURL("https://www.overlu.io"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62f22a8782c301212eb2bee8/attachments/62f22aae83b02f8c02303b4c/previews/62f22aaf83b02f8c02303b9d/download/image.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62f22a8782c301212eb2bee8/attachments/62f22aae83b02f8c02303b4c/previews/62f22aaf83b02f8c02303b9d/download/image.png"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/OVERLU_NFT")})
				case Type<MetadataViews.Traits>():
					let metadata = self.getMetadata()
					let traitsView = MetadataViews.dictToTraits(dict: metadata, excludedNames: [])
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					return traitsView
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
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOverluModel(id: UInt64): &OverluModel.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow OverluModel reference: the ID of the returned reference is incorrect"
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @OverluModel.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			OverluModel.ownerMapping[id] = (self.owner!).address!
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
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
		fun borrowOverluModel(id: UInt64): &OverluModel.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &OverluModel.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let OverluModel = nft as! &OverluModel.NFT
			return OverluModel as &{ViewResolver.Resolver}
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
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, slotNum: UInt64, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			assert(OverluModel.totalSupply < 10000, message: OverluError.errorEncode(msg: "Mint: Total supply reach max", err: OverluError.ErrorCode.EXCEEDED_AMOUNT_LIMIT))
			let nftId = OverluModel.totalSupply
			// create a new NFT
			var newNFT <- create NFT(id: nftId, name: name, description: description, thumbnail: thumbnail, slotNum: slotNum, royalties: royalties, metadata: metadata)
			emit Minted(id: newNFT.id, to: (recipient.owner!).address)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			OverluModel.ownerMapping[nftId] = (recipient.owner!).address!
			OverluModel.totalSupply = OverluModel.totalSupply + UInt64(1)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setLevelLimit(_ limit: UInt64){ 
			OverluModel.levelLimit = limit
		}
		
		// UpdateMetadata
		// Update metadata for a typeId
		//  type // max // name // description // thumbnail // royalties
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMetadata(id: UInt64, metadata:{ String: AnyStruct}){ 
			OverluModel.predefinedMetadata[id] = metadata
		}
	}
	
	// public funcs
	access(TMP_ENTITLEMENT_OWNER)
	fun getTotalSupply(): UInt64{ 
		return self.totalSupply
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadata(_ id: UInt64):{ String: AnyStruct}?{ 
		let metadata = self.predefinedMetadata[id] ??{} 
		metadata["dnas"] = OverluConfig.getUpgradeRecords(id) ?? []
		metadata["expands"] = OverluConfig.getExpandRecords(id) ?? []
		return metadata
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getOwner(_ id: UInt64): Address{ 
		pre{ 
			self.ownerMapping[id] != nil:
				OverluError.errorEncode(msg: "getOwner: can not find ", err: OverluError.ErrorCode.EXCEEDED_AMOUNT_LIMIT)
		}
		return self.ownerMapping[id]!
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/OverluModelCollection
		self.CollectionPublicPath = /public/OverluModelCollection
		self.MinterStoragePath = /storage/OverluModelMinter
		self._reservedFields ={} 
		self.predefinedMetadata ={} 
		self.ownerMapping ={} 
		self.levelLimit = 0
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&OverluModel.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
