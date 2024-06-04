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
contract MotoGPAdmin{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "1.0.1"
	}
	
	access(all)
	resource Admin{ 
		// createAdmin
		// only an admin can ever create
		// a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.account.storage.save(<-create Admin(), to: /storage/motogpAdmin)
	}
}
