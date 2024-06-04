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
contract Foo{ 
	access(all)
	resource Vault{} 
	
	access(all)
	var temp: @Vault?
	
	init(){ 
		self.temp <- nil
	}
	
	access(all)
	fun doubler(): @Vault{ 
		destroy <-create R()
		var doubled <- self.temp <- nil
		return <-doubled!
	}
	
	access(all)
	resource R{ 
		access(all)
		var bounty: @Vault
		
		access(all)
		var dummy: @Vault
		
		init(){ 
			self.bounty <- create Vault()
			self.dummy <- create Vault()
		}
		
		access(all)
		fun swap(){ 
			self.bounty <-> self.dummy
		}
	}
}
