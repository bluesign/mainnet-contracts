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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import CollecticoStandardNFT from "./CollecticoStandardNFT.cdc"

/*
	Collectico Views for Basic NFTs
	(c) CollecticoLabs.com
 */

access(all)
contract CollecticoStandardViews{ 
	access(all)
	resource interface NFTViewResolver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getViewType(): Type
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canResolveView(_ nft: &{NonFungibleToken.NFT}): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(_ nft: &{NonFungibleToken.NFT}): AnyStruct?
	}
	
	access(all)
	resource interface ItemViewResolver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getViewType(): Type
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canResolveView(_ item: &{CollecticoStandardNFT.Item}): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(_ item: &{CollecticoStandardNFT.Item}): AnyStruct?
	}
	
	access(all)
	struct ContractInfo{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		init(name: String, address: Address){ 
			self.name = name
			self.address = address
		}
	}
	
	// A helper to get ContractInfo in a typesafe way
	access(TMP_ENTITLEMENT_OWNER)
	fun getContractInfo(_ viewResolver: &{ViewResolver.Resolver}): ContractInfo?{ 
		if let view = viewResolver.resolveView(Type<ContractInfo>()){ 
			if let v = view as? ContractInfo{ 
				return v
			}
		}
		return nil
	}
	
	access(all)
	struct ItemView{ 
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
		let totalSupply: UInt64
		
		access(all)
		let maxSupply: UInt64?
		
		access(all)
		let isLocked: Bool
		
		access(all)
		let isTransferable: Bool
		
		access(all)
		let contractInfo: ContractInfo?
		
		access(all)
		let collectionDisplay: MetadataViews.NFTCollectionDisplay?
		
		access(all)
		let royalties: MetadataViews.Royalties?
		
		access(all)
		let display: MetadataViews.Display?
		
		access(all)
		let traits: MetadataViews.Traits?
		
		access(all)
		let medias: MetadataViews.Medias?
		
		access(all)
		let license: MetadataViews.License?
		
		init(
			id: UInt64,
			name: String,
			description: String,
			thumbnail:{ MetadataViews.File},
			metadata:{ 
				String: AnyStruct
			}?,
			totalSupply: UInt64,
			maxSupply: UInt64?,
			isLocked: Bool,
			isTransferable: Bool,
			contractInfo: ContractInfo?,
			collectionDisplay: MetadataViews.NFTCollectionDisplay?,
			royalties: MetadataViews.Royalties?,
			display: MetadataViews.Display?,
			traits: MetadataViews.Traits?,
			medias: MetadataViews.Medias?,
			license: MetadataViews.License?
		){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
			self.totalSupply = totalSupply
			self.maxSupply = maxSupply
			self.isLocked = isLocked
			self.isTransferable = isTransferable
			self.contractInfo = contractInfo
			self.collectionDisplay = collectionDisplay
			self.royalties = royalties
			self.display = display
			self.traits = traits
			self.medias = medias
			self.license = license
		}
	}
	
	// A helper to get ItemView in a typesafe way
	access(TMP_ENTITLEMENT_OWNER)
	fun getItemView(_ viewResolver: &{ViewResolver.Resolver}): ItemView?{ 
		if let view = viewResolver.resolveView(Type<ItemView>()){ 
			if let v = view as? ItemView{ 
				return v
			}
		}
		return nil
	}
	
	access(all)
	struct NFTView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemId: UInt64
		
		access(all)
		let itemName: String
		
		access(all)
		let itemDescription: String
		
		access(all)
		let itemThumbnail:{ MetadataViews.File}
		
		access(all)
		let itemMetadata:{ String: AnyStruct}?
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		access(all)
		let itemTotalSupply: UInt64
		
		access(all)
		let itemMaxSupply: UInt64?
		
		access(all)
		let isTransferable: Bool
		
		access(all)
		let contractInfo: ContractInfo?
		
		access(all)
		let collectionDisplay: MetadataViews.NFTCollectionDisplay?
		
		access(all)
		let royalties: MetadataViews.Royalties?
		
		access(all)
		let display: MetadataViews.Display?
		
		access(all)
		let traits: MetadataViews.Traits?
		
		access(all)
		let editions: MetadataViews.Editions?
		
		access(all)
		let medias: MetadataViews.Medias?
		
		access(all)
		let license: MetadataViews.License?
		
		init(
			id: UInt64,
			itemId: UInt64,
			itemName: String,
			itemDescription: String,
			itemThumbnail:{ MetadataViews.File},
			itemMetadata:{ 
				String: AnyStruct
			}?,
			serialNumber: UInt64,
			metadata:{ 
				String: AnyStruct
			}?,
			itemTotalSupply: UInt64,
			itemMaxSupply: UInt64?,
			isTransferable: Bool,
			contractInfo: ContractInfo?,
			collectionDisplay: MetadataViews.NFTCollectionDisplay?,
			royalties: MetadataViews.Royalties?,
			display: MetadataViews.Display?,
			traits: MetadataViews.Traits?,
			editions: MetadataViews.Editions?,
			medias: MetadataViews.Medias?,
			license: MetadataViews.License?
		){ 
			self.id = id
			self.itemId = itemId
			self.itemName = itemName
			self.itemDescription = itemDescription
			self.itemThumbnail = itemThumbnail
			self.itemMetadata = itemMetadata
			self.serialNumber = serialNumber
			self.metadata = metadata
			self.itemTotalSupply = itemTotalSupply
			self.itemMaxSupply = itemMaxSupply
			self.isTransferable = isTransferable
			self.contractInfo = contractInfo
			self.collectionDisplay = collectionDisplay
			self.royalties = royalties
			self.display = display
			self.traits = traits
			self.editions = editions
			self.medias = medias
			self.license = license
		}
	}
	
	// A helper to get NFTView in a typesafe way
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTView(_ viewResolver: &{ViewResolver.Resolver}): NFTView?{ 
		if let view = viewResolver.resolveView(Type<NFTView>()){ 
			if let v = view as? NFTView{ 
				return v
			}
		}
		return nil
	}
}
