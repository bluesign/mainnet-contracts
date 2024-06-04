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
NiftoryNonFungibleToken

Niftory is a platform to design, manage, and launch NFT experiments and
experiences. This contract defines what those NFTs look like.

In order to provide NFT brand admins maximum customizability, Niftory NFTs offer
the following features

- Mutatable metadata for NFTs via Niftory's MutableMetadata suite of contracts.
  Admins can continue to modify NFTs even after they are minted, or they can
  decide to lock the metadata for a particular NFT or set of NFTs to provide
  immutability guarantees

- Conformance to NFT metadata standards with customizable resolvers. The Flow
  team and community have provided standards for NFTs to implement so third
  party applications can access metadata for any NFT, regardless of how it was
  implemented. Niftory NFTs use MetadataViewsmMnager so admins can customize how
  NFTs are viewed by these applications, up until they decide to lock it.

- Common interfaces for minting and information. This enables separately managed
  code to refer to Niftory NFTs agnostically from the actual Niftory NFT
  implementation (e.g. No need to import an NFT contract directly, you just need
  to know what path and which address the minting/info/etc. capabilities are
  located)

- Common interface for collections, which allows bulk withdrawal/deposits

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MutableMetadata from "./MutableMetadata.cdc"

import MutableMetadataTemplate from "./MutableMetadataTemplate.cdc"

import MutableMetadataSet from "./MutableMetadataSet.cdc"

import MutableMetadataSetManager from "./MutableMetadataSetManager.cdc"

import MetadataViewsManager from "./MetadataViewsManager.cdc"

