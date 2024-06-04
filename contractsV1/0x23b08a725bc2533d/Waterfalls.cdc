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
contract Waterfalls{ 
	access(all)
	resource Carp{} 
	
	access(all)
	resource Dragon{ 
		init(_ carp: @Carp){ 
			destroy carp
		}
	}
	
	access(all)
	resource Waterfall{ 
		access(all)
		let wall: UInt64
		
		init(_ wall: UInt64){ 
			self.wall = wall
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hatch(): @Carp{ 
			return <-create Carp()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun climb(carp: @Carp): @Dragon?{ 
			if revertibleRandom<UInt64>() < self.wall{ 
				destroy carp
				return nil
			}
			return <-create Dragon(<-carp)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(wall: UInt64): @Waterfall{ 
		return <-create Waterfall(wall)
	}
}
