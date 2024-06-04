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

	import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TheFabricantMetadataViewsV2 from "./TheFabricantMetadataViewsV2.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface TheFabricantNFTStandardV2{ 
	access(contract)
	var nftIdsToOwner:{ UInt64: Address}
	
	// -----------------------------------------------------------------------
	// NFT Interface
	// -----------------------------------------------------------------------
	// Season
	// Collection
	// metadata
	// standards
	// We should have a set of scripts and txs that work for all nfts
	// We want to be able to get the nftIdsToOwner
	// Must be user mintable and admin mintable
	// NOTE: The TFNFT interface describes the bare minimum that
	// a TF NFT should implement to be considered as such. It specifies
	// functions as opposed to properties to avoid being prescriptive.
	access(TMP_ENTITLEMENT_OWNER)
	resource interface TFNFT{ 
		// NFT View
		// Display
		// Edition
		// Serial
		// Royalty
		// Media
		// License
		// ExternalURL
		// NFTCollectionData
		// NFTCollectionDisplay
		// Rarity
		// Trait
		
		// The id is likely to also be the edition number of the NFT in the collection
		access(all)
		let id: UInt64
		
		// NOTE: name, description and collection are not included because they may be
		// derived from the RevealableMetadata.
		// NOTE: UUID is a property on all resources so a reserved keyword.
		//pub let uuid: UInt64 //Display, Serial, 
		access(contract)
		let collectionId: String
		
		// id and editionNumber might not be the same in the nft...
		access(contract)
		let editionNumber: UInt64 //Edition
		
		
		access(contract)
		let maxEditionNumber: UInt64?
		
		access(contract)
		let originalRecipient: Address
		
		access(contract)
		let license: MetadataViews.License? //License
		
		
		// NFTs have a name prop and an edition number prop.
		// the name prop is usually just the last node in the 
		// collection name eg XXories Original.
		// The edition number is the number the NFT is in the series.
		// getFullName() returns the name + editionNumber
		// eg XXories Original #4
		access(TMP_ENTITLEMENT_OWNER)
		fun getFullName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEditionName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEditions(): MetadataViews.Editions
		
		// NOTE: Refer to RevealableV2 interface. Each campaign might have a 
		// different number of images/videos for its nfts. Enforcing
		// MetadataViews.Medias in the nft would make it un-RevealableV2,
		// as .Medias is immutable. Thus, this function should be used
		// to collect the media assets into a .Medias struct.
		access(TMP_ENTITLEMENT_OWNER)
		fun getMedias(): MetadataViews.Medias
		
		// Helper function for TF use to get images
		// {"mainImage": "imageURL", "imageTwo": "imageURL"}
		access(TMP_ENTITLEMENT_OWNER)
		fun getImages():{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVideos():{ String: String}
		
		// NOTE: This returns the traits that will be shown in marketplaces,
		// on dApps etc. We don't have a traits property to afford
		// flexibility to the implementation. The implementor might
		// want to have a 'revealable' trait for example,
		// and MetadataViews.Traits is immutable so not compatible.
		access(TMP_ENTITLEMENT_OWNER)
		fun getTraits(): MetadataViews.Traits?
		
		// NOTE: Same as above, rarity might be revealed.
		access(TMP_ENTITLEMENT_OWNER)
		fun getRarity(): MetadataViews.Rarity?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExternalRoyalties(): MetadataViews.Royalties
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDisplay(): MetadataViews.Display
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionData(): MetadataViews.NFTCollectionData
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTView(): MetadataViews.NFTView
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getViews(): [Type]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface TFRoyalties{ 
		access(all)
		let royalties: MetadataViews.Royalties //Royalty
		
		
		access(all)
		let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
	}
	
	// Used to expose the public mint function so that users can mint
	access(TMP_ENTITLEMENT_OWNER)
	resource interface TFNFTPublicMinter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getPublicMinterDetails():{ String: AnyStruct}
	}
}
