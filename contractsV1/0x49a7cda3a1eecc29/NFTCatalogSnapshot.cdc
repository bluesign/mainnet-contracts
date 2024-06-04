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

	// NFTCatalogSnapshot
//
// A snapshot of the NFT Catalog at a specific time.
// This is provided in order to provide post-deprecation
// support to the NFT Catalog `getCatalog` function.
// which has been deprecated because it is nearing
// execution limits when copied and used within a 
// script or transaction.
// https://github.com/dapperlabs/nft-catalog/issues/138
// 
access(all)
contract NFTCatalogSnapshot{ 
	access(self)
	var catalogSnapshot:{ String: AnyStruct}?
	
	access(all)
	var snapshotBlockHeight: UInt64?
	
	access(account)
	fun setSnapshot(_ snapshot:{ String: AnyStruct}){ 
		self.catalogSnapshot = snapshot
		self.snapshotBlockHeight = getCurrentBlock().height
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCatalogSnapshot():{ String: AnyStruct}?{ 
		return self.catalogSnapshot
	}
	
	init(){ 
		self.snapshotBlockHeight = nil
		self.catalogSnapshot = nil
	}
}
