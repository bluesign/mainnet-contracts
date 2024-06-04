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
contract Metabolism{ 
	access(all)
	resource Cell{ 
		access(all)
		var is_dead: Bool
		
		init(){ 
			self.is_dead = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun kill(): @Cell{ 
			self.is_dead = true
			return <-create Cell()
		}
	}
	
	init(){ 
		self.account.storage.save(<-create Cell(), to: /storage/MetabolismCell)
	}
}
