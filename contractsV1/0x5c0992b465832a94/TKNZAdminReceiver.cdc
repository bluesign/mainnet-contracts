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

	// Deployed for TKNZ Ltd. - https://tknz.gg
/*

  AdminReceiver.cdc

  This contract defines a function that takes a TKNZ Admin
  object and stores it in the storage of the contract account
  so it can be used.

 */

import TKNZ from "./TKNZ.cdc"

access(all)
contract TKNZAdminReceiver{ 
	
	// storeAdmin takes a TKNZ Admin resource and 
	// saves it to the account storage of the account
	// where the contract is deployed
	access(TMP_ENTITLEMENT_OWNER)
	fun storeAdmin(newAdmin: @TKNZ.Admin){ 
		self.account.storage.save(<-newAdmin, to: /storage/TKNZAdmin)
	}
	
	init(){} 
}
