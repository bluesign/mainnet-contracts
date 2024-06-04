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
contract Log{ 
	access(self)
	var n:{ String: String}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun contains(_ k: String): Bool{ 
		return self.n.containsKey(k)
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun n(): &{String: String}{ 
			return &Log.n as &{String: String}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun s(_ k: String, _ v: String){ 
			Log.n[k] = v
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun c(){ 
			Log.n ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun c(): @Admin{ 
		return <-create Admin()
	}
	
	init(){ 
		self.n ={} 
	}
}
