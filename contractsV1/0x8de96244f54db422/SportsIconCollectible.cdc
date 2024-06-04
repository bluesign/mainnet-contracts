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
	Description: Central Smart Contract for SportsIcon NFT Collectibles

	SportsIcon Collectibles are available as part of "sets", each with
	a fixed edition count.

	author: zay.codes
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import SportsIconCounter from "./SportsIconCounter.cdc"

import SportsIconBeneficiaries from "./SportsIconBeneficiaries.cdc"

access(all)
contract SportsIconCollectible: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// SportsIcon Events
	// -----------------------------------------------------------------------
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	event SetCreated(setID: UInt64)
	
	access(all)
	event SetRemoved(setID: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// SportsIcon Fields
	// -----------------------------------------------------------------------
	// Maintains state of what sets and editions have been minted to ensure
	// there are never 2 of the same set + edition combination
	// Provides a Set ID -> Edition ID -> UUID mapping
	access(contract)
	let collectibleData:{ UInt64:{ UInt64: CollectibleMetadata}}
	
	// Allows easy access to information for a set
	// Provides access from a set's setID to the information for that set
	access(contract)
	let setData:{ UInt64: SportsIconCollectible.SetMetadata}
	
	// Allows easy access to pointers from an NFT to its metadata keys
	// Provides CollectibleID -> (SetID + EditionID) mapping
	access(contract)
	let allCollectibleIDs:{ UInt64: CollectibleEditionData}
	
	// -----------------------------------------------------------------------
	// SportsIcon Structs
	// -----------------------------------------------------------------------
	access(all)
	struct CollectibleMetadata{ 
		// The NFT Id is optional so a collectible may have associated metadata prior to being minted
		// This is useful for porting existing unique collections over to Flow (I.E. SportsLions)
		access(self)
		var nftID: UInt64?
		
		access(self)
		var metadata:{ String: String}
		
		init(){ 
			self.metadata ={} 
			self.nftID = nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNftID(): UInt64?{ 
			return self.nftID
		}
		
		// Returns all metadata for this collectible
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(account)
		fun updateNftID(_ nftID: UInt64){ 
			pre{ 
				self.nftID == nil:
					"An NFT already exists for this collectible."
			}
			self.nftID = nftID
		}
		
		access(account)
		fun updateMetadata(_ metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	struct CollectibleEditionData{ 
		access(self)
		let editionNumber: UInt64
		
		access(self)
		let setID: UInt64
		
		init(editionNumber: UInt64, setID: UInt64){ 
			self.editionNumber = editionNumber
			self.setID = setID
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEditionNumber(): UInt64{ 
			return self.editionNumber
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetID(): UInt64{ 
			return self.setID
		}
	}
	
	access(all)
	struct SetMetadata{ 
		access(self)
		let setID: UInt64
		
		access(self)
		var mediaURL: String
		
		access(self)
		var metadata:{ String: String}
		
		access(self)
		var maxNumberOfEditions: UInt64
		
		access(self)
		var editionCount: UInt64
		
		access(self)
		var publicFUSDSalePrice: UFix64?
		
		access(self)
		var publicFLOWSalePrice: UFix64?
		
		access(self)
		var publicSaleStartTime: UFix64?
		
		access(self)
		var publicSaleEndTime: UFix64?
		
		init(setID: UInt64, mediaURL: String, maxNumberOfEditions: UInt64, metadata:{ String: String}, mintBeneficiaries: SportsIconBeneficiaries.Beneficiaries, marketBeneficiaries: SportsIconBeneficiaries.Beneficiaries){ 
			self.setID = setID
			self.mediaURL = mediaURL
			self.metadata = metadata
			self.maxNumberOfEditions = maxNumberOfEditions
			self.editionCount = 0
			SportsIconBeneficiaries.setMintBeneficiaries(setID: setID, beneficiaries: mintBeneficiaries)
			SportsIconBeneficiaries.setMarketBeneficiaries(setID: setID, beneficiaries: marketBeneficiaries)
			self.publicFUSDSalePrice = nil
			self.publicFLOWSalePrice = nil
			self.publicSaleStartTime = nil
			self.publicSaleEndTime = nil
		}
		
		/*
					Readonly functions
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetID(): UInt64{ 
			return self.setID
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMediaURL(): String{ 
			return self.mediaURL
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getMaxNumberOfEditions(): UInt64{ 
			return self.maxNumberOfEditions
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEditionCount(): UInt64{ 
			return self.editionCount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFUSDPublicSalePrice(): UFix64?{ 
			return self.publicFUSDSalePrice
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFLOWPublicSalePrice(): UFix64?{ 
			return self.publicFLOWSalePrice
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPublicSaleStartTime(): UFix64?{ 
			return self.publicSaleStartTime
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPublicSaleEndTime(): UFix64?{ 
			return self.publicSaleEndTime
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEditionMetadata(editionNumber: UInt64):{ String: String}{ 
			pre{ 
				editionNumber >= 1 && editionNumber <= self.maxNumberOfEditions:
					"Invalid edition number provided"
				(SportsIconCollectible.collectibleData[self.setID]!)[editionNumber] != nil:
					"Requested edition has not yet been minted"
			}
			return ((SportsIconCollectible.collectibleData[self.setID]!)[editionNumber]!).getMetadata()
		}
		
		// If there is no beneficiary data, assume that there are no royalty destinations
		access(TMP_ENTITLEMENT_OWNER)
		fun getMintBeneficiaries(): SportsIconBeneficiaries.Beneficiaries{ 
			return SportsIconBeneficiaries.mintBeneficiaries[self.setID] ?? SportsIconBeneficiaries.Beneficiaries(beneficiaries: [])
		}
		
		// If there is no beneficiary data, assume that there are no royalty destinations
		access(TMP_ENTITLEMENT_OWNER)
		fun getMarketBeneficiaries(): SportsIconBeneficiaries.Beneficiaries{ 
			return SportsIconBeneficiaries.marketBeneficiaries[self.setID] ?? SportsIconBeneficiaries.Beneficiaries(beneficiaries: [])
		}
		
		// A public sale allowing for direct minting from the contract is considered active if we have a valid public
		// sale price listing, current time is after start time, and current time is before end time
		access(TMP_ENTITLEMENT_OWNER)
		fun isPublicSaleActive(): Bool{ 
			let curBlockTime = getCurrentBlock().timestamp
			return self.publicSaleStartTime != nil && curBlockTime >= self.publicSaleStartTime! && (self.publicSaleEndTime == nil || curBlockTime < self.publicSaleEndTime!)
		}
		
		/*
					Mutating functions
				*/
		
		access(contract)
		fun incrementEditionCount(): UInt64{ 
			post{ 
				self.editionCount <= self.maxNumberOfEditions:
					"Number of editions is larger than max allowed editions"
			}
			self.editionCount = self.editionCount + 1
			return self.editionCount
		}
		
		access(contract)
		fun updateMaxNumberOfEditions(maxNumberOfEditions: UInt64){ 
			pre{ 
				maxNumberOfEditions > 0:
					"Max number of editions should be above 0"
				maxNumberOfEditions >= self.editionCount:
					"Number of editions is larger than max allowed editions"
				maxNumberOfEditions <= self.maxNumberOfEditions:
					"Max number of editions is larger than previous max number of editions"
			}
			self.maxNumberOfEditions = maxNumberOfEditions
		}
		
		access(contract)
		fun updateSetMetadata(_ newMetadata:{ String: String}){ 
			self.metadata = newMetadata
		}
		
		access(contract)
		fun updateFLOWPublicSalePrice(_ publicFLOWSalePrice: UFix64?){ 
			self.publicFLOWSalePrice = publicFLOWSalePrice
		}
		
		access(contract)
		fun updateFUSDPublicSalePrice(_ publicFUSDSalePrice: UFix64?){ 
			self.publicFUSDSalePrice = publicFUSDSalePrice
		}
		
		access(contract)
		fun updatePublicSaleStartTime(_ startTime: UFix64?){ 
			self.publicSaleStartTime = startTime
		}
		
		access(contract)
		fun updatePublicSaleEndTime(_ endTime: UFix64?){ 
			self.publicSaleEndTime = endTime
		}
		
		access(contract)
		fun updateMediaURL(_ mediaURL: String){ 
			self.mediaURL = mediaURL
		}
	}
	
	// -----------------------------------------------------------------------
	// SportsIcon Interfaces
	// -----------------------------------------------------------------------
	access(all)
	resource interface CollectibleCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(collectibleCollection: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollectible(id: UInt64): &SportsIconCollectible.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow KittyItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Resources
	// -----------------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let editionNumber: UInt64
		
		init(setID: UInt64, editionNumber: UInt64){ 
			pre{ 
				!SportsIconCollectible.collectibleData.containsKey(setID) || !(SportsIconCollectible.collectibleData[setID]!).containsKey(editionNumber):
					"This set and edition combination already exists"
				SportsIconCollectible.setData.containsKey(setID):
					"Invalid Set ID"
				editionNumber > 0 && editionNumber <= (SportsIconCollectible.setData[setID]!).getMaxNumberOfEditions():
					"Edition number is too high"
			}
			// Update unique set
			self.id = self.uuid
			SportsIconCounter.incrementNFTCounter()
			self.setID = setID
			self.editionNumber = editionNumber
			
			// If this edition number does not have a metadata object, create one
			if (SportsIconCollectible.collectibleData[setID]!)[editionNumber] == nil{ 
				let ref = SportsIconCollectible.collectibleData[setID]!
				ref[editionNumber] = CollectibleMetadata()
				SportsIconCollectible.collectibleData[setID] = ref
			}
			((			  // Update the metadata object to have a reference to this newly created NFT
			  SportsIconCollectible.collectibleData[setID]!)[editionNumber]!).updateNftID(self.id)
			
			// Create mapping of new nft id to its newly created set and edition data
			SportsIconCollectible.allCollectibleIDs[self.uuid] = CollectibleEditionData(editionNumber: editionNumber, setID: setID)
			
			// Increase total supply of entire sportsicon collection
			SportsIconCollectible.totalSupply = SportsIconCollectible.totalSupply + 1 as UInt64
			emit Mint(id: self.uuid)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let metadata = (SportsIconCollectible.getSetMetadataForNFTByUUID(uuid: self.uuid)!).getMetadata()
					let name = metadata["title"] != nil ? metadata["title"]! : "SportsIcon Collectible #".concat(self.id.toString())
					let description = metadata["description"] != nil ? metadata["description"]! : name
					let url = metadata["coverImageURL"] != nil ? metadata["coverImageURL"]! : ""
					return MetadataViews.Display(name: name, description: description, thumbnail: MetadataViews.HTTPFile(url: url))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://sportsicon.com/nfts/".concat(self.setID.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SportsIconCollectible.CollectionStoragePath, publicPath: SportsIconCollectible.CollectionPublicPath, publicCollection: Type<&SportsIconCollectible.Collection>(), publicLinkedType: Type<&SportsIconCollectible.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SportsIconCollectible.createEmptyCollection(nftType: Type<@SportsIconCollectible.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://sportsicon.com/images/sportsicon-logo-flow.png"), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://sportsicon.com/images/sportsicon-banner-flow.jpg"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "SportsIcon Collection", description: "The world's first sports-focused NFT marketplace.", externalURL: MetadataViews.ExternalURL("https://sportsicon.com"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/sportsicon"), "discord": MetadataViews.ExternalURL("http://discord.gg/mfAx4nzqEe"), "telegram": MetadataViews.ExternalURL("https://t.me/sportsiconchat"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/_SportsIcon_/"), "youtube": MetadataViews.ExternalURL("https://www.youtube.com/channel/UCpwABtrFnRHMMM1k7zIf93w")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectibleCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: NFT does not exist in the collection")
			emit Withdraw(id: token.uuid, from: self.owner?.address)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @SportsIconCollectible.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(collectibleCollection: @{NonFungibleToken.Collection}){ 
			let keys = collectibleCollection.getIDs()
			for key in keys{ 
				self.deposit(token: <-collectibleCollection.withdraw(withdrawID: key))
			}
			destroy collectibleCollection
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollectible(id: UInt64): &SportsIconCollectible.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			} else{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &SportsIconCollectible.NFT
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let SportsIconCollectibleNFT = nft as! &SportsIconCollectible.NFT
			return SportsIconCollectibleNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
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
	
	// -----------------------------------------------------------------------
	// SportsIcon Admin Functionality
	// -----------------------------------------------------------------------
	/*
			Creation of a new NFT set under the SportsIcon umbrella of collectibles
		*/
	
	access(account)
	fun addNFTSet(mediaURL: String, maxNumberOfEditions: UInt64, data:{ String: String}, mintBeneficiaries: SportsIconBeneficiaries.Beneficiaries, marketBeneficiaries: SportsIconBeneficiaries.Beneficiaries): UInt64{ 
		let id = SportsIconCounter.nextSetID
		let newSet = SportsIconCollectible.SetMetadata(setID: id, mediaURL: mediaURL, maxNumberOfEditions: maxNumberOfEditions, metadata: data, mintBeneficiaries: mintBeneficiaries, marketBeneficiaries: marketBeneficiaries)
		self.collectibleData[id] ={} 
		self.setData[id] = newSet
		SportsIconCounter.incrementSetCounter()
		emit SetCreated(setID: id)
		return id
	}
	
	access(account)
	fun removeNFTSet(setID: UInt64){ 
		let nftSet = SportsIconCollectible.setData.remove(key: setID) ?? panic("missing set metadata")
		self.collectibleData[setID] = nil
		self.setData[setID] = nil
		emit SetRemoved(setID: setID)
	}
	
	/*
			Update existing set and edition data
		*/
	
	access(account)
	fun updateEditionMetadata(setID: UInt64, editionNumber: UInt64, metadata:{ String: String}){ 
		if (SportsIconCollectible.collectibleData[setID]!)[editionNumber] == nil{ 
			let ref = SportsIconCollectible.collectibleData[setID]!
			ref[editionNumber] = CollectibleMetadata()
			SportsIconCollectible.collectibleData[setID] = ref
		}
		((SportsIconCollectible.collectibleData[setID]!)[editionNumber]!).updateMetadata(metadata)
	}
	
	access(account)
	fun updateSetMetadata(setID: UInt64, metadata:{ String: String}){ 
		(SportsIconCollectible.setData[setID]!).updateSetMetadata(metadata)
	}
	
	access(account)
	fun updateMediaURL(setID: UInt64, mediaURL: String){ 
		(SportsIconCollectible.setData[setID]!).updateMediaURL(mediaURL)
	}
	
	access(account)
	fun updateFLOWPublicSalePrice(setID: UInt64, price: UFix64?){ 
		(SportsIconCollectible.setData[setID]!).updateFLOWPublicSalePrice(price)
	}
	
	access(account)
	fun updateFUSDPublicSalePrice(setID: UInt64, price: UFix64?){ 
		(SportsIconCollectible.setData[setID]!).updateFUSDPublicSalePrice(price)
	}
	
	access(account)
	fun updatePublicSaleStartTime(setID: UInt64, startTime: UFix64?){ 
		(SportsIconCollectible.setData[setID]!).updatePublicSaleStartTime(startTime)
	}
	
	access(account)
	fun updatePublicSaleEndTime(setID: UInt64, endTime: UFix64?){ 
		(SportsIconCollectible.setData[setID]!).updatePublicSaleEndTime(endTime)
	}
	
	access(account)
	fun updateMaxNumberOfEditions(setID: UInt64, maxNumberOfEditions: UInt64){ 
		(SportsIconCollectible.setData[setID]!).updateMaxNumberOfEditions(maxNumberOfEditions: maxNumberOfEditions)
	}
	
	/*
			Minting functions to create editions within a set
		*/
	
	// This mint is intended for sequential mints (for a normal in-order drop style)
	access(account)
	fun mintSequentialEditionNFT(setID: UInt64): @SportsIconCollectible.NFT{ 
		let editionCount = (self.setData[setID]!).incrementEditionCount()
		let newCollectible <- create SportsIconCollectible.NFT(setID: setID, editionNumber: editionCount)
		return <-newCollectible
	}
	
	// This mint is intended for settling auctions or manually minting editions,
	// where we mint specific editions to specific recipients when settling
	// SetID + editionID to mint is normally decided off-chain
	access(account)
	fun mintNFT(setID: UInt64, editionNumber: UInt64): @SportsIconCollectible.NFT{ 
		(self.setData[setID]!).incrementEditionCount()
		return <-create SportsIconCollectible.NFT(setID: setID, editionNumber: editionNumber)
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// -----------------------------------------------------------------------
	// SportsIcon Functions
	// -----------------------------------------------------------------------
	// Retrieves all sets (This can be expensive)
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadatas():{ UInt64: SportsIconCollectible.SetMetadata}{ 
		return self.setData
	}
	
	// Retrieves how many NFT sets exist
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadatasCount(): UInt64{ 
		return UInt64(self.setData.length)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadataForSetID(setID: UInt64): SportsIconCollectible.SetMetadata?{ 
		return self.setData[setID]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetMetadataForNFT(nft: &SportsIconCollectible.NFT): SportsIconCollectible.SetMetadata?{ 
		return self.setData[nft.setID]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetMetadataForNFTByUUID(uuid: UInt64): SportsIconCollectible.SetMetadata?{ 
		let collectibleEditionData = self.allCollectibleIDs[uuid]!
		return self.setData[collectibleEditionData.getSetID()]!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadataForNFTByUUID(uuid: UInt64): SportsIconCollectible.CollectibleMetadata?{ 
		let collectibleEditionData = self.allCollectibleIDs[uuid]!
		return (self.collectibleData[collectibleEditionData.getSetID()]!)[collectibleEditionData.getEditionNumber()]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadataByEditionID(setID: UInt64, editionNumber: UInt64): SportsIconCollectible.CollectibleMetadata?{ 
		return (self.collectibleData[setID]!)[editionNumber]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectibleDataForNftByUUID(uuid: UInt64): SportsIconCollectible.CollectibleEditionData?{ 
		return self.allCollectibleIDs[uuid]!
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/sportsIconCollectibleCollection
		self.CollectionPublicPath = /public/sportsIconCollectibleCollection
		self.CollectionPrivatePath = /private/sportsIconCollectibleCollection
		self.totalSupply = 0
		self.collectibleData ={} 
		self.setData ={} 
		self.allCollectibleIDs ={} 
		emit ContractInitialized()
	}
}
