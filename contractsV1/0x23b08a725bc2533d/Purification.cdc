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
contract Purification{ 
	access(all)
	struct Desire{} 
	
	access(all)
	resource Human{ 
		access(contract)
		var desires: [Desire]
		
		init(){ 
			self.desires = []
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun live(){ 
			self.desires.append(Desire())
		}
		
		access(contract)
		fun purified(){ 
			self.desires.removeFirst()
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun purify(human: &Human){ 
		while human.desires.length > 0{ 
			human.purified()
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun birth(): @Human{ 
		return <-create Human()
	}
}
