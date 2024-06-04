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

access(TMP_ENTITLEMENT_OWNER)
contract interface Interfaces{ 
	
	// ARTIFACTAdminOpener is a interface resource used to
	// to open pack from a user wallet
	// 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface ARTIFACTAdminOpener{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(
			userPack: &{IPack},
			packID: UInt64,
			owner: Address,
			royalties: [
				MetadataViews.Royalty
			],
			packOption:{ IPackOption}?
		): @[{
			NonFungibleToken.NFT}
		]
	}
	
	// Resource interface to pack  
	// 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IPack{ 
		access(all)
		let id: UInt64
		
		access(all)
		var isOpen: Bool
		
		access(all)
		let templateId: UInt64
	}
	
	// Struct interface to pack template 
	// 
	access(TMP_ENTITLEMENT_OWNER)
	struct interface IPackTemplate{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let totalSupply: UInt64
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	struct interface IHashMetadata{ 
		access(all)
		let hash: String
		
		access(all)
		let start: UInt64
		
		access(all)
		let end: UInt64
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	struct interface IPackOption{ 
		access(all)
		let options: [String]
		
		access(all)
		let hash:{ IHashMetadata}
	}
}
