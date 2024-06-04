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
contract ObjectOrientedOntology{ 
	access(all)
	resource interface SensualObject{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun undermine(): &[ObjectOrientedOntology.Object]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun overmine(): [Capability<&Object>]
	}
	
	access(all)
	resource Object: SensualObject{ 
		access(all)
		var causes: @[Object]
		
		access(all)
		var effects: [Capability<&Object>]
		
		init(){ 
			self.causes <- []
			self.effects = []
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun undermine(): &[Object]{ 
			return (&self.causes as &[Object])!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun overmine(): [Capability<&Object>]{ 
			return self.effects
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createObject(): @Object{ 
		return <-create Object()
	}
}
