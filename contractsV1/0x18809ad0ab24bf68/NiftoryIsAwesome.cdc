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
NiftoryIsAwesome

This is the contract for NiftoryIsAwesome NFTs! 

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

access(all)
contract NiftoryIsAwesome: NonFungibleToken{ 
	
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
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, NiftoryNonFungibleToken.NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setId: Int
		
		access(all)
		let templateId: Int
		
		access(all)
		let serial: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
			return NiftoryIsAwesome._contract()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun set(): &MutableMetadataSet.Set{ 
			return self._contract().getSetManagerPublic().getSet(self.setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
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
			self.id = NiftoryIsAwesome.totalSupply
			NiftoryIsAwesome.totalSupply = NiftoryIsAwesome.totalSupply + 1
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
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
			return NiftoryIsAwesome._contract()
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
		
		access(TMP_ENTITLEMENT_OWNER)
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
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @NiftoryIsAwesome.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositBulk(tokens: @[{NonFungibleToken.NFT}]){ 
			while tokens.length > 0{ 
				let token <- tokens.removeLast() as! @NiftoryIsAwesome.NFT
				self.deposit(token: <-token)
			}
			destroy tokens
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.ownedNFTs[withdrawID] != nil:
					"NFT ".concat(withdrawID.toString()).concat(" does not exist in collection.")
			}
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawBulk(withdrawIDs: [UInt64]): @[{NonFungibleToken.NFT}]{ 
			let tokens: @[{NonFungibleToken.NFT}] <- []
			while withdrawIDs.length > 0{ 
				tokens.append(<-self.withdraw(withdrawID: withdrawIDs.removeLast()))
			}
			return <-tokens
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
	
	// ========================================================================
	// Manager
	// ========================================================================
	access(all)
	resource Manager: NiftoryNonFungibleToken.ManagerPublic, NiftoryNonFungibleToken.ManagerPrivate{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): AnyStruct?{ 
			return NiftoryIsAwesome.metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetManagerPublic(): &MutableMetadataSetManager.Manager{ 
			return NiftoryNFTRegistry.getSetManagerPublic(NiftoryIsAwesome.REGISTRY_ADDRESS, NiftoryIsAwesome.REGISTRY_BRAND)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadataViewsManagerPublic(): &MetadataViewsManager.Manager{ 
			return NiftoryNFTRegistry.getMetadataViewsManagerPublic(NiftoryIsAwesome.REGISTRY_ADDRESS, NiftoryIsAwesome.REGISTRY_BRAND)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return NiftoryNFTRegistry.buildNFTCollectionData(NiftoryIsAwesome.REGISTRY_ADDRESS, NiftoryIsAwesome.REGISTRY_BRAND, fun (): @{NonFungibleToken.Collection}{ 
					return <-NiftoryIsAwesome.createEmptyCollection(nftType: Type<@NiftoryIsAwesome.Collection>())
				})
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(TMP_ENTITLEMENT_OWNER)
		fun modifyContractMetadata(): &AnyStruct{ 
			return &NiftoryIsAwesome.metadata as &AnyStruct?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceContractMetadata(_ metadata: AnyStruct?){ 
			NiftoryIsAwesome.metadata = metadata
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getMetadataViewsManagerPrivate(): &MetadataViewsManager.Manager{ 
			let record = NiftoryNFTRegistry.getRegistryRecord(NiftoryIsAwesome.REGISTRY_ADDRESS, NiftoryIsAwesome.REGISTRY_BRAND)
			let manager = NiftoryIsAwesome.account.capabilities.get<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.private).borrow()!
			return manager
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockMetadataViewsManager(){ 
			self._getMetadataViewsManagerPrivate().lock()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataViewsResolver(_ resolver:{ MetadataViewsManager.Resolver}){ 
			self._getMetadataViewsManagerPrivate().addResolver(resolver)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMetadataViewsResolver(_ type: Type){ 
			self._getMetadataViewsManagerPrivate().removeResolver(type)
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getSetManagerPrivate(): &MutableMetadataSetManager.Manager{ 
			let record = NiftoryNFTRegistry.getRegistryRecord(NiftoryIsAwesome.REGISTRY_ADDRESS, NiftoryIsAwesome.REGISTRY_BRAND)
			let setManager = NiftoryIsAwesome.account.capabilities.get<&MutableMetadataSetManager.Manager>(record.setManager.paths.private).borrow()!
			return setManager
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataManagerName(_ name: String){ 
			self._getSetManagerPrivate().setName(name)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataManagerDescription(_ description: String){ 
			self._getSetManagerPrivate().setDescription(description)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSet(_ set: @MutableMetadataSet.Set){ 
			self._getSetManagerPrivate().addSet(<-set)
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getSetMutable(_ setId: Int): &MutableMetadataSet.Set{ 
			return self._getSetManagerPrivate().getSetMutable(setId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockSet(setId: Int){ 
			self._getSetMutable(setId).lock()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockSetMetadata(setId: Int){ 
			self._getSetMutable(setId).metadataMutable().lock()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun modifySetMetadata(setId: Int): &AnyStruct{ 
			return self._getSetMutable(setId).metadataMutable().getMutable()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceSetMetadata(setId: Int, new: AnyStruct){ 
			self._getSetMutable(setId).metadataMutable().replace(new)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addTemplate(setId: Int, template: @MutableMetadataTemplate.Template){ 
			self._getSetMutable(setId).addTemplate(<-template)
		}
		
		////////////////////////////////////////////////////////////////////////////
		access(self)
		fun _getTemplateMutable(_ setId: Int, _ templateId: Int): &MutableMetadataTemplate.Template{ 
			return self._getSetMutable(setId).getTemplateMutable(templateId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockTemplate(setId: Int, templateId: Int){ 
			self._getTemplateMutable(setId, templateId).lock()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setTemplateMaxMint(setId: Int, templateId: Int, max: UInt64){ 
			self._getTemplateMutable(setId, templateId).setMaxMint(max)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(setId: Int, templateId: Int): @{NonFungibleToken.NFT}{ 
			let template = self._getTemplateMutable(setId, templateId)
			template.registerMint()
			let serial = template.minted()
			let nft <- create NFT(setId: setId, templateId: templateId, serial: serial)
			emit NFTMinted(id: nft.id, setId: setId, templateId: templateId, serial: serial)
			return <-nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
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
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockNFTMetadata(setId: Int, templateId: Int){ 
			self._getNFTMetadata(setId, templateId).lock()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun modifyNFTMetadata(setId: Int, templateId: Int): &AnyStruct{ 
			return self._getNFTMetadata(setId, templateId).getMutable()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceNFTMetadata(setId: Int, templateId: Int, new: AnyStruct){ 
			self._getNFTMetadata(setId, templateId).replace(new)
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	access(TMP_ENTITLEMENT_OWNER)
	view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
		return NiftoryNFTRegistry.getNFTManagerPublic(NiftoryIsAwesome.REGISTRY_ADDRESS, NiftoryIsAwesome.REGISTRY_BRAND)
	}
	
	// ========================================================================
	// Init
	// ========================================================================
	init(){ 
		let record = NiftoryNFTRegistry.generateRecord(account: self.account.address, project: "cl98uicmo00010hjp859ymyrl_NiftoryIsAwesome")
		self.REGISTRY_ADDRESS = 0x32d62d5c43ad1038
		self.REGISTRY_BRAND = "cl98uicmo00010hjp859ymyrl_NiftoryIsAwesome"
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
		self.account.storage.save<@Manager>(<-create Manager(), to: record.nftManager.paths.storage)
		
		// NFT Manager public
		var capability_1 = self.account.capabilities.storage.issue<&{NiftoryNonFungibleToken.ManagerPublic}>(record.nftManager.paths.storage)
		self.account.capabilities.publish(capability_1, at: record.nftManager.paths.public)
		
		// NFT Manager private
		var capability_2 = self.account.capabilities.storage.issue<&Manager>(record.nftManager.paths.storage)
		self.account.capabilities.publish(capability_2, at: record.nftManager.paths.private)
		
		// Save a MutableSetManager to this contract's storage, as the source of
		// this NFT contract's metadata.
		//
		// MutableMetadataSetManager storage
		self.account.storage.save<@MutableMetadataSetManager.Manager>(<-MutableMetadataSetManager._create(name: "NiftoryIsAwesome", description: "The set manager for NiftoryIsAwesome."), to: record.setManager.paths.storage)
		
		// MutableMetadataSetManager public
		var capability_3 = self.account.capabilities.storage.issue<&MutableMetadataSetManager.Manager>(record.setManager.paths.storage)
		self.account.capabilities.publish(capability_3, at: record.setManager.paths.public)
		
		// MutableMetadataSetManager private
		var capability_4 = self.account.capabilities.storage.issue<&MutableMetadataSetManager.Manager>(record.setManager.paths.storage)
		self.account.capabilities.publish(capability_4, at: record.setManager.paths.private)
		
		// Save a MetadataViewsManager to this contract's storage, which will
		// allow observers to inspect standardized metadata through any of its
		// configured MetadataViews resolvers.
		//
		// MetadataViewsManager storage
		self.account.storage.save<@MetadataViewsManager.Manager>(<-MetadataViewsManager._create(), to: record.metadataViewsManager.paths.storage)
		
		// MetadataViewsManager public
		var capability_5 = self.account.capabilities.storage.issue<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.storage)
		self.account.capabilities.publish(capability_5, at: record.metadataViewsManager.paths.public)
		
		// MetadataViewsManager private
		var capability_6 = self.account.capabilities.storage.issue<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.storage)
		self.account.capabilities.publish(capability_6, at: record.metadataViewsManager.paths.private)
	}
}
