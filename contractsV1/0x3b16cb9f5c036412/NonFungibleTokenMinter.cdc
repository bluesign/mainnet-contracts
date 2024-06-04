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
contract interface NonFungibleTokenMinter{ 
	access(all)
	event Minted(to: Address, id: UInt64, metadata:{ String: String})
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface MinterProvider{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(
			id: UInt64,
			recipient: &{NonFungibleToken.CollectionPublic},
			metadata:{ 
				String: String
			}
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface NFTMinter: MinterProvider{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String})
	}
}
