/*
BeerRun

This is the contract for BeerRun NFTs! 

This was implemented using Niftory interfaces. For full details on how this
contract functions, please see the Niftory and NFTRegistry contracts.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MutableMetadata from "../0x7ec1f607f0872a9e/MutableMetadata.cdc"

import MutableMetadataTemplate from "../0x7ec1f607f0872a9e/MutableMetadataTemplate.cdc"

import MutableMetadataSet from "../0x7ec1f607f0872a9e/MutableMetadataSet.cdc"

import MutableMetadataSetManager from "../0x7ec1f607f0872a9e/MutableMetadataSetManager.cdc"

import MetadataViewsManager from "../0x7ec1f607f0872a9e/MetadataViewsManager.cdc"

import NiftoryNonFungibleToken from "../0x7ec1f607f0872a9e/NiftoryNonFungibleToken.cdc"

import NiftoryNFTRegistry from "../0x7ec1f607f0872a9e/NiftoryNFTRegistry.cdc"

import NiftoryMetadataViewsResolvers from "../0x7ec1f607f0872a9e/NiftoryMetadataViewsResolvers.cdc"

import NiftoryNonFungibleTokenProxy from "../0x7ec1f607f0872a9e/NiftoryNonFungibleTokenProxy.cdc"

access(all)
contract BeerRun: NonFungibleToken{ 
	
	// ========================================================================
	// Constants 
	// ========================================================================
	
	// Suggested paths where collection could be stored
	access(all)
	let COLLECTION_PRIVATE_PATH: PrivatePath
	
	access(all)
	let COLLECTION_PUBLIC_PATH: PublicPath
	
	access(all)
	let COLLECTION_STORAGE_PATH: StoragePath
	
	// Accessor token to be used with NiftoryNFTRegistry to retrieve
	// meta-information about this NFT project
	access(all)
	let REGISTRY_ADDRESS: Address
	
	access(all)
	let REGISTRY_BRAND: String
	
	// ========================================================================
	// Attributes
	// ========================================================================
	// Arbitrary metadata for this NFT contract
	access(all)
	var metadata: AnyStruct?
	
	// Number of NFTs created
	access(all)
	var totalSupply: UInt64
	
	// ========================================================================
	// Contract Events
	// ========================================================================
	// This contract was initialized
	access(all)
	event ContractInitialized()
	
	// A withdrawal of NFT `id` has occurred from the `from` Address
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// A deposit of an NFT `id` has occurred to the `to` Address
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// An NFT being minted from a given Template within a given Set
	access(all)
	event NFTMinted(id: UInt64, setId: Int, templateId: Int, serial: UInt64)
	
	// An NFT was minted
	// An NFT was burned
	// ========================================================================
	// NFT
	// ========================================================================
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver, NiftoryNonFungibleToken.NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setId: Int
		
		access(all)
		let templateId: Int
		
		access(all)
		let serial: UInt64
		
		access(all)
		view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
			return BeerRun._contract()
		}
		
		access(all)
		fun set(): &MutableMetadataSet.Set{ 
			return self._contract().getSetManagerPublic().getSet(self.setId)
		}
		
		access(all)
		fun metadata(): &MutableMetadata.Metadata{ 
			return self.set().getTemplate(self.templateId).metadata()
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return self._contract().getMetadataViewsManagerPublic().getViews()
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let nftRef = &self as &{NiftoryNonFungibleToken.NFTPublic}
			return self._contract().getMetadataViewsManagerPublic().resolveView(view: view, nftRef: nftRef)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(setId: Int, templateId: Int, serial: UInt64){ 
			self.id = BeerRun.totalSupply
			BeerRun.totalSupply = BeerRun.totalSupply + 1
			self.setId = setId
			self.templateId = templateId
			self.serial = serial
		}
	}
	
	// ========================================================================
	// Collection
	// ========================================================================
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, NiftoryNonFungibleToken.CollectionPublic, NiftoryNonFungibleToken.CollectionPrivate{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
			return BeerRun._contract()
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT ".concat(id.toString()).concat(" does not exist in collection.")
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrow(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in collection."
			}
			let nftRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let fullNft = nftRef as! &NFT
			return fullNft as &NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in collection."
			}
			let nftRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let fullNft = nftRef as! &NFT
			return fullNft as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @BeerRun.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun depositBulk(tokens: @[{NonFungibleToken.NFT}]){ 
			while tokens.length > 0{ 
				let token <- tokens.removeLast() as! @BeerRun.NFT
				self.deposit(token: <-token)
			}
			destroy tokens
		}
		
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.ownedNFTs[withdrawID] != nil:
					"NFT ".concat(withdrawID.toString()).concat(" does not exist in collection.")
			}
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun withdrawBulk(withdrawIDs: [UInt64]): @[{NonFungibleToken.NFT}]{ 
			let tokens: @[{NonFungibleToken.NFT}] <- []
			while withdrawIDs.length > 0{ 
				tokens.append(<-self.withdraw(withdrawID: withdrawIDs.removeLast()))
			}
			return <-tokens
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
	
	// ========================================================================
	// Manager
	// ========================================================================
	access(all)
	resource Manager: NiftoryNonFungibleToken.ManagerPublic, NiftoryNonFungibleToken.ManagerPrivate{ 
		access(all)
		fun metadata(): AnyStruct?{ 
			return BeerRun.metadata
		}
		
		access(all)
		fun getSetManagerPublic(): &MutableMetadataSetManager.Manager{ 
			return NiftoryNFTRegistry.getSetManagerPublic(BeerRun.REGISTRY_ADDRESS, BeerRun.REGISTRY_BRAND)
		}
		
		access(all)
		fun getMetadataViewsManagerPublic(): &MetadataViewsManager.Manager{ 
			return NiftoryNFTRegistry.getMetadataViewsManagerPublic(BeerRun.REGISTRY_ADDRESS, BeerRun.REGISTRY_BRAND)
		}
		
		access(all)
		fun getNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return NiftoryNFTRegistry.buildNFTCollectionData(BeerRun.REGISTRY_ADDRESS, BeerRun.REGISTRY_BRAND, fun (): @{NonFungibleToken.Collection}{ 
					return <-BeerRun.createEmptyCollection(nftType: Type<@BeerRun.Collection>())
				})
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(all)
		fun modifyContractMetadata(): &AnyStruct{ 
			return &BeerRun.metadata as &AnyStruct?
		}
		
		access(all)
		fun replaceContractMetadata(_ metadata: AnyStruct?){ 
			BeerRun.metadata = metadata
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getMetadataViewsManagerPrivate(): &MetadataViewsManager.Manager{ 
			let record = NiftoryNFTRegistry.getRegistryRecord(BeerRun.REGISTRY_ADDRESS, BeerRun.REGISTRY_BRAND)
			let manager = (BeerRun.account.capabilities.get<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.private)!).borrow()!
			return manager
		}
		
		access(all)
		fun lockMetadataViewsManager(){ 
			self._getMetadataViewsManagerPrivate().lock()
		}
		
		access(all)
		fun setMetadataViewsResolver(_ resolver:{ MetadataViewsManager.Resolver}){ 
			self._getMetadataViewsManagerPrivate().addResolver(resolver)
		}
		
		access(all)
		fun removeMetadataViewsResolver(_ type: Type){ 
			self._getMetadataViewsManagerPrivate().removeResolver(type)
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getSetManagerPrivate(): &MutableMetadataSetManager.Manager{ 
			let record = NiftoryNFTRegistry.getRegistryRecord(BeerRun.REGISTRY_ADDRESS, BeerRun.REGISTRY_BRAND)
			let setManager = (BeerRun.account.capabilities.get<&MutableMetadataSetManager.Manager>(record.setManager.paths.private)!).borrow()!
			return setManager
		}
		
		access(all)
		fun setMetadataManagerName(_ name: String){ 
			self._getSetManagerPrivate().setName(name)
		}
		
		access(all)
		fun setMetadataManagerDescription(_ description: String){ 
			self._getSetManagerPrivate().setDescription(description)
		}
		
		access(all)
		fun addSet(_ set: @MutableMetadataSet.Set){ 
			self._getSetManagerPrivate().addSet(<-set)
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getSetMutable(_ setId: Int): &MutableMetadataSet.Set{ 
			return self._getSetManagerPrivate().getSetMutable(setId)
		}
		
		access(all)
		fun lockSet(setId: Int){ 
			self._getSetMutable(setId).lock()
		}
		
		access(all)
		fun lockSetMetadata(setId: Int){ 
			self._getSetMutable(setId).metadataMutable().lock()
		}
		
		access(all)
		fun modifySetMetadata(setId: Int): &AnyStruct{ 
			return self._getSetMutable(setId).metadataMutable().getMutable()
		}
		
		access(all)
		fun replaceSetMetadata(setId: Int, new: AnyStruct){ 
			self._getSetMutable(setId).metadataMutable().replace(new)
		}
		
		access(all)
		fun addTemplate(setId: Int, template: @MutableMetadataTemplate.Template){ 
			self._getSetMutable(setId).addTemplate(<-template)
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getTemplateMutable(_ setId: Int, _ templateId: Int): &MutableMetadataTemplate.Template{ 
			return self._getSetMutable(setId).getTemplateMutable(templateId)
		}
		
		access(all)
		fun lockTemplate(setId: Int, templateId: Int){ 
			self._getTemplateMutable(setId, templateId).lock()
		}
		
		access(all)
		fun setTemplateMaxMint(setId: Int, templateId: Int, max: UInt64){ 
			self._getTemplateMutable(setId, templateId).setMaxMint(max)
		}
		
		access(all)
		fun mint(setId: Int, templateId: Int): @{NonFungibleToken.NFT}{ 
			let template = self._getTemplateMutable(setId, templateId)
			template.registerMint()
			let serial = template.minted()
			let nft <- create NFT(setId: setId, templateId: templateId, serial: serial)
			emit NFTMinted(id: nft.id, setId: setId, templateId: templateId, serial: serial)
			return <-nft
		}
		
		access(all)
		fun mintBulk(setId: Int, templateId: Int, numToMint: UInt64): @[{NonFungibleToken.NFT}]{ 
			let template = self._getTemplateMutable(setId, templateId)
			let nfts: @[{NonFungibleToken.NFT}] <- []
			var leftToMint = numToMint
			while leftToMint > 0{ 
				template.registerMint()
				let serial = template.minted()
				let nft <- create NFT(setId: setId, templateId: templateId, serial: serial)
				emit NFTMinted(id: nft.id, setId: setId, templateId: templateId, serial: serial)
				nfts.append(<-nft)
				leftToMint = leftToMint - 1
			}
			return <-nfts
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getNFTMetadata(_ setId: Int, _ templateId: Int): &MutableMetadata.Metadata{ 
			return self._getTemplateMutable(setId, templateId).metadataMutable()
		}
		
		access(all)
		fun lockNFTMetadata(setId: Int, templateId: Int){ 
			self._getNFTMetadata(setId, templateId).lock()
		}
		
		access(all)
		fun modifyNFTMetadata(setId: Int, templateId: Int): &AnyStruct{ 
			return self._getNFTMetadata(setId, templateId).getMutable()
		}
		
		access(all)
		fun replaceNFTMetadata(setId: Int, templateId: Int, new: AnyStruct){ 
			self._getNFTMetadata(setId, templateId).replace(new)
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	access(all)
	view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
		return NiftoryNFTRegistry.getNFTManagerPublic(BeerRun.REGISTRY_ADDRESS, BeerRun.REGISTRY_BRAND)
	}
	
	// ========================================================================
	// Init
	// ========================================================================
	init(nftManagerProxy: &{NiftoryNonFungibleTokenProxy.Public, NiftoryNonFungibleTokenProxy.Private}){ 
		let record = NiftoryNFTRegistry.generateRecord(account: self.account.address, project: "clg8jgjbd0000jw0wzjbnxfa3_BeerRun")
		self.REGISTRY_ADDRESS = 0x32d62d5c43ad1038
		self.REGISTRY_BRAND = "clg8jgjbd0000jw0wzjbnxfa3_BeerRun"
		self.COLLECTION_PUBLIC_PATH = record.collectionPaths.public
		self.COLLECTION_PRIVATE_PATH = record.collectionPaths.private
		self.COLLECTION_STORAGE_PATH = record.collectionPaths.storage
		
		// No metadata to start with
		self.metadata = nil
		
		// Initialize the total supply to 0.
		self.totalSupply = 0
		
		// The Manager for this NFT
		//
		// NFT Manager storage
		let nftManager <- create Manager()
		
		// Save a MutableSetManager to this contract's storage, as the source of
		// this NFT contract's metadata.
		//
		// MutableMetadataSetManager storage
		self.account.storage.save<@MutableMetadataSetManager.Manager>(<-MutableMetadataSetManager._create(name: "BeerRun", description: "The set manager for BeerRun."), to: record.setManager.paths.storage)
		
		// MutableMetadataSetManager public
		var capability_1 = self.account.capabilities.storage.issue<&MutableMetadataSetManager.Manager>(record.setManager.paths.storage)
		self.account.capabilities.publish(capability_1, at: record.setManager.paths.public)
		
		// MutableMetadataSetManager private
		var capability_2 = self.account.capabilities.storage.issue<&MutableMetadataSetManager.Manager>(record.setManager.paths.storage)
		self.account.capabilities.publish(capability_2, at: record.setManager.paths.private)
		
		// Save a MetadataViewsManager to this contract's storage, which will
		// allow observers to inspect standardized metadata through any of its
		// configured MetadataViews resolvers.
		//
		// MetadataViewsManager storage
		self.account.storage.save<@MetadataViewsManager.Manager>(<-MetadataViewsManager._create(), to: record.metadataViewsManager.paths.storage)
		
		// MetadataViewsManager public
		var capability_3 = self.account.capabilities.storage.issue<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.storage)
		self.account.capabilities.publish(capability_3, at: record.metadataViewsManager.paths.public)
		
		// MetadataViewsManager private
		var capability_4 = self.account.capabilities.storage.issue<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.storage)
		self.account.capabilities.publish(capability_4, at: record.metadataViewsManager.paths.private)
		let contractName = "BeerRun"
		
		// Royalties
		let royaltiesResolver = NiftoryMetadataViewsResolvers.RoyaltiesResolver(royalties: MetadataViews.Royalties([]))
		nftManager.setMetadataViewsResolver(royaltiesResolver)
		
		// Collection Data
		let collectionDataResolver = NiftoryMetadataViewsResolvers.NFTCollectionDataResolver()
		nftManager.setMetadataViewsResolver(collectionDataResolver)
		
		// Display
		let displayResolver = NiftoryMetadataViewsResolvers.DisplayResolver(nameField: "title", defaultName: contractName.concat("NFT"), descriptionField: "description", defaultDescription: contractName.concat(" NFT"), imageField: "mediaUrl", defaultImagePrefix: "ipfs://", defaultImage: "ipfs://bafybeig6la3me5x3veull7jzxmwle4sfuaguou2is3o3z44ayhe7ihlqpa/NiftoryBanner.png")
		nftManager.setMetadataViewsResolver(displayResolver)
		
		// Collection Display
		let collectionResolver = NiftoryMetadataViewsResolvers.NFTCollectionDisplayResolver(nameField: "title", defaultName: contractName, descriptionField: "description", defaultDescription: contractName.concat(" Collection"), externalUrlField: "domainUrl", defaultExternalURLPrefix: "https://", defaultExternalURL: "https://niftory.com", squareImageField: "squareImage", defaultSquareImagePrefix: "ipfs://", defaultSquareImage: "ipfs://bafybeihc76uodw2at2xi2l5jydpvscj5ophfpqgblbrmsfpeffhcmgdtl4/squareImage.png", squareImageMediaTypeField: "squareImageMediaType", defaultSquareImageMediaType: "image/png", bannerImageField: "bannerImage", defaultBannerImagePrefix: "ipfs://", defaultBannerImage: "ipfs://bafybeig6la3me5x3veull7jzxmwle4sfuaguou2is3o3z44ayhe7ihlqpa/NiftoryBanner.png", bannerImageMediaTypeField: "bannerImageMediaType", defaultBannerImageMediaType: "image/png", socialsFields: [])
		nftManager.setMetadataViewsResolver(collectionResolver)
		
		// ExternalURL
		let externalURLResolver = NiftoryMetadataViewsResolvers.ExternalURLResolver(field: "domainUrl", defaultPrefix: "https://", defaultURL: "https://niftory.com")
		nftManager.setMetadataViewsResolver(externalURLResolver)
		
		// Save NFT Manager
		self.account.storage.save<@Manager>(<-nftManager, to: record.nftManager.paths.storage)
		
		// NFT Manager public
		var capability_5 = self.account.capabilities.storage.issue<&{NiftoryNonFungibleToken.ManagerPublic}>(record.nftManager.paths.storage)
		self.account.capabilities.publish(capability_5, at: record.nftManager.paths.public)
		
		// NFT Manager private
		var capability_6 = self.account.capabilities.storage.issue<&Manager>(record.nftManager.paths.storage)
		self.account.capabilities.publish(capability_6, at: record.nftManager.paths.private)
		nftManagerProxy.add(registryAddress: self.REGISTRY_ADDRESS, brand: self.REGISTRY_BRAND, cap: self.account.capabilities.get<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>(record.nftManager.paths.private)!)
	}
}
