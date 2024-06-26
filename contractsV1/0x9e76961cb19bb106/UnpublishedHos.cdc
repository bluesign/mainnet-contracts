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

	// Flickplay
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract UnpublishedHos: NonFungibleToken{ 
	/// Events
	///
	access(all)
	event ContractInitialized() /// emitted when the contract is initialized
	
	
	access(all)
	event Withdraw(id: UInt64, from: Address?) /// emitted when an NFT is withdrawn from an account
	
	
	access(all)
	event Deposit(id: UInt64, to: Address?) /// emitted when an NFT is deposited into an account
	
	
	access(all)
	event Minted(id: UInt64) /// emitted when a new NFT is minted
	
	
	access(all)
	event NFTDestroyed(id: UInt64) /// emitted when an NFT is destroyed
	
	
	access(all)
	event SetCreated(setId: UInt32) /// emitted when a new NFT set is created
	
	
	access(all)
	event SetMetadataUpdated(setId: UInt32) /// emitted when the metadata of an NFT set is updated
	
	
	access(all)
	event NFTMinted(tokenId: UInt64, setId: UInt32, editionNum: UInt64) /// emitted when a new NFT is minted within a specific set
	
	
	access(all)
	event ActionsAllowed(setId: UInt32, ids: [UInt64]) /// emitted when actions are allowed for a specific set and IDs
	
	
	access(all)
	event ActionsRestricted(setId: UInt32, ids: [UInt64]) /// emitted when actions are restricted for a specific set and IDs
	
	
	access(all)
	event AddedToWhitelist(addedAddresses: [Address]) /// emitted when addresses are added to the whitelist
	
	
	access(all)
	event RemovedFromWhitelist(removedAddresses: [Address]) /// emitted when addresses are removed from the whitelist
	
	
	access(all)
	event RoyaltyCutUpdated(newRoyaltyCut: UFix64) /// emitted when the royalty cut is updated
	
	
	access(all)
	event RoyaltyAddressUpdated(newAddress: Address) /// emitted when the royalty address is updated
	
	
	access(all)
	event NewAdminCreated() /// emitted when a new admin is created
	
	
	access(all)
	event Unboxed(setId: UInt32) /// emitted when set id updated when unboxing
	
	
	/// Contract paths
	///
	access(all)
	let CollectionStoragePath: StoragePath /// the storage path for NFT collections
	
	
	access(all)
	let CollectionPublicPath: PublicPath /// the public path for NFT collections
	
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	var totalSupply: UInt64 /// the total number of NFTs minted by the contract
	
	
	access(self)
	var royaltyCut: UFix64 //// the percentage of royalties to be distributed
	
	
	access(all)
	var royaltyAddress: Address /// the address to receive royalties
	
	
	access(all)
	var whitelist:{ Address: Bool} /// a dictionary that maps addresses to a boolean value, indicating if the address is whitelisted
	
	
	access(self)
	var setMetadata:{ UInt32: NFTSetMetadata} /// a dictionary that maps set IDs to NFTSetMetadata resources
	
	
	access(all)
	var allowedActions:{ UInt32:{ UInt64: Bool}} /// a dictionary that maps set IDs to a dictionary of token IDs and their allowed actions
	
	
	access(self)
	var series: @Series /// a reference to the Series resource
	
	
	access(all)
	resource Series{ 
		
		/// Resource state variables
		///
		access(self)
		var setIds: [UInt32]
		
		access(self)
		var tokenIDs: UInt64
		
		access(self)
		var numberEditionsMintedPerSet:{ UInt32: UInt64}
		
		/// Initialize the Series resource
		///
		init(){ 
			self.numberEditionsMintedPerSet ={} 
			self.setIds = []
			self.tokenIDs = 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addNftSet(setId: UInt32, name: String, edition: String, thumbnail: String, description: String, httpFile: String, maxEditions: UInt64, mediaFile: String, externalUrl: String, twitterLink: String, toyStats: ToyStats, toyProperties:{ String: AnyStruct}){ 
			pre{ 
				self.setIds.contains(setId) == false:
					"The Set has already been added to the Series."
			}
			var newNFTSet = NFTSetMetadata(setId: setId, name: name, edition: edition, thumbnail: thumbnail, description: description, httpFile: httpFile, maxEditions: maxEditions, mediaFile: mediaFile, externalUrl: externalUrl, twitterLink: twitterLink, toyStats: toyStats, toyProperties: toyProperties)
			self.setIds.append(setId)
			self.numberEditionsMintedPerSet[setId] = 0
			UnpublishedHos.setMetadata[setId] = newNFTSet
			emit SetCreated(setId: setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSetMetadata(setId: UInt32, name: String, edition: String, thumbnail: String, description: String, httpFile: String, maxEditions: UInt64, mediaFile: String, externalUrl: String, twitterLink: String, toyStats: ToyStats, toyProperties:{ String: AnyStruct}){ 
			pre{ 
				self.setIds.contains(setId) == true:
					"The Set is not part of this Series."
			}
			let newSetMetadata = NFTSetMetadata(setId: setId, name: name, edition: edition, thumbnail: thumbnail, description: description, httpFile: httpFile, maxEditions: maxEditions, mediaFile: mediaFile, externalUrl: externalUrl, twitterLink: twitterLink, toyStats: toyStats, toyProperties: toyProperties)
			UnpublishedHos.setMetadata[setId] = newSetMetadata
			emit SetMetadataUpdated(setId: setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSetStats(setId: UInt32, toyStats: ToyStats){ 
			pre{ 
				self.setIds.contains(setId) == true:
					"The Set is not part of this Series."
			}
			let newSetMetadata = NFTSetMetadata(setId: setId, name: UnpublishedHos.getSetMetadata(setId: setId).name, edition: UnpublishedHos.getSetMetadata(setId: setId).edition, thumbnail: UnpublishedHos.getSetMetadata(setId: setId).thumbnail, description: UnpublishedHos.getSetMetadata(setId: setId).description, httpFile: UnpublishedHos.getSetMetadata(setId: setId).httpFile, maxEditions: UnpublishedHos.getSetMetadata(setId: setId).maxEditions, mediaFile: UnpublishedHos.getSetMetadata(setId: setId).mediaFile, externalUrl: UnpublishedHos.getSetMetadata(setId: setId).externalUrl, twitterLink: UnpublishedHos.getSetMetadata(setId: setId).twitterLink, toyStats: toyStats, toyProperties: UnpublishedHos.getSetMetadata(setId: setId).toyProperties)
			UnpublishedHos.setMetadata[setId] = newSetMetadata
			emit SetMetadataUpdated(setId: setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSetTraits(setId: UInt32, toyProperties:{ String: AnyStruct}){ 
			pre{ 
				self.setIds.contains(setId) == true:
					"The Set is not part of this Series."
			}
			let newSetMetadata = NFTSetMetadata(setId: setId, name: UnpublishedHos.getSetMetadata(setId: setId).name, edition: UnpublishedHos.getSetMetadata(setId: setId).edition, thumbnail: UnpublishedHos.getSetMetadata(setId: setId).thumbnail, description: UnpublishedHos.getSetMetadata(setId: setId).description, httpFile: UnpublishedHos.getSetMetadata(setId: setId).httpFile, maxEditions: UnpublishedHos.getSetMetadata(setId: setId).maxEditions, mediaFile: UnpublishedHos.getSetMetadata(setId: setId).mediaFile, externalUrl: UnpublishedHos.getSetMetadata(setId: setId).externalUrl, twitterLink: UnpublishedHos.getSetMetadata(setId: setId).twitterLink, toyStats: UnpublishedHos.getSetMetadata(setId: setId).toyStats, toyProperties: toyProperties)
			UnpublishedHos.setMetadata[setId] = newSetMetadata
			emit SetMetadataUpdated(setId: setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateGenericMetadata(setId: UInt32, name: String, edition: String, thumbnail: String, description: String, httpFile: String, maxEditions: UInt64, mediaFile: String, externalUrl: String, twitterLink: String){ 
			pre{ 
				self.setIds.contains(setId) == true:
					"The Set is not part of this Series."
			}
			let newSetMetadata = NFTSetMetadata(setId: setId, name: name, edition: edition, thumbnail: thumbnail, description: description, httpFile: httpFile, maxEditions: maxEditions, mediaFile: mediaFile, externalUrl: externalUrl, twitterLink: twitterLink, toyStats: UnpublishedHos.getSetMetadata(setId: setId).toyStats, toyProperties: UnpublishedHos.getSetMetadata(setId: setId).toyProperties)
			UnpublishedHos.setMetadata[setId] = newSetMetadata
			emit SetMetadataUpdated(setId: setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintFlickplaySeriesNFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32){ 
			pre{ 
				self.numberEditionsMintedPerSet[setId] != nil:
					"The Set does not exist."
				self.numberEditionsMintedPerSet[setId]! < UnpublishedHos.getSetMaxEditions(setId: setId)!:
					"Set has reached maximum NFT edition capacity."
			}
			let tokenId: UInt64 = self.tokenIDs
			let editionNum: UInt64 = self.numberEditionsMintedPerSet[setId]! + 1
			recipient.deposit(token: <-create UnpublishedHos.NFT(tokenId: tokenId, setId: setId, editionNum: editionNum, name: UnpublishedHos.getSetMetadata(setId: setId).name, description: UnpublishedHos.getSetMetadata(setId: setId).description, thumbnail: UnpublishedHos.getSetMetadata(setId: setId).thumbnail))
			self.tokenIDs = self.tokenIDs + 1
			UnpublishedHos.totalSupply = UnpublishedHos.totalSupply + 1
			self.numberEditionsMintedPerSet[setId] = editionNum
			emit NFTMinted(tokenId: tokenId, setId: setId, editionNum: editionNum)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintFlickplaySeriesNFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32, amount: UInt32){ 
			pre{ 
				amount > 0:
					"Amount must be > 0"
			}
			var i: UInt32 = 0
			while i < amount{ 
				self.mintFlickplaySeriesNFT(recipient: recipient, setId: setId)
				i = i + 1
			}
		}
	}
	
	access(all)
	struct ToyStats{ 
		access(all)
		var level: UInt32
		
		access(all)
		var xp: UInt32
		
		access(all)
		var likes: UInt32
		
		access(all)
		var views: UInt32
		
		access(all)
		var uses: UInt32
		
		// pub var animation: String
		init(level: UInt32, xp: UInt32, likes: UInt32, views: UInt32, uses: UInt32){ 
			// animation: String,
			self.level = level
			self.xp = xp
			self.likes = likes
			self.views = views
			self.uses = uses
		// self.animation = animation
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStats(_ viewResolver: &{ViewResolver.Resolver}): ToyStats?{ 
		if let view = viewResolver.resolveView(Type<UnpublishedHos.ToyStats>()){ 
			if let v = view as? ToyStats{ 
				return v
			}
		}
		return nil
	}
	
	access(all)
	struct NFTSetMetadata{ 
		access(all)
		var setId: UInt32
		
		access(all)
		var name: String
		
		access(all)
		var edition: String
		
		access(all)
		var thumbnail: String
		
		access(all)
		var description: String
		
		access(all)
		var httpFile: String
		
		access(all)
		var maxEditions: UInt64
		
		access(all)
		var mediaFile: String
		
		access(all)
		var externalUrl: String
		
		access(all)
		var twitterLink: String
		
		access(all)
		var toyStats: ToyStats
		
		access(all)
		var toyProperties:{ String: AnyStruct}
		
		init(setId: UInt32, name: String, edition: String, thumbnail: String, description: String, httpFile: String, maxEditions: UInt64, mediaFile: String, externalUrl: String, twitterLink: String, toyStats: ToyStats, toyProperties:{ String: AnyStruct}){ 
			self.setId = setId
			self.name = name
			self.edition = edition
			self.thumbnail = thumbnail
			self.description = description
			self.httpFile = httpFile
			self.maxEditions = maxEditions
			self.mediaFile = mediaFile
			self.externalUrl = externalUrl
			self.twitterLink = twitterLink
			self.toyStats = toyStats
			self.toyProperties = toyProperties
			emit SetCreated(setId: self.setId)
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var setId: UInt32
		
		access(all)
		let editionNum: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		init(tokenId: UInt64, setId: UInt32, editionNum: UInt64, name: String, description: String, thumbnail: String){ 
			self.id = tokenId
			self.setId = setId
			self.editionNum = editionNum
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			emit Minted(id: self.id)
		}
		
		access(contract)
		fun unbox(newSetId: UInt32){ 
			self.setId = newSetId
			emit Unboxed(setId: newSetId)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<UnpublishedHos.ToyStats>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: UnpublishedHos.getSetMetadata(setId: self.setId).name, description: UnpublishedHos.getSetMetadata(setId: self.setId).description, thumbnail: MetadataViews.HTTPFile(url: UnpublishedHos.getSetMetadata(setId: self.setId).thumbnail))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: UnpublishedHos.getSetMetadata(setId: self.setId).edition, number: self.editionNum, max: UnpublishedHos.getSetMetadata(setId: self.setId).maxEditions)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.HTTPFile>():
					return MetadataViews.HTTPFile(url: UnpublishedHos.getSetMetadata(setId: self.setId).httpFile)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(UnpublishedHos.getSetMetadata(setId: self.setId).externalUrl)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: UnpublishedHos.CollectionStoragePath, publicPath: UnpublishedHos.CollectionPublicPath, publicCollection: Type<&UnpublishedHos.Collection>(), publicLinkedType: Type<&UnpublishedHos.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-UnpublishedHos.createEmptyCollection(nftType: Type<@UnpublishedHos.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: UnpublishedHos.getSetMetadata(setId: self.setId).mediaFile), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: UnpublishedHos.getSetMetadata(setId: self.setId).name, description: UnpublishedHos.getSetMetadata(setId: self.setId).description, externalURL: MetadataViews.ExternalURL(UnpublishedHos.getSetMetadata(setId: self.setId).externalUrl), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL(UnpublishedHos.getSetMetadata(setId: self.setId).twitterLink)})
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver: Capability<&{FungibleToken.Receiver}> = getAccount(UnpublishedHos.royaltyAddress).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: royaltyReceiver, cut: UnpublishedHos.royaltyCut, description: "Flickplay Royalty")])
				case Type<MetadataViews.Traits>():
					let traitsView = MetadataViews.dictToTraits(dict: UnpublishedHos.getSetMetadata(setId: self.setId).toyProperties, excludedNames: [])
					return traitsView
				case Type<UnpublishedHos.ToyStats>():
					return UnpublishedHos.getSetMetadata(setId: self.setId).toyStats
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Admin: IAdminSafeShare{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSeries(): &Series{ 
			return &UnpublishedHos.series as &Series
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowedActions(setId: UInt32, ids: [UInt64]){ 
			let set = UnpublishedHos.allowedActions[setId] ??{} 
			for id in ids{ 
				set[id] = true
			}
			UnpublishedHos.allowedActions[setId] = set
			emit ActionsAllowed(setId: setId, ids: ids)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRestrictedActions(setId: UInt32, ids: [UInt64]){ 
			let set = UnpublishedHos.allowedActions[setId] ??{} 
			for id in ids{ 
				set[id] = false
			}
			UnpublishedHos.allowedActions[setId] = set
			emit ActionsRestricted(setId: setId, ids: ids)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addToWhitelist(_toAddAddresses: [Address]){ 
			for address in _toAddAddresses{ 
				UnpublishedHos.whitelist[address] = true
			}
			emit AddedToWhitelist(addedAddresses: _toAddAddresses)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFromWhitelist(_toRemoveAddresses: [Address]){ 
			for address in _toRemoveAddresses{ 
				UnpublishedHos.whitelist[address] = false
			}
			emit RemovedFromWhitelist(removedAddresses: _toRemoveAddresses)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unboxNft(address: Address, nftId: UInt64, newSetId: UInt32){ 
			let collectionRef = getAccount(address).capabilities.get<&{UnpublishedHos.FlickplaySeriesCollectionPublic}>(UnpublishedHos.CollectionPublicPath).borrow()
			let nftRef = (collectionRef!).borrowFlickplaySeries(id: nftId)
			nftRef?.unbox(newSetId: newSetId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRoyaltyCut(newRoyalty: UFix64){ 
			UnpublishedHos.royaltyCut = newRoyalty
			emit RoyaltyCutUpdated(newRoyaltyCut: newRoyalty)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRoyaltyAddress(newReceiver: Address){ 
			UnpublishedHos.royaltyAddress = newReceiver
			emit RoyaltyAddressUpdated(newAddress: newReceiver)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface IAdminSafeShare{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSeries(): &UnpublishedHos.Series
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowedActions(setId: UInt32, ids: [UInt64])
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRestrictedActions(setId: UInt32, ids: [UInt64])
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addToWhitelist(_toAddAddresses: [Address])
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFromWhitelist(_toRemoveAddresses: [Address])
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unboxNft(address: Address, nftId: UInt64, newSetId: UInt32)
	}
	
	access(all)
	resource interface FlickplaySeriesCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowFlickplaySeries(id: UInt64): &UnpublishedHos.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow UnpublishedHos reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: FlickplaySeriesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let ref = (&self.ownedNFTs[withdrawID] as &{NonFungibleToken.NFT}?)!
			let flickplayNFT = ref as! &UnpublishedHos.NFT
			UnpublishedHos.getAllowedActionsStatus(setId: flickplayNFT.setId, tokenId: flickplayNFT.id) ?? panic("Actions for this token NOT allowed")
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
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
			let token <- token as! @UnpublishedHos.NFT
			// UnpublishedHos.getAllowedActionsStatus(setId: token.setId,tokenId: token.id) ?? panic("Actions for this token NOT allowed")
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// access(contract) fun depositInternal(token: @UnpublishedHos.NFT) {
		//	 let id: UInt64 = token.id
		//	 let oldToken <- self.ownedNFTs[id] <- token
		//	 emit Deposit(id: id, to: self.owner?.address)
		//	 destroy oldToken
		// }
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowFlickplaySeries(id: UInt64): &UnpublishedHos.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &UnpublishedHos.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let flickplayNFT = nft as! &UnpublishedHos.NFT
			return flickplayNFT as &{ViewResolver.Resolver}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun burn(id: UInt64){ 
			let nft <- self.ownedNFTs.remove(key: id) as! @UnpublishedHos.NFT?
			destroy nft
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
		return <-create UnpublishedHos.Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun fetch(_ from: Address, id: UInt64): &UnpublishedHos.NFT?{ 
		let collection = getAccount(from).capabilities.get<&UnpublishedHos.Collection>(UnpublishedHos.CollectionPublicPath).borrow<&UnpublishedHos.Collection>() ?? panic("Couldn't get collection")
		return collection.borrowFlickplaySeries(id: id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetMetadata(setId: UInt32): UnpublishedHos.NFTSetMetadata{ 
		return UnpublishedHos.setMetadata[setId]!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllowedActionsStatus(setId: UInt32, tokenId: UInt64): Bool?{ 
		if let set = UnpublishedHos.allowedActions[setId]{ 
			return set[tokenId]
		} else{ 
			return nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllSets(): [UnpublishedHos.NFTSetMetadata]{ 
		return UnpublishedHos.setMetadata.values
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getSetMaxEditions(setId: UInt32): UInt64?{ 
		return UnpublishedHos.setMetadata[setId]?.maxEditions
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/UnpublishedHosCollection
		self.CollectionPublicPath = /public/UnpublishedHosCollection
		self.AdminStoragePath = /storage/UnpublishedHosAdmin
		self.AdminPrivatePath = /private/UnpublishedHosAdminPrivate
		self.totalSupply = 0
		self.royaltyCut = 0.02
		self.royaltyAddress = self.account.address
		self.setMetadata ={} 
		self.whitelist ={} 
		self.allowedActions ={} 
		self.series <- create Series()
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&UnpublishedHos.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
