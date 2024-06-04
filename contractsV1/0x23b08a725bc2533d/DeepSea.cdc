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
contract DeepSea{ 
	access(all)
	resource Deep{ 
		access(all)
		var mystery: @AnyResource?
		
		init(_ depth: Int){ 
			if depth > 1000{ 
				self.mystery <- nil
			} else if depth == Int(revertibleRandom() % 400 + 100){ 
				self.mystery <- create Coelacanth()
			} else{ 
				self.mystery <- create Deep(depth + 1)
			}
		}
	}
	
	access(all)
	resource Coelacanth{} 
	
	access(TMP_ENTITLEMENT_OWNER)
	fun dive(): @Deep{ 
		return <-create Deep(0)
	}
}
