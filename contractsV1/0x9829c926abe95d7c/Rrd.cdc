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
contract Rrd{ 
	access(all)
	resource interface RR{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun h(_ n: UInt256): Bool
	}
	
	access(all)
	resource R: RR{ 
		access(self)
		var r:{ UInt256: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun s(_ n: UInt256){ 
			assert(!self.r.containsKey(n), message: "e")
			self.r[n] = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun c(){ 
			self.r ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun h(_ n: UInt256): Bool{ 
			return self.r.containsKey(n)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun size(): Int{ 
			return self.r.keys.length
		}
		
		init(){ 
			self.r ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mint(): @R{ 
		return <-create R()
	}
	
	init(){} 
}
