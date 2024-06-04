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

	access(all)
contract EventLogger{ 
	access(all)
	event Success(id: UInt64, dapp: String)
	
	access(all)
	event Failure(id: UInt64, dapp: String, reason: String)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun logSuccess(id: UInt64, dapp: String){ 
		emit Success(id: id, dapp: dapp)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun logFailure(id: UInt64, dapp: String, reason: String){ 
		emit Failure(id: id, dapp: dapp, reason: reason)
	}
}
