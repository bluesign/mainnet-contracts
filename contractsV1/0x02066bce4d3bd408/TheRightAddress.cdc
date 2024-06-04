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

	import AFLPack from "../0x8f9231920da9af6d/AFLPack.cdc"

access(all)
contract TheRightAddress{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun updateAddress(managerRef: &AFLPack.Pack){ 
		managerRef.updateOwnerAddress(owner: 0x02066bce4d3bd408)
	}
	
	init(){} 
}