access(all)
contract NiftoryNonFungibleToken{ 
	
	// ========================================================================
	// NFTPublic
	// ========================================================================
	
	// All Niftory NFTs should implement NFTPublic.
	access(all)
	resource interface NFTPublic{ 
		
		// Unique ID of the NFT
		access(all)
		let id: UInt64
		
		// ID of set this NFT belongs to
		access(all)
		let setId: Int
		
		// ID of template within the set
		access(all)
		let templateId: Int
		
		// Serial number of the NFT. If multiple NFTs are meant to represent the
		// exact same 'entity' or set of metadata, then serial number should be used
		// to distinguish them. This will likely always be 1 for PFPs.
		access(all)
		let serial: UInt64
		
		// Contract public information
		access(TMP_ENTITLEMENT_OWNER)
		fun _contract(): &{ManagerPublic}
		
		// All Niftory NFTs belong to exactly one set. This function should return
		// that set
		access(TMP_ENTITLEMENT_OWNER)
		fun set(): &MutableMetadataSet.Set
		
		// This NFTs metadata as a MutableMetadata object.
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): &MutableMetadata.Metadata
		
		// From MetadataViews
		access(TMP_ENTITLEMENT_OWNER)
		fun getViews(): [Type]
		
		// From MetadataViews
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	// ========================================================================
	// Collection interfaces
	// ========================================================================
	// Public
	access(all)
	resource interface CollectionPublic{ 
		
		// Contract public information
		access(TMP_ENTITLEMENT_OWNER)
		fun _contract(): &{ManagerPublic}
		
		// Inherited from NonFungibleToken.Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		// Inherited from MetadataViews.Resolver
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}
		
		// An optimized version of deposit for doing bulk NFT deposits into
		// a collection
		access(TMP_ENTITLEMENT_OWNER)
		fun depositBulk(tokens: @[{NonFungibleToken.NFT}])
		
		// Similar to borrowNFT, but with additional functionality from NFTPublic
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(id: UInt64): &{NFTPublic}
	}
	
	// Private
	access(all)
	resource interface CollectionPrivate{ 
		
		// Inherited from NonFungibleToken.Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		// An optimized version of withdraw for doing bulk NFT withdrawals from
		// a collection
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawBulk(withdrawIDs: [UInt64]): @[{NonFungibleToken.NFT}]
	}
	
	// ========================================================================
	// Manager interfaces
	// ========================================================================
	// A Niftory NFT Manager is responsible for providing interfaces into the NFT
	// contract itself. The two basic functions are to either provide information
	// about the contract or do minting (if authorized)
	access(all)
	resource interface ManagerPublic{ 
		
		// Get arbitrary metadata for this NFT contract, if implemented
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): AnyStruct?
		
		// For convenience and transparency, return the MutableSetManager this
		// contract's NFTs are gettting their metadata from
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetManagerPublic(): &MutableMetadataSetManager.Manager
		
		// For convenience and transparency, return the MetadataViewsManager this
		// contract's NFTs are gettting their metadata from
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadataViewsManagerPublic(): &MetadataViewsManager.Manager
		
		// In order to expose collection features in an NFT agnostic way
		// (i.e. without having to import the actual NFT contract explicitly)
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTCollectionData(): MetadataViews.NFTCollectionData
	}
	
	access(all)
	resource interface ManagerPrivate{ 
		
		// ========================================================================
		// Contract metadata
		// ========================================================================
		
		// Set arbitrary metadata for this NFT contract, if implemented
		access(TMP_ENTITLEMENT_OWNER)
		fun modifyContractMetadata(): &AnyStruct
		
		// Set arbitrary metadata for this NFT contract, if implemented
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceContractMetadata(_ metadata: AnyStruct?)
		
		// ========================================================================
		// Metadata Views Manager
		// ========================================================================
		// Lock MetadataViewsResolver so that resolvers can be neither added nor
		// removed
		access(TMP_ENTITLEMENT_OWNER)
		fun lockMetadataViewsManager()
		
		// Add the given resolver to the MetadataViewsResolver if not locked
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataViewsResolver(_ resolver:{ MetadataViewsManager.Resolver})
		
		// Remove the given resolver from the MetadataViewsResolver if not locked
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMetadataViewsResolver(_ type: Type)
		
		// ========================================================================
		// Set Manager
		// ========================================================================
		// Set the name of the set manager
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataManagerName(_ name: String)
		
		// Set the description of the set manager
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataManagerDescription(_ description: String)
		
		// Add a set to the set manager
		access(TMP_ENTITLEMENT_OWNER)
		fun addSet(_ set: @MutableMetadataSet.Set)
		
		// ========================================================================
		// Set
		// ========================================================================
		// Lock the set so new templates cannot be added
		access(TMP_ENTITLEMENT_OWNER)
		fun lockSet(setId: Int)
		
		// Lock the ability to modify the set metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun lockSetMetadata(setId: Int)
		
		// Retrieve a modifiable version of the underyling set metadata, only if the
		// metadata has not been locked.
		access(TMP_ENTITLEMENT_OWNER)
		fun modifySetMetadata(setId: Int): &AnyStruct
		
		// Replace the metadata for a set
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceSetMetadata(setId: Int, new: AnyStruct)
		
		// Add a new template to set setId
		access(TMP_ENTITLEMENT_OWNER)
		fun addTemplate(setId: Int, template: @MutableMetadataTemplate.Template)
		
		// ========================================================================
		// Minting
		// ========================================================================
		// Lock the template from minting new NFTs
		access(TMP_ENTITLEMENT_OWNER)
		fun lockTemplate(setId: Int, templateId: Int)
		
		// Set maximum number of NFTs that can be minted from this template
		access(TMP_ENTITLEMENT_OWNER)
		fun setTemplateMaxMint(setId: Int, templateId: Int, max: UInt64)
		
		// Construct an NFT from the given set and template IDs
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(setId: Int, templateId: Int): @{NonFungibleToken.NFT}
		
		// Same as mint from above, but an optimized version to do bulk mints.
		access(TMP_ENTITLEMENT_OWNER)
		fun mintBulk(setId: Int, templateId: Int, numToMint: UInt64): @[{NonFungibleToken.NFT}]
		
		// ========================================================================
		// NFT metadata
		// ========================================================================
		// Lock the metadata for a given template
		access(TMP_ENTITLEMENT_OWNER)
		fun lockNFTMetadata(setId: Int, templateId: Int)
		
		// Get a mutable reference to the metadata for a given template
		access(TMP_ENTITLEMENT_OWNER)
		fun modifyNFTMetadata(setId: Int, templateId: Int): &AnyStruct
		
		// Replace the metadata for a given template
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceNFTMetadata(setId: Int, templateId: Int, new: AnyStruct)
	}
}
