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

	// TiblesNFT.cdc
access(TMP_ENTITLEMENT_OWNER)
contract interface TiblesNFT{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let PublicCollectionPath: PublicPath
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface INFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mintNumber: UInt32
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata():{ String: AnyStruct}?
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun depositTible(tible: @{TiblesNFT.INFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowTible(id: UInt64): &{TiblesNFT.INFT}
	}
}
